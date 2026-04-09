import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/file_node.dart';

/// File service using **shallow lazy listing** — never recursive.
///
/// Platform behavior:
/// 1. User explicitly adds root folders (e.g., `C:\Projects`, `/storage/0/Documents`).
/// 2. Each root folder is listed **shallow** (immediate children only).
/// 3. Subdirectories are expanded on-demand — their children are listed shallowly.
/// 4. No full-disk scan. No isolates. No blocking. Startup is instant.
/// 5. LRU cache avoids redundant disk I/O for recently accessed folders.
///
/// Android note: file_picker uses Storage Access Framework (SAF).
/// SAF grants URI permissions via system picker — no manifest permissions needed.
/// file_picker resolves SAF URIs to real paths that dart:io can access.
class FileService {
  final Map<String, _CacheEntry> _cache = {};
  static const _cacheMaxAge = Duration(seconds: 60);
  static const _cacheMaxSize = 500;

  final Set<String> _defaultExtensions = {'md', 'markdown', 'mdx', 'txt'};

  // ─── Public API ───

  /// List immediate children of a directory (shallow — no recursion).
  ///
  /// Returns both files (matching extensions) and directories.
  /// Directories are included only if they contain .md files at ANY depth
  /// (quick shallow check — scans at most one sublevel to avoid full recursion).
  Future<List<FileNode>> listDirectory(
    String directoryPath, {
    Set<String>? allowedExtensions,
    bool showHidden = false,
  }) async {
    final exts = allowedExtensions ?? _defaultExtensions;
    final cacheKey = '$directoryPath|${exts.join(',')}|$showHidden';

    final cached = _cache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.timestamp) < _cacheMaxAge) {
      return cached.children;
    }

    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) return [];

      final entities = await dir.list(recursive: false, followLinks: false).toList();
      final children = <FileNode>[];

      for (final entity in entities) {
        final entityName = p.basename(entity.path);
        if (!showHidden && entityName.startsWith('.')) continue;

        try {
          if (entity is Directory) {
            // Skip protected system directories
            if (_isProtectedSystemDirectory(entity.path)) continue;

            // Quick check: does this folder have .md files (shallow, max 1 sublevel)?
            final hasMarkdown = await _folderHasMarkdownShallow(entity.path, exts, showHidden);
            if (!hasMarkdown) continue;

            final stat = await entity.stat();
            children.add(FileNode(
              path: entity.path,
              name: entityName,
              isDirectory: true,
              lastModified: stat.modified,
              children: [],
            ));
          } else if (entity is File) {
            final ext = p.extension(entityName).replaceAll('.', '').toLowerCase();
            if (!exts.contains(ext)) continue;

            final fileStat = await entity.stat();
            children.add(FileNode(
              path: entity.path,
              name: entityName,
              isDirectory: false,
              lastModified: fileStat.modified,
              size: fileStat.size,
            ));
          }
        } catch (e) {
          // Skip inaccessible entities
          continue;
        }
      }

      children.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      _putCache(cacheKey, children);
      return children;
    } catch (e) {
      return [];
    }
  }

  /// Build a root folder node (shallow listing of immediate children only).
  /// This is called for each user-added root folder. Instant — no recursion.
  Future<FileNode?> buildRootNode(
    String directoryPath, {
    Set<String>? allowedExtensions,
    bool showHidden = false,
  }) async {
    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) return null;

      final name = p.basename(directoryPath);
      final stat = await dir.stat();
      final children = await listDirectory(
        directoryPath,
        allowedExtensions: allowedExtensions,
        showHidden: showHidden,
      );

      return FileNode(
        path: directoryPath,
        name: name,
        isDirectory: true,
        lastModified: stat.modified,
        children: children,
        isExpanded: false,
      );
    } catch (e) {
      return null;
    }
  }

  /// Read file content (lazy-loaded on selection).
  Future<String?> readFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }

  void invalidateCache(String directoryPath) {
    final keysToRemove = _cache.keys.where((k) => k.startsWith(directoryPath)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  void clearCache() {
    _cache.clear();
  }

  // ─── Private: Protected directory detection ───

  static final List<RegExp> _protectedPatterns = [
    RegExp(r'^[A-Za-z]:\\Windows($|\\)', caseSensitive: false),
    RegExp(r'^[A-Za-z]:\\Program Files($|\\)', caseSensitive: false),
    RegExp(r'^[A-Za-z]:\\Program Files \(x86\)($|\\)', caseSensitive: false),
    RegExp(r'^[A-Za-z]:\\ProgramData($|\\)', caseSensitive: false),
    RegExp(r'^[A-Za-z]:\\\$Recycle\.Bin($|\\)', caseSensitive: false),
    RegExp(r'^[A-Za-z]:\\System Volume Information($|\\)', caseSensitive: false),
    RegExp(r'^[A-Za-z]:\\MSOCache($|\\)', caseSensitive: false),
    RegExp(r'^[A-Za-z]:\\PerfLogs($|\\)', caseSensitive: false),
    RegExp(r'^[A-Za-z]:\\Recovery($|\\)', caseSensitive: false),
    RegExp(r'^[A-Za-z]:\\Boot($|\\)', caseSensitive: false),
    RegExp(r'^[A-Za-z]:\\Config\.Msi($|\\)', caseSensitive: false),
    // Android system directories
    RegExp(r'^/storage/.*?/Android($|/)'),
    RegExp(r'^/data/'),
    RegExp(r'^/system/'),
  ];

  static bool _isProtectedSystemDirectory(String path) {
    return _protectedPatterns.any((pattern) => pattern.hasMatch(path));
  }

  // ─── Private: Shallow markdown detection ───

  /// Quick shallow check: does this folder have .md files?
  /// Checks the immediate level + one sublevel deep (not full recursion).
  /// This prevents listing folders that are completely empty of .md files
  /// while avoiding expensive full recursive scans.
  Future<bool> _folderHasMarkdownShallow(
    String dirPath,
    Set<String> exts,
    bool showHidden,
  ) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return false;

      // Check immediate files
      await for (final entity in dir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if (!showHidden && name.startsWith('.')) continue;
          final ext = p.extension(name).replaceAll('.', '').toLowerCase();
          if (exts.contains(ext)) return true;
        } else if (entity is Directory) {
          // Check one sublevel deep
          if (_isProtectedSystemDirectory(entity.path)) continue;
          try {
            final subdir = Directory(entity.path);
            await for (final subEntity in subdir.list(recursive: false, followLinks: false)) {
              if (subEntity is File) {
                final subName = p.basename(subEntity.path);
                if (!showHidden && subName.startsWith('.')) continue;
                final subExt = p.extension(subName).replaceAll('.', '').toLowerCase();
                if (exts.contains(subExt)) return true;
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  // ─── Private: Cache ───

  void _putCache(String key, List<FileNode> children) {
    if (_cache.length >= _cacheMaxSize) {
      var oldestKey = _cache.keys.first;
      var oldestTime = _cache[oldestKey]!.timestamp;
      for (final entry in _cache.entries) {
        if (entry.value.timestamp.isBefore(oldestTime)) {
          oldestTime = entry.value.timestamp;
          oldestKey = entry.key;
        }
      }
      _cache.remove(oldestKey);
    }
    _cache[key] = _CacheEntry(children, DateTime.now());
  }
}

class _CacheEntry {
  final List<FileNode> children;
  final DateTime timestamp;
  _CacheEntry(this.children, this.timestamp);
}

