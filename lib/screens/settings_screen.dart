import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/app_settings.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';

/// Settings page: manage root folders, theme, and preferences.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // No auto-scan needed - folders are loaded on app startup
    // Only reload when user makes changes (add/remove/refresh)
  }

  Future<void> _addFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null && mounted) {
      await ref.read(settingsProvider.notifier).addRootFolder(result);
      // Reload tree with new folder
      final settings = ref.read(settingsProvider);
      if (mounted) {
        ref.read(fileTreeProvider.notifier).loadRoots(settings.rootFolders, settings, ref: ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Folder added: ${result.split('/').last}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeFolder(String path) async {
    await ref.read(settingsProvider.notifier).removeRootFolder(path);
    // Reload tree with remaining folders
    final settings = ref.read(settingsProvider);
    ref.read(fileTreeProvider.notifier).loadRoots(settings.rootFolders, settings, ref: ref);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ─── Root Folders ───
          _SectionHeader(title: 'Root Folders', icon: PhosphorIconsRegular.folder),
          const SizedBox(height: 12),
          if (settings.rootFolders.isEmpty)
            _EmptyStateMessage('No folders added yet')
          else
            ...settings.rootFolders.map((path) => _FolderItem(
                  path: path,
                  onRemove: () => _removeFolder(path),
                )),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _addFolder,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Folder'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const SizedBox(height: 32),

          // ─── Appearance ───
          _SectionHeader(title: 'Appearance', icon: PhosphorIconsRegular.paintBrush),
          const SizedBox(height: 12),
          _ThemeSelector(settings: settings),
          const SizedBox(height: 16),
          _FontSizeSlider(settings: settings),

          const SizedBox(height: 32),

          // ─── File Types ───
          _SectionHeader(title: 'File Types', icon: PhosphorIconsRegular.file),
          const SizedBox(height: 12),
          _ExtensionChips(settings: settings),

          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(
              'Show hidden files',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            subtitle: const Text(
              'Include files and folders starting with a dot',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            value: settings.showHiddenFiles,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).update(showHiddenFiles: value);
            },
            activeThumbColor: AppColors.accent,
          ),

          const SizedBox(height: 32),

          // ─── Actions ───
          _SectionHeader(title: 'Actions', icon: PhosphorIconsRegular.wrench),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              if (settings.rootFolders.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No folders added yet'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              ref.read(fileTreeProvider.notifier).refresh(
                    settings.rootFolders,
                    settings,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Folders refreshed successfully'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh All Folders'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.backgroundElevated,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const SizedBox(height: 48),

          // ─── About ───
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'MD Explorer v1.0.0',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          Center(
            child: Text(
              'Built with Flutter',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyStateMessage extends StatelessWidget {
  final String message;

  const _EmptyStateMessage(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        message,
        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _FolderItem extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _FolderItem({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.folder,
            size: 18,
            color: AppColors.folderIcon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              path,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: PhosphorIcon(
              PhosphorIconsRegular.trash,
              size: 16,
              color: AppColors.textMuted,
            ),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  final AppSettings settings;

  const _ThemeSelector({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Theme',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ButtonSegment(value: ThemeMode.system, label: Text('System')),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (Set<ThemeMode> selected) {
            ref.read(settingsProvider.notifier).update(themeMode: selected.first);
          },
          style: SegmentedButton.styleFrom(
            backgroundColor: AppColors.backgroundElevated,
            foregroundColor: AppColors.textPrimary,
            selectedBackgroundColor: AppColors.accentSoft,
            selectedForegroundColor: AppColors.accent,
            side: BorderSide(color: AppColors.borderSubtle),
          ),
        ),
      ],
    );
  }
}

class _FontSizeSlider extends ConsumerWidget {
  final AppSettings settings;

  const _FontSizeSlider({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Markdown font size',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
            Text(
              '${settings.markdownFontSize.toInt()}',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
        Slider(
          value: settings.markdownFontSize,
          min: 10,
          max: 24,
          divisions: 14,
          label: '${settings.markdownFontSize.toInt()}',
          activeColor: AppColors.accent,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).update(markdownFontSize: value);
          },
        ),
      ],
    );
  }
}

class _ExtensionChips extends ConsumerWidget {
  final AppSettings settings;

  const _ExtensionChips({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allExtensions = ['md', 'markdown', 'mdx', 'txt', 'rst'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allExtensions.map((ext) {
        final isSelected = settings.allowedExtensions.contains(ext);
        return FilterChip(
          label: Text('.$ext'),
          selected: isSelected,
          onSelected: (selected) {
            final current = List<String>.from(settings.allowedExtensions);
            if (selected) {
              current.add(ext);
            } else {
              current.remove(ext);
            }
            ref.read(settingsProvider.notifier).update(allowedExtensions: current);
          },
          selectedColor: AppColors.accentSoft,
          checkmarkColor: AppColors.accent,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.accent : AppColors.borderSubtle,
          ),
        );
      }).toList(),
    );
  }
}
