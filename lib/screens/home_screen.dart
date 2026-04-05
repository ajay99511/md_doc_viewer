import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/viewer/markdown_content.dart';
import '../widgets/sidebar/list_section.dart';
import 'settings_screen.dart';

/// Main home screen — fully responsive across mobile/tablet/desktop.
///
/// Layout strategy:
/// ┌─────────────────────────────────────────────┐
/// │ COMPACT (< 600px) — Mobile                  │
/// │ [Drawer: Tree] → [Main: Files] → [Sheet: V] │
/// │ Single panel at a time, bottom nav bar      │
/// ├─────────────────────────────────────────────┤
/// │ MEDIUM (600-1024px) — Tablet                │
/// │ [Sidebar] + [Files/Viewer toggle]           │
/// │ 2 panels, viewer slides in from right       │
/// ├─────────────────────────────────────────────┤
/// │ EXPANDED (> 1024px) — Desktop               │
/// │ [Sidebar] + [Files] + [Viewer]              │
/// │ 3 panels, all visible simultaneously        │
/// └─────────────────────────────────────────────┘
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      if (settings.rootFolders.isNotEmpty) {
        ref.read(fileTreeProvider.notifier).loadRoots(
              settings.rootFolders,
              settings,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFullscreen = ref.watch(uiProvider).isViewerFullscreen;

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: isFullscreen ? const _FullscreenWrapper() : const _ResponsiveLayout(),
    );
  }
}

/// Responsive layout — switches between mobile/tablet/desktop modes.
class _ResponsiveLayout extends ConsumerWidget {
  const _ResponsiveLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final mode = AppBreakpoints.getMode(width);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (mode) {
        LayoutMode.compact => const _MobileLayout(key: ValueKey('mobile')),
        LayoutMode.medium => const _TabletLayout(key: ValueKey('tablet')),
        LayoutMode.expanded => const _DesktopLayout(key: ValueKey('desktop')),
      },
    );
  }
}

// ═══════════════════════════════════════════════════
// DESKTOP LAYOUT (> 1024px) — 3 panels
// ═══════════════════════════════════════════════════

class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _DesktopSidebar(ref: ref),
        _DesktopFileList(ref: ref),
        _DesktopViewer(ref: ref),
      ],
    );
  }
}

class _DesktopSidebar extends ConsumerWidget {
  final WidgetRef ref;
  const _DesktopSidebar({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        border: Border(right: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        children: [
          _AppHeader(
            onRefresh: () => ref.read(fileTreeProvider.notifier).refresh(
                  ref.read(settingsProvider).rootFolders,
                  ref.read(settingsProvider),
                ),
            onAddFolder: () async {
              final result = await FilePicker.platform.getDirectoryPath();
              if (result != null) {
                await ref.read(settingsProvider.notifier).addRootFolder(result);
                final settings = ref.read(settingsProvider);
                ref.read(fileTreeProvider.notifier).loadRoots(
                      settings.rootFolders,
                      settings,
                    );
              }
            },
            onSettings: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(child: const _FolderTreeContent()),
                const _BookmarkSection(),
                const ListSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopFileList extends ConsumerWidget {
  final WidgetRef ref;
  const _DesktopFileList({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AppColors.backgroundBase,
        border: Border(right: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: const _FileListContent(),
    );
  }
}

class _DesktopViewer extends ConsumerWidget {
  final WidgetRef ref;
  const _DesktopViewer({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    return const Expanded(child: _ViewerContent());
  }
}

// ═══════════════════════════════════════════════════
// TABLET LAYOUT (600-1024px) — 2 panels
// ═══════════════════════════════════════════════════

class _TabletLayout extends ConsumerWidget {
  const _TabletLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFile = ref.watch(selectedFileProvider);

    return Row(
      children: [
        // Sidebar (narrower on tablet)
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            border: Border(right: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Column(
            children: [
              _AppHeader(
                onRefresh: () => ref.read(fileTreeProvider.notifier).refresh(
                      ref.read(settingsProvider).rootFolders,
                      ref.read(settingsProvider),
                    ),
                onAddFolder: () async {
                  final result = await FilePicker.platform.getDirectoryPath();
                  if (result != null) {
                    await ref.read(settingsProvider.notifier).addRootFolder(result);
                    ref.read(fileTreeProvider.notifier).loadRoots(
                          ref.read(settingsProvider).rootFolders,
                          ref.read(settingsProvider),
                        );
                  }
                },
                onSettings: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: const _FolderTreeContent()),
                    const _BookmarkSection(),
                    const ListSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Main area: file list or viewer
        Expanded(
          child: selectedFile == null
              ? const _FileListContent()
              : _ViewerContent(showBackButton: true),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// MOBILE LAYOUT (< 600px) — 1 panel + drawer + bottom nav
// ═══════════════════════════════════════════════════

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(uiProvider);
    final selectedFile = ref.watch(selectedFileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      // App bar
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          onPressed: () {
            ref.read(uiProvider.notifier).toggleSidebarDrawer();
          },
        ),
        title: Row(
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.notebook,
              size: 20,
              color: AppColors.accent,
            ),
            const SizedBox(width: 8),
            const Text(
              'MD Explorer',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: PhosphorIcon(
              PhosphorIconsRegular.arrowClockwise,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              ref.read(fileTreeProvider.notifier).refresh(
                    ref.read(settingsProvider).rootFolders,
                    ref.read(settingsProvider),
                  );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      // Drawer: folder tree
      drawer: _MobileDrawer(),
      // Body: depends on active panel
      body: switch (uiState.activeMobilePanel) {
        MobilePanel.tree => const _FolderTreeContent(),
        MobilePanel.files => const _FileListContent(),
        MobilePanel.viewer => selectedFile != null
            ? _ViewerContent(showBackButton: true)
            : const _MobileEmptyViewer(),
      },
      // Bottom navigation
      bottomNavigationBar: _MobileBottomNav(),
      // FAB: add folder (only on tree/files panel)
      floatingActionButton: uiState.activeMobilePanel != MobilePanel.viewer
          ? FloatingActionButton.small(
              heroTag: 'addFolder',
              backgroundColor: AppColors.accent,
              onPressed: () async {
                final result = await FilePicker.platform.getDirectoryPath();
                if (result != null) {
                  await ref.read(settingsProvider.notifier).addRootFolder(result);
                  ref.read(fileTreeProvider.notifier).loadRoots(
                        ref.read(settingsProvider).rootFolders,
                        ref.read(settingsProvider),
                      );
                }
              },
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            )
          : null,
    );
  }
}

/// Mobile drawer containing the folder tree, bookmarks, and lists.
class _MobileDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: AppColors.backgroundSurface,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.notebook,
                    size: 24,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'MD Explorer',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: PhosphorIcon(
                      PhosphorIconsRegular.plus,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await FilePicker.platform.getDirectoryPath();
                      if (result != null) {
                        await ref.read(settingsProvider.notifier).addRootFolder(result);
                        ref.read(fileTreeProvider.notifier).loadRoots(
                              ref.read(settingsProvider).rootFolders,
                              ref.read(settingsProvider),
                            );
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: const _FolderTreeContent()),
                  const _BookmarkSection(),
                  const ListSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mobile bottom navigation bar.
class _MobileBottomNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(uiProvider);
    final selectedFile = ref.watch(selectedFileProvider);

    // If no file selected, only show Tree and Files tabs
    final hasViewer = selectedFile != null;

    return NavigationBar(
      backgroundColor: AppColors.backgroundSurface,
      indicatorColor: AppColors.accentSoft,
      selectedIndex: switch (uiState.activeMobilePanel) {
        MobilePanel.tree => 0,
        MobilePanel.files => 1,
        MobilePanel.viewer => hasViewer ? 2 : 1,
      },
      onDestinationSelected: (index) {
        if (index == 0) {
          ref.read(uiProvider.notifier).setMobilePanel(MobilePanel.tree);
        } else if (index == 1) {
          ref.read(uiProvider.notifier).setMobilePanel(MobilePanel.files);
        } else if (index == 2 && hasViewer) {
          ref.read(uiProvider.notifier).setMobilePanel(MobilePanel.viewer);
        }
      },
      destinations: [
        NavigationDestination(
          icon: PhosphorIcon(
            PhosphorIconsRegular.folder,
            size: 24,
            color: uiState.activeMobilePanel == MobilePanel.tree
                ? AppColors.accent
                : AppColors.textMuted,
          ),
          label: 'Folders',
        ),
        NavigationDestination(
          icon: PhosphorIcon(
            PhosphorIconsRegular.files,
            size: 24,
            color: uiState.activeMobilePanel == MobilePanel.files
                ? AppColors.accent
                : AppColors.textMuted,
          ),
          label: 'Files',
        ),
        if (hasViewer)
          NavigationDestination(
            icon: PhosphorIcon(
              PhosphorIconsRegular.fileText,
              size: 24,
              color: uiState.activeMobilePanel == MobilePanel.viewer
                  ? AppColors.accent
                  : AppColors.textMuted,
            ),
            label: 'Viewer',
          ),
      ],
    );
  }
}

/// Mobile empty state for viewer when no file is selected.
class _MobileEmptyViewer extends StatelessWidget {
  const _MobileEmptyViewer();

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 8),
          Text(
            'Tap a file from the Files tab',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// SHARED COMPONENTS (used by all layout modes)
// ═══════════════════════════════════════════════════

/// App header with logo, refresh, add folder.
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
          const Text(
            'MD Explorer',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: PhosphorIcon(
              PhosphorIconsRegular.arrowClockwise,
              size: 18,
              color: AppColors.textMuted,
            ),
            tooltip: 'Refresh',
            onPressed: onRefresh,
            // Ensure 48px touch target
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
          ),
        ],
      ),
    );
  }
}

/// Folder tree content — used by all layouts.
class _FolderTreeContent extends ConsumerWidget {
  const _FolderTreeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeState = ref.watch(fileTreeProvider);
    return treeState.when(
      data: (nodes) => nodes.isEmpty
          ? _EmptyTree(
              onAddFolder: () async {
                final result = await FilePicker.platform.getDirectoryPath();
                if (result != null) {
                  await ref.read(settingsProvider.notifier).addRootFolder(result);
                  ref.read(fileTreeProvider.notifier).loadRoots(
                        ref.read(settingsProvider).rootFolders,
                        ref.read(settingsProvider),
                      );
                }
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: nodes.length,
              itemBuilder: (context, index) {
                return _TreeNodeWidget(node: nodes[index], depth: 0);
              },
            ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => _EmptyTree(
        error: e.toString(),
        onAddFolder: () async {
          final result = await FilePicker.platform.getDirectoryPath();
          if (result != null) {
            await ref.read(settingsProvider.notifier).addRootFolder(result);
            ref.read(fileTreeProvider.notifier).loadRoots(
                  ref.read(settingsProvider).rootFolders,
                  ref.read(settingsProvider),
                );
          }
        },
      ),
    );
  }
}

class _EmptyTree extends StatelessWidget {
  final String? error;
  final VoidCallback onAddFolder;
  const _EmptyTree({this.error, required this.onAddFolder});

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
              error ?? 'No folders added',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddFolder,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Folder'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(140, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// File list content — used by all layouts.
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
                            : 'No markdown files',
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
                          // On mobile, auto-navigate to viewer
                          if (AppBreakpoints.isCompact(context)) {
                            ref.read(uiProvider.notifier).navigateToViewer();
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14), // 44px min height
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

/// Viewer content — used by all layouts.
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
              // Bookmark
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
              // Fullscreen
              IconButton(
                icon: const Icon(Icons.open_in_full, color: AppColors.textSecondary, size: 20),
                onPressed: () {
                  ref.read(uiProvider.notifier).setFullscreen(true);
                },
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              // Close
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
      error: (_, __) => const SizedBox.shrink(),
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
// FOLDER/FILE TREE WIDGETS (shared)
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
          // 44px min touch target for mobile
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
                // Bookmark star
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
        // On mobile, auto-navigate to viewer
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
