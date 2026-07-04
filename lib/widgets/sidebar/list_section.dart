import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/file_node.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../../utils/palette.dart';
import '../../utils/responsive.dart';
import 'create_list_dialog.dart';

/// Lists (Collections) section in the sidebar.
class ListSection extends ConsumerWidget {
  const ListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(listsProvider);

    final lists = listsAsync.value ?? const <ListData>[];

    // Header is ALWAYS shown so the user can create their first list.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: context.palette.borderSubtle),
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
              Text(
                'LISTS',
                style: TextStyle(
                  color: context.palette.textMuted,
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
                  color: context.palette.textMuted,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const CreateListDialog(),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Create new list',
              ),
            ],
          ),
        ),
        // List items, or a gentle hint when empty.
        if (lists.isEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Group related folders into a list. Tap + to create one.',
              style: TextStyle(color: context.palette.textMuted, fontSize: 11, height: 1.4),
            ),
          )
        else
          ...lists.map((list) => _ListItem(listData: list)),
      ],
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

        // Load all folders (skip directories — we only want files in the list view)
        final allFiles = <FileNode>[];
        for (final folderPath in fullList.folderPaths) {
          final files = await treeNotifier.navigateToFolder(folderPath, settings);
          allFiles.addAll(files.where((f) => !f.isDirectory));
        }
        ref.read(currentFolderFilesProvider.notifier).state = allFiles;

        // On mobile, surface the Files panel so the user sees the result.
        if (context.mounted && AppBreakpoints.isCompact(context)) {
          ref.read(uiProvider.notifier).setMobilePanel(MobilePanel.files);
        }
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
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${listData.folderCount} folder${listData.folderCount != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: context.palette.textMuted,
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
                color: context.palette.textMuted,
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
        backgroundColor: context.palette.backgroundElevated,
        title: Text('Rename List', style: TextStyle(color: context.palette.textPrimary)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: context.palette.textPrimary),
          decoration: InputDecoration(
            hintText: 'List name',
            hintStyle: TextStyle(color: context.palette.textMuted),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: context.palette.textMuted)),
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
