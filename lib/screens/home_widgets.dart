part of 'home_screen.dart';

// SHARED COMPONENTS
// ═══════════════════════════════════════════════════

class _AppHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onAddFolder;
  final VoidCallback onSettings;

  const _AppHeader({
    required this.onRefresh,
    required this.onAddFolder,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.notebook,
            size: 20,
            color: AppColors.accent,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'MD Explorer',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: PhosphorIcon(
              PhosphorIconsRegular.arrowClockwise,
              size: 18,
              color: AppColors.textMuted,
            ),
            tooltip: 'Refresh',
            onPressed: onRefresh,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: PhosphorIcon(
              PhosphorIconsRegular.plus,
              size: 18,
              color: AppColors.textMuted,
            ),
            tooltip: 'Add folder',
            onPressed: onAddFolder,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: PhosphorIcon(
              PhosphorIconsRegular.gear,
              size: 18,
              color: AppColors.textMuted,
            ),
            tooltip: 'Settings',
            onPressed: onSettings,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

/// Folder tree with prominent empty state + managed folder list.
class _FolderTreeContent extends ConsumerWidget {
  const _FolderTreeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final treeState = ref.watch(fileTreeProvider);

    return treeState.when(
      data: (nodes) {
        // No folders added yet — show setup prompt
        if (settings.rootFolders.isEmpty) {
          return _EmptyState(onAddFolder: () async {
            final result = await FilePicker.platform.getDirectoryPath();
            if (result != null) {
              await ref.read(settingsProvider.notifier).addRootFolder(result);
              ref.read(fileTreeProvider.notifier).loadRoots(
                    ref.read(settingsProvider).rootFolders,
                    ref.read(settingsProvider),
                    ref: ref,
                  );
            }
          });
        }

        // Folders added but empty tree (loading or truly empty)
        if (nodes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        // Show managed folder headers + tree
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: nodes.length,
          itemBuilder: (context, index) {
            return _TreeNodeWidget(node: nodes[index], depth: 0);
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => _EmptyState(
        error: 'Failed to load folders: $e',
        onAddFolder: () async {
          final result = await FilePicker.platform.getDirectoryPath();
          if (result != null && context.mounted) {
            await ref.read(settingsProvider.notifier).addRootFolder(result);
            ref.read(fileTreeProvider.notifier).loadRoots(
                  ref.read(settingsProvider).rootFolders,
                  ref.read(settingsProvider),
                  ref: ref,
                );
          }
        },
        onRetry: () {
          final settings = ref.read(settingsProvider);
          if (settings.rootFolders.isNotEmpty) {
            ref.read(fileTreeProvider.notifier).loadRoots(
                  settings.rootFolders,
                  settings,
                  ref: ref,
                );
          }
        },
      ),
    );
  }
}

/// Empty state — shown when no folders are added or when error occurs.
class _EmptyState extends StatelessWidget {
  final String? error;
  final VoidCallback onAddFolder;
  final VoidCallback? onRetry;

  const _EmptyState({this.error, required this.onAddFolder, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: hasError ? AppColors.error.withValues(alpha: 0.1) : AppColors.accentSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                hasError ? Icons.error_outline : Icons.folder_open,
                size: 40,
                color: hasError ? AppColors.error : AppColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              hasError ? 'Failed to Load Folders' : 'No Folders Added',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              hasError
                  ? 'There was a problem loading your folders.'
                  : 'Add folders containing Markdown files\nto start exploring your documentation.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasError) ...[
              const SizedBox(height: 8),
              // Tip
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Add specific project folders, not entire drives like C:\\',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onAddFolder,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Folder'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(150, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
                if (hasError && onRetry != null) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      minimumSize: const Size(100, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ],
            ),
            // Error message
            if (hasError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// File list content — shared by all layouts.
class _FileListContent extends ConsumerWidget {
  const _FileListContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(currentFolderFilesProvider);
    final uiState = ref.watch(uiProvider);
    final query = uiState.searchQuery.toLowerCase();

    final filteredFiles = files
        .where((f) => !f.isDirectory)
        .where((f) => query.isEmpty || f.name.toLowerCase().contains(query))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'FILES',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          decoration: BoxDecoration(
            color: AppColors.backgroundElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              PhosphorIcon(
                PhosphorIconsRegular.magnifyingGlass,
                size: 18,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search in folder...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  onChanged: (value) =>
                      ref.read(uiProvider.notifier).setSearchQuery(value),
                ),
              ),
              if (query.isNotEmpty)
                IconButton(
                  icon: PhosphorIcon(
                    PhosphorIconsRegular.x,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () =>
                      ref.read(uiProvider.notifier).setSearchQuery(''),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        Expanded(
          child: filteredFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.file,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        query.isNotEmpty
                            ? 'No files match "$query"'
                            : 'Select a folder to see files',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
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
                      child: InkWell(
                        onTap: () {
                          ref.read(selectedFileProvider.notifier).state = file;
                          if (AppBreakpoints.isCompact(context)) {
                            ref.read(uiProvider.notifier).navigateToViewer();
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected
                                ? AppColors.backgroundActive
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              PhosphorIcon(
                                PhosphorIconsRegular.fileText,
                                size: 20,
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.fileIcon,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (file.lastModified != null)
                                      Text(
                                        _formatDate(file.lastModified!),
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppColors.textSecondary
                                              : AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                PhosphorIcon(
                                  PhosphorIconsRegular.caretRight,
                                  size: 16,
                                  color: AppColors.accent,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Viewer content — shared by all layouts.
class _ViewerContent extends ConsumerWidget {
  final bool showBackButton;
  const _ViewerContent({this.showBackButton = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFile = ref.watch(selectedFileProvider);

    if (selectedFile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.fileText,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a file to view',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                  onPressed: () {
                    ref.read(uiProvider.notifier).navigateToFiles();
                  },
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              PhosphorIcon(
                PhosphorIconsRegular.fileText,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedFile.name,
                  style: const TextStyle(
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
                  final isBookmarked = ref.watch(bookmarksProvider).value
                          ?.any((b) => b.path == selectedFile.path) ??
                      false;
                  return IconButton(
                    icon: PhosphorIcon(
                      isBookmarked
                          ? PhosphorIconsFill.star
                          : PhosphorIconsRegular.star,
                      size: 20,
                      color: isBookmarked
                          ? AppColors.starActive
                          : AppColors.textMuted,
                    ),
                    onPressed: () {
                      if (isBookmarked) {
                        ref.read(bookmarksProvider.notifier).remove(selectedFile.path);
                      } else {
                        ref.read(bookmarksProvider.notifier).add(selectedFile.path);
                      }
                    },
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.open_in_full, color: AppColors.textSecondary, size: 20),
                onPressed: () {
                  ref.read(uiProvider.notifier).setFullscreen(true);
                },
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                onPressed: () {
                  ref.read(selectedFileProvider.notifier).state = null;
                  if (AppBreakpoints.isCompact(context)) {
                    ref.read(uiProvider.notifier).navigateToFiles();
                  }
                },
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              final contentAsync = ref.watch(selectedFileContentProvider);
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
                  return MarkdownContent(content: content);
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Bookmark section — shared component.
class _BookmarkSection extends ConsumerWidget {
  const _BookmarkSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);

    return bookmarksAsync.when(
      data: (bookmarks) {
        if (bookmarks.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  const Text(
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
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bookmarks.length,
                onReorder: (oldIndex, newIndex) {
                  ref.read(bookmarksProvider.notifier).reorder(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final bm = bookmarks[index];
                  return InkWell(
                    key: ValueKey(bm.path),
                    onTap: () async {
                      final settings = ref.read(settingsProvider);
                      final files = await ref.read(fileServiceProvider).listDirectory(
                            bm.path,
                            allowedExtensions: Set<String>.from(settings.allowedExtensions),
                            showHidden: settings.showHiddenFiles,
                          );
                      ref.read(currentFolderFilesProvider.notifier).state = files;
                      // Check mounted after async gap
                      if (!context.mounted) return;
                      if (AppBreakpoints.isCompact(context)) {
                        ref.read(uiProvider.notifier).setMobilePanel(MobilePanel.files);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: PhosphorIcon(
                              PhosphorIconsRegular.dotsSixVertical,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          PhosphorIcon(
                            PhosphorIconsFill.star,
                            size: 16,
                            color: AppColors.starActive,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bm.label,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: PhosphorIcon(
                              PhosphorIconsRegular.x,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () {
                              ref.read(bookmarksProvider.notifier).remove(bm.path);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Fullscreen viewer wrapper.
class _FullscreenWrapper extends ConsumerWidget {
  const _FullscreenWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFile = ref.watch(selectedFileProvider);
    if (selectedFile == null) {
      ref.read(uiProvider.notifier).setFullscreen(false);
      return const SizedBox.shrink();
    }

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
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedFile.name,
                    style: const TextStyle(
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
                          icon: const Icon(Icons.text_decrease, size: 20),
                          color: AppColors.textMuted,
                          onPressed: () {
                            if (fontSize > 10) {
                              ref.read(settingsProvider.notifier).update(
                                    markdownFontSize: fontSize - 1,
                                  );
                            }
                          },
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                        Text(
                          '${fontSize.toInt()}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                        IconButton(
                          icon: const Icon(Icons.text_increase, size: 20),
                          color: AppColors.textMuted,
                          onPressed: () {
                            if (fontSize < 28) {
                              ref.read(settingsProvider.notifier).update(
                                    markdownFontSize: fontSize + 1,
                                  );
                            }
                          },
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
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

// ═══════════════════════════════════════════════════
// FOLDER/FILE TREE WIDGETS
// ═══════════════════════════════════════════════════

class _TreeNodeWidget extends ConsumerWidget {
  final dynamic node;
  final int depth;

  const _TreeNodeWidget({required this.node, required this.depth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (node.isDirectory) {
      return _FolderWidget(node: node, depth: depth);
    } else {
      return _FileWidget(node: node, depth: depth);
    }
  }
}

class _FolderWidget extends ConsumerWidget {
  final dynamic node;
  final int depth;

  const _FolderWidget({required this.node, required this.depth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasChildren = node.children?.isNotEmpty ?? false;

    return Column(
      children: [
        InkWell(
          onTap: () {
            ref.read(fileTreeProvider.notifier).toggleExpand(
                  node.path,
                  ref.read(settingsProvider),
                );
            if (node.children?.isNotEmpty ?? false) {
              ref.read(currentFolderFilesProvider.notifier).state = node.children ?? [];
            }
          },
          child: Container(
            padding: EdgeInsets.only(left: 8.0 + depth * 16, right: 8, top: 10, bottom: 10),
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
                  size: 20,
                  color: AppColors.folderIcon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    node.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final isBookmarked = ref.watch(bookmarksProvider).value
                            ?.any((b) => b.path == node.path) ??
                        false;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: PhosphorIcon(
                            isBookmarked
                                ? PhosphorIconsFill.star
                                : PhosphorIconsRegular.star,
                            size: 18,
                            color: isBookmarked
                                ? AppColors.starActive
                                : Colors.transparent,
                          ),
                          onPressed: () {
                            if (isBookmarked) {
                              ref.read(bookmarksProvider.notifier).remove(node.path);
                            } else {
                              ref.read(bookmarksProvider.notifier).add(node.path, node.name);
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        if (node.isExpanded && hasChildren)
          ...node.children.map(
              (child) => _TreeNodeWidget(node: child, depth: depth + 1)),
      ],
    );
  }
}

class _FileWidget extends ConsumerWidget {
  final dynamic node;
  final int depth;

  const _FileWidget({required this.node, required this.depth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFile = ref.watch(selectedFileProvider);
    final isSelected = selectedFile?.path == node.path;

    return InkWell(
      onTap: () {
        ref.read(selectedFileProvider.notifier).state = node;
        if (AppBreakpoints.isCompact(context)) {
          ref.read(uiProvider.notifier).navigateToViewer();
        }
      },
      child: Container(
        padding: EdgeInsets.only(left: 24 + depth * 16, right: 8, top: 10, bottom: 10),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.fileText,
              size: 18,
              color: isSelected ? AppColors.accent : AppColors.fileIcon,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                node.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              PhosphorIcon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}
