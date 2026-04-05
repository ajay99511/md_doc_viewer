import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/file_node.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import 'file_list_item.dart';
import 'search_bar.dart';
import '../shared/empty_state.dart';

/// Center panel: shows files in the currently selected folder.
class FileListView extends ConsumerWidget {
  const FileListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(currentFolderFilesProvider);
    final uiState = ref.watch(uiProvider);
    final query = uiState.searchQuery.toLowerCase();

    final filteredFiles = files
        .where((f) => !f.isDirectory)
        .where((f) => query.isEmpty || f.name.toLowerCase().contains(query))
        .toList();

    // Group by section header based on folder context
    final sectionName = _getSectionName(files);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            sectionName ?? 'FILES',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        // Search bar
        SearchBarWidget(
          query: uiState.searchQuery,
          onChanged: (value) => ref.read(uiProvider.notifier).setSearchQuery(value),
        ),
        // File list
        Expanded(
          child: filteredFiles.isEmpty
              ? EmptyState(
                  message: query.isNotEmpty
                      ? 'No files match "$query"'
                      : 'No markdown files found',
                  icon: Icons.search_off,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredFiles.length,
                  itemBuilder: (context, index) {
                    final file = filteredFiles[index];
                    final selectedFile = ref.watch(selectedFileProvider);
                    final isSelected = selectedFile?.path == file.path;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: FileListItem(
                        name: file.name,
                        lastModified: file.lastModified,
                        isSelected: isSelected,
                        onTap: () {
                          ref.read(selectedFileProvider.notifier).state = file;
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String? _getSectionName(List<FileNode> files) {
    if (files.isEmpty) return 'FILES';
    // Use parent folder name or first folder name
    for (final f in files) {
      if (f.isDirectory) return f.name.toUpperCase();
    }
    return 'FILES';
  }
}
