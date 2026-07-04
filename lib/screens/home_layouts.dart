part of 'home_screen.dart';

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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassPanel(child: _DesktopSidebar(ref: ref)),
          const SizedBox(width: 24),
          GlassPanel(child: _DesktopFileList(ref: ref)),
          const SizedBox(width: 24),
          Expanded(child: GlassPanel(withGlow: true, child: _DesktopViewer(ref: ref))),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends ConsumerWidget {
  final WidgetRef ref;
  const _DesktopSidebar({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          _AppHeader(
            onRefresh: () => ref.read(fileTreeProvider.notifier).refresh(
                  ref.read(settingsProvider).rootFolders,
                  ref.read(settingsProvider),
                  ref: ref,
                ),
            onAddFolder: () async {
              final result = await FilePicker.platform.getDirectoryPath();
              if (result != null) {
                await ref.read(settingsProvider.notifier).addRootFolder(result);
                final settings = ref.read(settingsProvider);
                ref.read(fileTreeProvider.notifier).loadRoots(
                      settings.rootFolders,
                      settings,
                      ref: ref,
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
    return SizedBox(
      width: 320,
      child: const _FileListContent(),
    );
  }
}

class _DesktopViewer extends ConsumerWidget {
  final WidgetRef ref;
  const _DesktopViewer({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    return const _ViewerContent();
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassPanel(
            child: SizedBox(
              width: 260,
              child: Column(
                children: [
                  _AppHeader(
                    onRefresh: () => ref.read(fileTreeProvider.notifier).refresh(
                          ref.read(settingsProvider).rootFolders,
                          ref.read(settingsProvider),
                          ref: ref,
                        ),
                    onAddFolder: () async {
                      final result = await FilePicker.platform.getDirectoryPath();
                      if (result != null) {
                        await ref.read(settingsProvider.notifier).addRootFolder(result);
                        ref.read(fileTreeProvider.notifier).loadRoots(
                              ref.read(settingsProvider).rootFolders,
                              ref.read(settingsProvider),
                              ref: ref,
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
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GlassPanel(
              withGlow: selectedFile != null,
              child: selectedFile == null
                  ? const _FileListContent()
                  : const _ViewerContent(showBackButton: true),
            ),
          ),
        ],
      ),
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.2),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: context.palette.textPrimary),
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
            Text(
              'MD Explorer',
              style: TextStyle(
                color: context.palette.textPrimary,
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
              color: context.palette.textSecondary,
            ),
            onPressed: () {
              ref.read(fileTreeProvider.notifier).refresh(
                    ref.read(settingsProvider).rootFolders,
                    ref.read(settingsProvider),
                    ref: ref,
                  );
            },
          ),
          IconButton(
            icon: PhosphorIcon(
              PhosphorIconsRegular.books,
              size: 22,
              color: context.palette.textSecondary,
            ),
            tooltip: 'My Library',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MdLibraryScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.palette.textSecondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: _MobileDrawer(),
      body: switch (uiState.activeMobilePanel) {
        MobilePanel.tree => const _FolderTreeContent(),
        MobilePanel.files => const _FileListContent(),
        MobilePanel.viewer => selectedFile != null
            ? _ViewerContent(showBackButton: true)
            : const _MobileEmptyViewer(),
      },
      bottomNavigationBar: _MobileBottomNav(),
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
                        ref: ref,
                      );
                }
              },
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            )
          : null,
    );
  }
}

class _MobileDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.cpu, // Updated icon
                    size: 24,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'NEXUS DB',
                    style: TextStyle(
                      color: context.palette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: PhosphorIcon(
                      PhosphorIconsRegular.plus,
                      size: 20,
                      color: context.palette.textSecondary,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await FilePicker.platform.getDirectoryPath();
                      if (result != null) {
                        await ref.read(settingsProvider.notifier).addRootFolder(result);
                        ref.read(fileTreeProvider.notifier).loadRoots(
                              ref.read(settingsProvider).rootFolders,
                              ref.read(settingsProvider),
                              ref: ref,
                            );
                      }
                    },
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.palette.borderSubtle),
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

class _MobileBottomNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(uiProvider);
    final selectedFile = ref.watch(selectedFileProvider);
    final hasViewer = selectedFile != null;

    return NavigationBar(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
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
                : context.palette.textMuted,
          ),
          label: 'Folders',
        ),
        NavigationDestination(
          icon: PhosphorIcon(
            PhosphorIconsRegular.files,
            size: 24,
            color: uiState.activeMobilePanel == MobilePanel.files
                ? AppColors.accent
                : context.palette.textMuted,
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
                  : context.palette.textMuted,
            ),
            label: 'Viewer',
          ),
      ],
    );
  }
}

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
            color: context.palette.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a file to view',
            style: TextStyle(
              color: context.palette.textMuted,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a file from the Files tab',
            style: TextStyle(
              color: context.palette.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

