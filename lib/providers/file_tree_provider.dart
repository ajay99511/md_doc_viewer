import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_node.dart';
import '../models/app_settings.dart';
import '../services/file_service.dart';
import '../services/watcher_service.dart';

/// Production-grade file tree provider.
///
/// On loadRoots: builds a complete recursive tree structure via isolate scan.
/// On toggleExpand: toggles expanded/collapsed state (children already loaded).
/// On refresh: clears cache and re-scans.
final fileTreeProvider = StateNotifierProvider<FileTreeNotifier, AsyncValue<List<FileNode>>>((ref) {
  return FileTreeNotifier();
});

class FileTreeNotifier extends StateNotifier<AsyncValue<List<FileNode>>> {
  final FileService _fileService = FileService();
  final WatcherService _watcherService = WatcherService();

  // Track which folders are expanded/collapsed
  final Set<String> _expandedPaths = {};

  FileTreeNotifier() : super(const AsyncValue.loading());

  /// Load root folders with full recursive tree structure (runs in isolate).
  Future<void> loadRoots(List<String> rootFolders, AppSettings settings) async {
    if (rootFolders.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final allowed = Set<String>.from(settings.allowedExtensions);
      final nodes = <FileNode>[];

      // Build each root in parallel (each runs in its own isolate)
      final results = await Future.wait(
        rootFolders.asMap().entries.map((entry) => _fileService.buildRootNode(
              entry.value,
              allowedExtensions: allowed,
              showHidden: settings.showHiddenFiles,
            ).then((node) {
              if (node != null) {
                node.isExpanded = _expandedPaths.contains(entry.value);
              }
              return node;
            })),
      );

      for (final node in results) {
        if (node != null) nodes.add(node);
      }

      state = AsyncValue.data(nodes);

      // Set up file watchers
      _setupWatchers(rootFolders, settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Toggle expand/collapse for a folder.
  /// Children are already loaded from the recursive scan.
  Future<void> toggleExpand(String path, AppSettings settings) async {
    final current = state.value;
    if (current == null) return;

    final isNowExpanded = !_expandedPaths.contains(path);

    if (isNowExpanded) {
      _expandedPaths.add(path);
    } else {
      _expandedPaths.remove(path);
    }

    // Update expanded state in the tree
    final newTree = _updateNode(current, path, (node) {
      return FileNode(
        path: node.path,
        name: node.name,
        isDirectory: node.isDirectory,
        lastModified: node.lastModified,
        children: node.children,
        isExpanded: isNowExpanded,
      );
    });

    state = AsyncValue.data(newTree);
  }

  /// Manually refresh — clears cache and re-scans all roots.
  Future<void> refresh(List<String> rootFolders, AppSettings settings) async {
    _fileService.clearCache();
    _expandedPaths.clear();
    await loadRoots(rootFolders, settings);
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

  // ─── Private helpers ───

  void _setupWatchers(List<String> rootFolders, AppSettings settings) {
    _watcherService.dispose();

    _watcherService.changes.listen((changedPath) {
      _fileService.invalidateCache(changedPath);

      final currentRoots = settings.rootFolders;
      final affectedRoot = currentRoots.firstWhere(
        (root) => changedPath.startsWith(root),
        orElse: () => '',
      );

      if (affectedRoot.isNotEmpty) {
        _refreshRoot(affectedRoot, settings);
      }
    });

    for (final root in rootFolders) {
      _watcherService.watch(root);
    }
  }

  Future<void> _refreshRoot(String rootPath, AppSettings settings) async {
    final current = state.value;
    if (current == null) return;

    final allowed = Set<String>.from(settings.allowedExtensions);
    final newNode = await _fileService.buildRootNode(
      rootPath,
      allowedExtensions: allowed,
      showHidden: settings.showHiddenFiles,
    );

    if (newNode != null) {
      newNode.isExpanded = _expandedPaths.contains(rootPath);
      final newTree = current.map((node) {
        if (node.path == rootPath) return newNode;
        return node;
      }).toList();
      state = AsyncValue.data(newTree);
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
