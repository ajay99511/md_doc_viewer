import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';

// ─── Settings ───

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    state = await AppSettings.load();
  }

  Future<void> update({
    AppSettings? settings,
    ThemeMode? themeMode,
    double? markdownFontSize,
    List<String>? rootFolders,
    List<String>? allowedExtensions,
    bool? showHiddenFiles,
    double? sidebarWidth,
    double? fileListWidth,
  }) async {
    if (settings != null) {
      state = settings;
    } else {
      state = state.copyWith(
        themeMode: themeMode,
        markdownFontSize: markdownFontSize,
        rootFolders: rootFolders,
        allowedExtensions: allowedExtensions,
        showHiddenFiles: showHiddenFiles,
        sidebarWidth: sidebarWidth,
        fileListWidth: fileListWidth,
      );
    }
    await state.save();
  }

  Future<void> addRootFolder(String path) async {
    if (!state.rootFolders.contains(path)) {
      final updated = [...state.rootFolders, path];
      await update(rootFolders: updated);
    }
  }

  Future<void> removeRootFolder(String path) async {
    final updated = state.rootFolders.where((p) => p != path).toList();
    await update(rootFolders: updated);
  }
}
