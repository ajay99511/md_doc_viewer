import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/providers.dart';
import 'utils/constants.dart';
import 'utils/syntax_languages.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register syntax highlighting languages
  registerHighlightLanguages();

  // Window setup for desktop
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'MD Explorer',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: MDExplorerApp()));
}

class MDExplorerApp extends ConsumerWidget {
  const MDExplorerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'MD Explorer',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: _buildThemeData(Brightness.light),
      darkTheme: _buildThemeData(Brightness.dark),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildThemeData(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark ? darkColorScheme : lightColorScheme;

    return ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: isDark ? AppColors.backgroundBase : const Color(0xFFF8FAFC),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.backgroundSurface : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? AppColors.textPrimary : Colors.black87),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.backgroundElevated : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: isDark ? AppColors.textMuted : Colors.black38),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.borderSubtle : Colors.grey.shade200,
      ),
    );
  }
}
