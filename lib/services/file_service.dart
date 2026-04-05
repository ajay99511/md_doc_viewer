import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;
import '../models/file_node.dart';

/// Production-grade file service for Windows/macOS/Linux.
class FileService {
  final Map<String, _CacheEntry> _cache = {};
  static const _cacheMaxAge = Duration(seconds: 30);
  static const _cacheMaxSize = 1000;

  final Set<String> _defaultExtensions = {'md', 'markdown', 'mdx', 'txt'};

  // Windows system directories to skip (compiled once, reused).
  // Works on any drive letter (C:, D:, etc.).
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
  ];

  // ─── Public API ───

  /// Build a complete folder tree for a root directory.
  /// Recursively finds ALL directories containing supported files at ANY depth.
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
      final exts = allowedExtensions ?? _defaultExtensions;

      // Recursive structure scan in isolate (non-blocking)
      final children = await _scanStructureAsync(directoryPath, exts, showHidden);

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

  /// List immediate children of a directory (for navigation/bookmark access).
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

        if (entity is Directory) {
          // Only show directories that have .md files somewhere in their subtree
          final hasMarkdown = await _directoryHasMarkdownDeep(entity.path, exts, showHidden);
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

  // ─── Private: Recursive scan in isolate ───

  Future<List<FileNode>> _scanStructureAsync(
    String directoryPath,
    Set<String> exts,
    bool showHidden,
  ) async {
    return Isolate.run(() {
      return _buildTreeSync(directoryPath, exts.toList(), showHidden);
    });
  }

  /// Synchronous recursive tree builder.
  ///
  /// IMPORTANT: Permission errors on individual directories are handled
  /// gracefully — the scan continues with other directories. Only the
  /// inaccessible branch is skipped, not the entire tree.
  static List<FileNode> _buildTreeSync(
    String dirPath,
    List<String> allowedExtensions,
    bool showHidden,
  ) {
    final exts = allowedExtensions.toSet();
    final children = <FileNode>[];

    // Try to list this directory. If it fails (permission denied),
    // return empty — the parent will handle the "no children" case.
    List<FileSystemEntity> entities;
    try {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) return [];
      entities = dir.listSync(recursive: false, followLinks: false);
    } catch (e) {
      // Permission denied, reparse point, etc. — skip this directory entirely
      return [];
    }

    for (final entity in entities) {
      final entityName = p.basename(entity.path);
      if (!showHidden && entityName.startsWith('.')) continue;

      try {
        if (entity is Directory) {
          // Skip Windows special directories that are always inaccessible
          if (_isProtectedSystemDirectory(entity.path)) continue;

          // Recursively scan subdirectory
          final subChildren = _buildTreeSync(entity.path, allowedExtensions, showHidden);

          // Only include this directory if it has markdown files in its subtree
          if (subChildren.isNotEmpty || _dirHasFilesDirect(entity.path, exts, showHidden)) {
            final stat = entity.statSync();
            children.add(FileNode(
              path: entity.path,
              name: entityName,
              isDirectory: true,
              lastModified: stat.modified,
              children: subChildren,
            ));
          }
        } else if (entity is File) {
          final ext = p.extension(entityName).replaceAll('.', '').toLowerCase();
          if (exts.contains(ext)) {
            final fileStat = entity.statSync();
            children.add(FileNode(
              path: entity.path,
              name: entityName,
              isDirectory: false,
              lastModified: fileStat.modified,
              size: fileStat.size,
            ));
          }
        }
      } catch (e) {
        // Individual entity error — skip and continue
        continue;
      }
    }

    // Sort: directories first, then files, both alphabetically
    children.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return children;
  }

  /// Check if a path is a Windows protected system directory.
  static bool _isProtectedSystemDirectory(String path) {
    final normalized = path.replaceAll('/', r'\');
    return _protectedPatterns.any((pattern) => pattern.hasMatch(normalized));
  }

  /// Quick check: does this directory have any supported files directly in it?
  /// (No recursion — just the immediate level.)
  static bool _dirHasFilesDirect(
    String dirPath,
    Set<String> exts,
    bool showHidden,
  ) {
    try {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) return false;

      for (final entity in dir.listSync(recursive: false, followLinks: false)) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if (!showHidden && name.startsWith('.')) continue;
          final ext = p.extension(name).replaceAll('.', '').toLowerCase();
          if (exts.contains(ext)) return true;
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  /// Deep recursive check: does this directory contain .md files at ANY depth?
  /// Used for lazy-loaded directory expansion. Runs in isolate.
  Future<bool> _directoryHasMarkdownDeep(
    String dirPath,
    Set<String> exts,
    bool showHidden,
  ) async {
    return Isolate.run(() => _checkHasMarkdownSync(dirPath, exts.toList(), showHidden));
  }

  static bool _checkHasMarkdownSync(
    String dirPath,
    List<String> allowedExtensions,
    bool showHidden,
  ) {
    final exts = allowedExtensions.toSet();
    return _deepSearch(dirPath, exts, showHidden);
  }

  /// Deep recursive search for markdown files.
  /// Tolerates permission errors on individual directories.
  static bool _deepSearch(String dirPath, Set<String> exts, bool showHidden) {
    try {
      if (_isProtectedSystemDirectory(dirPath)) return false;

      final dir = Directory(dirPath);
      if (!dir.existsSync()) return false;

      for (final entity in dir.listSync(recursive: false, followLinks: false)) {
        try {
          if (entity is File) {
            final name = p.basename(entity.path);
            if (!showHidden && name.startsWith('.')) continue;
            final ext = p.extension(name).replaceAll('.', '').toLowerCase();
            if (exts.contains(ext)) return true;
          } else if (entity is Directory) {
            if (_deepSearch(entity.path, exts, showHidden)) return true;
          }
        } catch (e) {
          // Skip inaccessible items
          continue;
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
