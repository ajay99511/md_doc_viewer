import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which mobile panel is currently visible.
enum MobilePanel { tree, files, viewer }

/// UI state for all layout modes.
class UIState {
  final bool isViewerFullscreen;
  final String searchQuery;

  // Mobile navigation state
  final MobilePanel activeMobilePanel;
  final bool isSidebarDrawerOpen;

  UIState({
    this.isViewerFullscreen = false,
    this.searchQuery = '',
    this.activeMobilePanel = MobilePanel.files,
    this.isSidebarDrawerOpen = false,
  });

  UIState copyWith({
    bool? isViewerFullscreen,
    String? searchQuery,
    MobilePanel? activeMobilePanel,
    bool? isSidebarDrawerOpen,
  }) {
    return UIState(
      isViewerFullscreen: isViewerFullscreen ?? this.isViewerFullscreen,
      searchQuery: searchQuery ?? this.searchQuery,
      activeMobilePanel: activeMobilePanel ?? this.activeMobilePanel,
      isSidebarDrawerOpen: isSidebarDrawerOpen ?? this.isSidebarDrawerOpen,
    );
  }
}

final uiProvider = StateNotifierProvider<UINotifier, UIState>((ref) {
  return UINotifier();
});

class UINotifier extends StateNotifier<UIState> {
  UINotifier() : super(UIState());

  void toggleFullscreen() {
    state = state.copyWith(isViewerFullscreen: !state.isViewerFullscreen);
  }

  void setFullscreen(bool value) {
    state = state.copyWith(isViewerFullscreen: value);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // Mobile navigation
  void setMobilePanel(MobilePanel panel) {
    state = state.copyWith(activeMobilePanel: panel, isSidebarDrawerOpen: false);
  }

  void navigateToViewer() {
    state = state.copyWith(activeMobilePanel: MobilePanel.viewer);
  }

  void navigateToFiles() {
    state = state.copyWith(activeMobilePanel: MobilePanel.files);
  }

  void navigateToTree() {
    state = state.copyWith(activeMobilePanel: MobilePanel.tree);
  }

  void toggleSidebarDrawer() {
    state = state.copyWith(isSidebarDrawerOpen: !state.isSidebarDrawerOpen);
  }

  void closeSidebarDrawer() {
    state = state.copyWith(isSidebarDrawerOpen: false);
  }
}
