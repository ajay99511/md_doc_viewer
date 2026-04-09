import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/file_node.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import 'create_list_dialog.dart';

/// Lists (Collections) section in the sidebar.
class ListSection extends ConsumerWidget {
  const ListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(listsProvider);

    return listsAsync.when(
      data: (lists) {
        if (lists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, color: AppColors.borderSubtle),
            // Header with create button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.listBullets,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LISTS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: PhosphorIcon(
                      PhosphorIconsRegular.plus,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const CreateListDialog(),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Create new list',
                  ),
                ],
              ),
            ),
            // List items
            ...lists.map((list) => _ListItem(listData: list)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ListItem extends ConsumerWidget {
  final ListData listData;

  const _ListItem({required this.listData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        // Navigate to this list: load all folders in the list
        final fullList = await ref.read(listsProvider.notifier).getListById(listData.id);
        if (fullList == null || fullList.folderPaths.isEmpty) return;

        final settings = ref.read(settingsProvider);
        final treeNotifier = ref.read(fileTreeProvider.notifier);

        // Load all folders in parallel
        final allFiles = <FileNode>[];
        for (final folderPath in fullList.folderPaths) {
          final files = await treeNotifier.navigateToFolder(folderPath, settings);
          allFiles.addAll(files);
        }
        ref.read(currentFolderFilesProvider.notifier).state = allFiles;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.listBullets,
              size: 14,
              color: AppColors.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listData.name,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${listData.folderCount} folder${listData.folderCount != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // More options menu
            PopupMenuButton<String>(
              icon: PhosphorIcon(
                PhosphorIconsRegular.dotsThree,
                size: 16,
                color: AppColors.textMuted,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (value) {
                switch (value) {
                  case 'rename':
                    _showRenameDialog(context, ref);
                    break;
                  case 'delete':
                    ref.read(listsProvider.notifier).delete(listData.id);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Rename'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: listData.name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        title: const Text('Rename List', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'List name',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(listsProvider.notifier).rename(listData.id, controller.text.trim());
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
