import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/file_node.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';

/// Left sidebar: folder tree with expand/collapse.
class FolderTree extends ConsumerWidget {
  const FolderTree({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeState = ref.watch(fileTreeProvider);

    return treeState.when(
      data: (nodes) => nodes.isEmpty
          ? _EmptyTree()
          : _TreeContent(nodes: nodes),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => _EmptyTree(error: e.toString()),
    );
  }
}

class _EmptyTree extends StatelessWidget {
  final String? error;
  const _EmptyTree({this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.folderOpen,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              error ?? 'No folders added yet',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Use Settings to add root folders',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreeContent extends StatelessWidget {
  final List<FileNode> nodes;
  const _TreeContent({required this.nodes});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        return _TreeNode(node: nodes[index], depth: 0);
      },
    );
  }
}

class _TreeNode extends ConsumerWidget {
  final FileNode node;
  final int depth;

  const _TreeNode({required this.node, required this.depth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (node.isDirectory) {
      return _FolderNode(node: node, depth: depth);
    } else {
      return _FileNodeItem(node: node, depth: depth);
    }
  }
}

class _FolderNode extends ConsumerWidget {
  final FileNode node;
  final int depth;

  const _FolderNode({required this.node, required this.depth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasChildren = node.children.isNotEmpty;
    final isSelected = ref.watch(currentFolderFilesProvider).isNotEmpty &&
        ref.watch(currentFolderFilesProvider).any((f) => f.path == node.path || f.path.startsWith('${node.path}/'));

    return Column(
      children: [
        InkWell(
          onTap: () {
            // Toggle expand/collapse and load children
            ref.read(fileTreeProvider.notifier).toggleExpand(node.path, ref.read(settingsProvider));
            // Also set as current folder for file list
            if (node.children.isNotEmpty) {
              ref.read(currentFolderFilesProvider.notifier).state = node.children;
            }
          },
          child: Container(
            padding: EdgeInsets.only(left: 8.0 + depth * 16, right: 8, top: 6, bottom: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.backgroundActive : Colors.transparent,
            ),
            child: Row(
              children: [
                if (hasChildren)
                  PhosphorIcon(
                    node.isExpanded
                        ? PhosphorIconsRegular.caretDown
                        : PhosphorIconsRegular.caretRight,
                    size: 14,
                    color: AppColors.textMuted,
                  )
                else
                  const SizedBox(width: 14),
                const SizedBox(width: 4),
                PhosphorIcon(
                  node.isExpanded
                      ? PhosphorIconsRegular.folderOpen
                      : PhosphorIconsRegular.folder,
                  size: 18,
                  color: AppColors.folderIcon,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Bookmark star
                Consumer(
                  builder: (context, ref, _) {
                    final bookmarks = ref.watch(bookmarksProvider);
                    final isBookmarked = bookmarks.value?.any((b) => b.path == node.path) ?? false;
                    return IconButton(
                      icon: PhosphorIcon(
                        isBookmarked ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                        size: 16,
                        color: isBookmarked ? AppColors.starActive : Colors.transparent,
                      ),
                      onPressed: () {
                        if (isBookmarked) {
                          ref.read(bookmarksProvider.notifier).remove(node.path);
                        } else {
                          ref.read(bookmarksProvider.notifier).add(node.path, node.name);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Children
        if (node.isExpanded && hasChildren)
          ...node.children.map((child) => _TreeNode(node: child, depth: depth + 1)),
      ],
    );
  }
}

class _FileNodeItem extends ConsumerWidget {
  final FileNode node;
  final int depth;

  const _FileNodeItem({required this.node, required this.depth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFile = ref.watch(selectedFileProvider);
    final isSelected = selectedFile?.path == node.path;

    return InkWell(
      onTap: () {
        ref.read(selectedFileProvider.notifier).state = node;
      },
      child: Container(
        padding: EdgeInsets.only(left: 24 + depth * 16, right: 8, top: 5, bottom: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.backgroundActive : Colors.transparent,
        ),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.fileText,
              size: 16,
              color: isSelected ? AppColors.accent : AppColors.fileIcon,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                node.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
