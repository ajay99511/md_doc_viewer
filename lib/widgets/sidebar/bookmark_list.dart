import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';

/// Bookmarked (starred) folders section in the sidebar.
class BookmarkList extends ConsumerWidget {
  const BookmarkList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);

    return bookmarksAsync.when(
      data: (bookmarks) {
        if (bookmarks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Divider + header
            const Divider(height: 1, color: AppColors.borderSubtle),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.star,
                    size: 16,
                    color: AppColors.starActive,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BOOKMARKS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            // Reorderable bookmark list
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookmarks.length,
              onReorder: (oldIndex, newIndex) {
                ref.read(bookmarksProvider.notifier).reorder(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                return _BookmarkItem(
                  key: ValueKey(bookmark.path),
                  bookmark: bookmark,
                  index: index,
                );
              },
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BookmarkItem extends ConsumerWidget {
  final BookmarkData bookmark;
  final int index;

  const _BookmarkItem({
    super.key,
    required this.bookmark,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        final settings = ref.read(settingsProvider);
        final files = await ref.read(fileServiceProvider).listDirectory(
              bookmark.path,
              allowedExtensions: Set<String>.from(settings.allowedExtensions),
              showHidden: settings.showHiddenFiles,
            );
        ref.read(currentFolderFilesProvider.notifier).state = files;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: PhosphorIcon(
                PhosphorIconsRegular.dotsSixVertical,
                size: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 4),
            PhosphorIcon(
              PhosphorIconsFill.star,
              size: 14,
              color: AppColors.starActive,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bookmark.label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Remove bookmark button
            IconButton(
              icon: PhosphorIcon(
                PhosphorIconsRegular.x,
                size: 14,
                color: AppColors.textMuted,
              ),
              onPressed: () {
                ref.read(bookmarksProvider.notifier).remove(bookmark.path);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
