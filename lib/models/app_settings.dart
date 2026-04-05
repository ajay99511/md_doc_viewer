import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings persisted via SharedPreferences.
class AppSettings {
  // Theme
  final ThemeMode themeMode;

  // Markdown rendering
  final double markdownFontSize;
  final bool showLineNumbers;

  // File scanning
  final List<String> rootFolders;
  final List<String> allowedExtensions;
  final bool showHiddenFiles;

  // UI
  final double sidebarWidth;
  final double fileListWidth;

  AppSettings({
    this.themeMode = ThemeMode.system,
    this.markdownFontSize = 16.0,
    this.showLineNumbers = false,
    List<String>? rootFolders,
    List<String>? allowedExtensions,
    this.showHiddenFiles = false,
    this.sidebarWidth = 280.0,
    this.fileListWidth = 320.0,
  })  : rootFolders = rootFolders ?? [],
        allowedExtensions = allowedExtensions ?? ['md', 'markdown', 'mdx', 'txt'];

  static const _keyThemeMode = 'themeMode';
  static const _keyMarkdownFontSize = 'markdownFontSize';
  static const _keyRootFolders = 'rootFolders';
  static const _keyAllowedExtensions = 'allowedExtensions';
  static const _keyShowHiddenFiles = 'showHiddenFiles';
  static const _keySidebarWidth = 'sidebarWidth';
  static const _keyFileListWidth = 'fileListWidth';

  /// Load settings from SharedPreferences.
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeStr = prefs.getString(_keyThemeMode) ?? 'system';
    final themeMode = switch (themeModeStr) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };

    return AppSettings(
      themeMode: themeMode,
      markdownFontSize: prefs.getDouble(_keyMarkdownFontSize) ?? 16.0,
      rootFolders: prefs.getStringList(_keyRootFolders) ?? [],
      allowedExtensions: prefs.getStringList(_keyAllowedExtensions) ??
          ['md', 'markdown', 'mdx', 'txt'],
      showHiddenFiles: prefs.getBool(_keyShowHiddenFiles) ?? false,
      sidebarWidth: prefs.getDouble(_keySidebarWidth) ?? 280.0,
      fileListWidth: prefs.getDouble(_keyFileListWidth) ?? 320.0,
    );
  }

  /// Save settings to SharedPreferences.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyThemeMode,
        switch (themeMode) {
          ThemeMode.dark => 'dark',
          ThemeMode.light => 'light',
          ThemeMode.system => 'system',
        });
    await prefs.setDouble(_keyMarkdownFontSize, markdownFontSize);
    await prefs.setStringList(_keyRootFolders, rootFolders);
    await prefs.setStringList(_keyAllowedExtensions, allowedExtensions);
    await prefs.setBool(_keyShowHiddenFiles, showHiddenFiles);
    await prefs.setDouble(_keySidebarWidth, sidebarWidth);
    await prefs.setDouble(_keyFileListWidth, fileListWidth);
  }

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? markdownFontSize,
    bool? showLineNumbers,
    List<String>? rootFolders,
    List<String>? allowedExtensions,
    bool? showHiddenFiles,
    double? sidebarWidth,
    double? fileListWidth,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      markdownFontSize: markdownFontSize ?? this.markdownFontSize,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      rootFolders: rootFolders ?? this.rootFolders,
      allowedExtensions: allowedExtensions ?? this.allowedExtensions,
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      fileListWidth: fileListWidth ?? this.fileListWidth,
    );
  }
}
