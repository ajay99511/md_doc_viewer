import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import 'markdown_content.dart';

class FullscreenViewer extends ConsumerWidget {
  const FullscreenViewer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFile = ref.watch(selectedFileProvider);
    if (selectedFile == null) return const SizedBox.shrink();

    return ColoredBox(
      color: AppColors.backgroundBase,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () {
                    ref.read(uiProvider.notifier).setFullscreen(false);
                  },
                  tooltip: 'Exit fullscreen (Esc)',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedFile.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final fontSize = ref.watch(settingsProvider).markdownFontSize;
                    return Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.text_decrease, size: 18),
                          color: AppColors.textMuted,
                          onPressed: () {
                            if (fontSize > 10) {
                              ref.read(settingsProvider.notifier).update(
                                    markdownFontSize: fontSize - 1,
                                  );
                            }
                          },
                        ),
                        Text(
                          '${fontSize.toInt()}',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        IconButton(
                          icon: const Icon(Icons.text_increase, size: 18),
                          color: AppColors.textMuted,
                          onPressed: () {
                            if (fontSize < 28) {
                              ref.read(settingsProvider.notifier).update(
                                    markdownFontSize: fontSize + 1,
                                  );
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final contentAsync = ref.watch(selectedFileContentProvider);
                final fontSize = ref.watch(settingsProvider).markdownFontSize;
                return contentAsync.when(
                  data: (content) {
                    if (content == null || content.isEmpty) {
                      return const Center(
                        child: Text(
                          'This file is empty',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      );
                    }
                    return MarkdownContent(content: content, customFontSize: fontSize);
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load: $e',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
