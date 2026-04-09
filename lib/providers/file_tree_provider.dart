import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_node.dart';
import '../models/app_settings.dart';
import '../services/file_service.dart';
import '../services/watcher_service.dart';

/// File tree provider using **shallow lazy-load** model.
///
/// - User adds root folders → each is shallow-listed (instant)
/// - Expanding a folder → lazy-loads its immediate children
/// - No recursive scanning. No isolates. No blocking.
final fileTreeProvider = StateNotifierProvider<FileTreeNotifier, AsyncValue<List<FileNode>>>((ref) {
  return FileTreeNotifier();
});

class FileTreeNotifier extends StateNotifier<AsyncValue<List<FileNode>>> {
  final FileService _fileService = FileService();
  final WatcherService _watcherService = WatcherService();

  // Track expanded folders for state restoration
  final Set<String> _expandedPaths = {};

  FileTreeNotifier() : super(const AsyncValue.data([]));

  /// Load all root folders (shallow listing — instant).
  Future<void> loadRoots(List<String> rootFolders, AppSettings settings, {WidgetRef? ref}) async {
    if (rootFolders.isEmpty) {
      state = const AsyncValue.data([]);
      // Also clear current folder files
      ref?.read(currentFolderFilesProvider.notifier).state = [];
      return;
    }

    // Start with empty state — folders load progressively
    state = const AsyncValue.data([]);

    try {
      final allowed = Set<String>.from(settings.allowedExtensions);
      final nodes = <FileNode>[];

      // Load each root in parallel (shallow only)
      final results = await Future.wait(
        rootFolders.map((root) => _fileService.buildRootNode(
              root,
              allowedExtensions: allowed,
              showHidden: settings.showHiddenFiles,
            )),
      );

      for (final node in results) {
        if (node != null) nodes.add(node);
      }

      state = AsyncValue.data(nodes);

      // Populate currentFolderFilesProvider with all files from all roots
      // This ensures the Files tab shows content immediately on mobile
      if (ref != null) {
        final allFiles = <FileNode>[];
        for (final rootNode in nodes) {
          if (rootNode.children.isNotEmpty) {
            _collectFiles(rootNode.children, allFiles);
          }
        }
        ref.read(currentFolderFilesProvider.notifier).state = allFiles;
      }

      // Set up file watchers
      _setupWatchers(rootFolders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Recursively collect all files from a list of nodes
  void _collectFiles(List<FileNode> nodes, List<FileNode> accumulator) {
    for (final node in nodes) {
      if (node.isDirectory) {
        if (node.children.isNotEmpty) {
          _collectFiles(node.children, accumulator);
        }
      } else {
        accumulator.add(node);
      }
    }
  }

  /// Toggle expand/collapse for a folder.
  /// On first expand: lazy-load children from disk.
  /// On collapse: just toggle state (children kept in memory).
  Future<void> toggleExpand(String path, AppSettings settings) async {
    final current = state.value;
    if (current == null) return;

    final isNowExpanded = !_expandedPaths.contains(path);

    if (isNowExpanded) {
      _expandedPaths.add(path);

      // Lazy-load children for this folder
      final allowed = Set<String>.from(settings.allowedExtensions);
      final newChildren = await _fileService.listDirectory(
        path,
        allowedExtensions: allowed,
        showHidden: settings.showHiddenFiles,
      );

      // Update tree with new children
      final newTree = _updateNode(current, path, (node) {
        return FileNode(
          path: node.path,
          name: node.name,
          isDirectory: node.isDirectory,
          lastModified: node.lastModified,
          children: newChildren,
          isExpanded: true,
        );
      });

      state = AsyncValue.data(newTree);
    } else {
      // Collapse — just toggle state
      _expandedPaths.remove(path);
      final newTree = _updateNode(current, path, (node) {
        return FileNode(
          path: node.path,
          name: node.name,
          isDirectory: node.isDirectory,
          lastModified: node.lastModified,
          children: node.children,
          isExpanded: false,
        );
      });
      state = AsyncValue.data(newTree);
    }
  }

  /// Refresh all root folders (re-scan shallow).
  Future<void> refresh(List<String> rootFolders, AppSettings settings, {WidgetRef? ref}) async {
    _fileService.clearCache();
    _expandedPaths.clear();
    await loadRoots(rootFolders, settings, ref: ref);
  }

  /// Navigate to a specific folder — returns its children for the file list panel.
  Future<List<FileNode>> navigateToFolder(
    String folderPath,
    AppSettings settings,
  ) async {
    final allowed = Set<String>.from(settings.allowedExtensions);
    return _fileService.listDirectory(
      folderPath,
      allowedExtensions: allowed,
      showHidden: settings.showHiddenFiles,
    );
  }

  // ─── Private ───

  void _setupWatchers(List<String> rootFolders) {
    _watcherService.dispose();

    _watcherService.changes.listen((changedPath) {
      _fileService.invalidateCache(changedPath);
    });

    for (final root in rootFolders) {
      _watcherService.watch(root);
    }
  }

  List<FileNode> _updateNode(
    List<FileNode> nodes,
    String targetPath,
    FileNode Function(FileNode) transform,
  ) {
    return nodes.map((node) {
      if (node.path == targetPath) return transform(node);
      if (node.isDirectory && node.children.isNotEmpty) {
        return FileNode(
          path: node.path,
          name: node.name,
          isDirectory: node.isDirectory,
          lastModified: node.lastModified,
          children: _updateNode(node.children, targetPath, transform),
          isExpanded: node.isExpanded,
        );
      }
      return node;
    }).toList();
  }

  @override
  void dispose() {
    _watcherService.dispose();
    super.dispose();
  }
}

/// Files in the currently selected/expanded folder.
final currentFolderFilesProvider = StateProvider<List<FileNode>>((ref) => []);
