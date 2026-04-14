import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/imported_file.dart';
import '../providers/imported_files_provider.dart';
import '../utils/constants.dart';
import '../widgets/viewer/markdown_content.dart';
import '../providers/settings_provider.dart';

/// Full-screen reader for an imported markdown file.
///
/// Uses the existing [MarkdownContent] widget to render GitHub-style markdown.
/// Provides font-size controls and a back button to return to the library.
class MdReaderScreen extends ConsumerStatefulWidget {
  final ImportedFile file;

  const MdReaderScreen({super.key, required this.file});

  @override
  ConsumerState<MdReaderScreen> createState() => _MdReaderScreenState();
}

class _MdReaderScreenState extends ConsumerState<MdReaderScreen> {
  String? _content;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(importServiceProvider);
      final content = await service.readFileContent(widget.file.storedPath);
      if (mounted) {
        setState(() {
          _content = content;
          _isLoading = false;
          if (content == null) {
            _error = 'File not found or cannot be read.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error reading file: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final fontSize = settings.markdownFontSize;

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.fileText,
              size: 18,
              color: AppColors.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.file.originalName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Font size controls
          IconButton(
            icon: const Icon(Icons.text_decrease, size: 20),
            color: AppColors.textMuted,
            onPressed: fontSize > 10
                ? () => ref.read(settingsProvider.notifier).update(
                      markdownFontSize: fontSize - 1,
                    )
                : null,
            tooltip: 'Decrease font size',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '${fontSize.toInt()}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase, size: 20),
            color: AppColors.textMuted,
            onPressed: fontSize < 28
                ? () => ref.read(settingsProvider.notifier).update(
                      markdownFontSize: fontSize + 1,
                    )
                : null,
            tooltip: 'Increase font size',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.accent,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 36,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadContent,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_content == null || _content!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.fileText,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'This file is empty',
              style: TextStyle(color: AppColors.textMuted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return MarkdownContent(content: _content!);
  }
}
