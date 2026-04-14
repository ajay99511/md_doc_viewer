import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/file_node.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/viewer/markdown_content.dart';
import '../widgets/sidebar/list_section.dart';
import 'settings_screen.dart';
import 'md_library_screen.dart';

import 'package:permission_handler/permission_handler.dart';

part 'home_layouts.dart';
part 'home_widgets.dart';

/// Main home screen — fully responsive across mobile/tablet/desktop.
///
/// Key model: User explicitly adds folders to scan. No full-disk scanning.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
    // Auto-load configured folders on startup (shallow — instant)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      if (settings.rootFolders.isNotEmpty) {
        ref.read(fileTreeProvider.notifier).loadRoots(
              settings.rootFolders,
              settings,
              ref: ref,
            );
      }
    });
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 11+
      if (!await Permission.manageExternalStorage.isGranted) {
        await Permission.manageExternalStorage.request();
      }
      // Android 10 and lower
      if (!await Permission.storage.isGranted) {
        await Permission.storage.request();
      }
    }
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
