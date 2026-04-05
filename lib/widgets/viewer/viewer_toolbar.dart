import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';

/// Toolbar at the top of the markdown viewer panel.
class ViewerToolbar extends ConsumerWidget {
  final String fileName;
  final DateTime? lastUpdated;

  const ViewerToolbar({
    super.key,
    required this.fileName,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.fileText,
            size: 18,
            color: AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                'Last updated: ${_formatDate(lastUpdated!)}',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          // Bookmark button
          Consumer(
            builder: (context, ref, _) {
              final selectedFile = ref.watch(selectedFileProvider);
              if (selectedFile == null) return const SizedBox.shrink();

              final isBookmarked = ref.watch(bookmarksProvider).value?.any(
                    (b) => b.path == selectedFile.path,
                  ) ??
                  false;

              return IconButton(
                icon: PhosphorIcon(
                  isBookmarked ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                  size: 18,
                  color: isBookmarked ? AppColors.starActive : AppColors.textMuted,
                ),
                tooltip: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
                onPressed: () {
                  if (isBookmarked) {
                    ref.read(bookmarksProvider.notifier).remove(selectedFile.path);
                  } else {
                    ref.read(bookmarksProvider.notifier).add(selectedFile.path);
                  }
                },
              );
            },
          ),
          // Fullscreen toggle
          Consumer(
            builder: (context, ref, _) {
              final isFullscreen = ref.watch(uiProvider).isViewerFullscreen;
              return IconButton(
                icon: Icon(
                  isFullscreen ? Icons.close_fullscreen : Icons.open_in_full,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                tooltip: isFullscreen ? 'Exit fullscreen' : 'Fullscreen',
                onPressed: () {
                  ref.read(uiProvider.notifier).toggleFullscreen();
                },
              );
            },
          ),
          // Close button (only visible when a file is selected)
          Consumer(
            builder: (context, ref, _) {
              final selectedFile = ref.watch(selectedFileProvider);
              if (selectedFile == null) return const SizedBox.shrink();

              return IconButton(
                icon: PhosphorIcon(
                  PhosphorIconsRegular.x,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                tooltip: 'Close viewer',
                onPressed: () {
                  ref.read(selectedFileProvider.notifier).state = null;
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
