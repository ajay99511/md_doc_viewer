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
                    ref: ref,
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
      backgroundColor: AppColors.backgroundSurface,
      child: SafeArea(
        child: Column(
          children: [
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
                              ref: ref,
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

class _MobileBottomNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(uiProvider);
    final selectedFile = ref.watch(selectedFileProvider);
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

