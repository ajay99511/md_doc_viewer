import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_banner.dart';
import 'viewer_toolbar.dart';
import 'markdown_content.dart';

/// Main markdown viewer panel — shows content or empty state.
class MarkdownViewer extends ConsumerWidget {
  const MarkdownViewer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFile = ref.watch(selectedFileProvider);

    if (selectedFile == null) {
      return const EmptyState(
        message: 'Select a file to view its content',
        icon: Icons.description_outlined,
      );
    }

    return Column(
      children: [
        // Toolbar
        ViewerToolbar(
          fileName: selectedFile.name,
          lastUpdated: selectedFile.lastModified,
        ),
        // Content
        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              final contentAsync = ref.watch(selectedFileContentProvider);

              return contentAsync.when(
                data: (content) {
                  if (content == null || content.isEmpty) {
                    return const EmptyState(
                      message: 'This file is empty',
                      icon: Icons.note,
                    );
                  }
                  return MarkdownContent(content: content);
                },
                loading: () => const LoadingIndicator(),
                error: (e, _) => ErrorBanner(
                  message: 'Failed to load file: $e',
                  onRetry: () {
                    ref.invalidate(selectedFileContentProvider);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
