import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/palette.dart';
import '../../utils/syntax_languages.dart';

/// Production-grade GitHub-style markdown renderer.
///
/// Uses flutter_markdown_plus (GitHub Flavored Markdown) plus:
/// - real syntax highlighting for fenced code blocks (flutter_highlight),
/// - tappable links (opened via url_launcher),
/// - inline image rendering (network + local, relative paths resolved against
///   [documentPath]),
/// - a guard that defers rendering very large documents until the user opts in.
class MarkdownContent extends ConsumerStatefulWidget {
  final String content;
  final double? customFontSize;

  /// Absolute path of the source document. Used to resolve relative image and
  /// link targets. Null for content with no on-disk origin.
  final String? documentPath;

  const MarkdownContent({
    super.key,
    required this.content,
    this.customFontSize,
    this.documentPath,
  });

  @override
  ConsumerState<MarkdownContent> createState() => _MarkdownContentState();
}

class _MarkdownContentState extends ConsumerState<MarkdownContent> {
  /// Above this size (in characters) rendering is deferred behind a tap so the
  /// UI thread isn't blocked building a huge widget tree unexpectedly.
  static const _largeThreshold = 500 * 1024;

  bool _forceRender = false;

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.customFontSize ?? ref.watch(settingsProvider).markdownFontSize;

    if (widget.content.length > _largeThreshold && !_forceRender) {
      return _LargeFileNotice(
        sizeLabel: _formatBytes(widget.content.length),
        onRender: () => setState(() => _forceRender = true),
      );
    }

    final baseDir = widget.documentPath != null ? p.dirname(widget.documentPath!) : null;

    return Markdown(
      data: widget.content,
      selectable: true,
      padding: const EdgeInsets.all(24),
      extensionSet: md.ExtensionSet.gitHubFlavored,
      onTapLink: (text, href, title) => _handleLink(href, baseDir),
      imageBuilder: (uri, title, alt) => _buildImage(uri, alt, baseDir),
      builders: {
        'code': _CodeElementBuilder(fontSize: fontSize),
      },
      styleSheet: MarkdownStyleSheet(
        h1: TextStyle(
          color: context.palette.textPrimary,
          fontSize: fontSize + 14,
          fontWeight: FontWeight.w800,
          height: 1.25,
          letterSpacing: -0.5,
        ),
        h2: TextStyle(
          color: context.palette.textPrimary,
          fontSize: fontSize + 10,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        h3: TextStyle(
          color: context.palette.textPrimary,
          fontSize: fontSize + 6,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        h4: TextStyle(
          color: context.palette.textPrimary,
          fontSize: fontSize + 2,
          fontWeight: FontWeight.w600,
        ),
        h5: TextStyle(
          color: context.palette.textPrimary,
          fontSize: fontSize + 1,
          fontWeight: FontWeight.w600,
        ),
        h6: TextStyle(
          color: context.palette.textMuted,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
        p: TextStyle(
          color: context.palette.textSecondary,
          fontSize: fontSize,
          height: 1.7,
          fontWeight: FontWeight.w400,
        ),
        // Inline code only — fenced blocks are handled by _CodeElementBuilder.
        code: TextStyle(
          color: const Color(0xFFE6EDF3),
          backgroundColor: const Color(0xFF161B22),
          fontSize: fontSize * 0.9,
          fontFamily: 'Consolas',
          fontWeight: FontWeight.w400,
        ),
        // Neutralised so the custom code-block builder fully controls block
        // appearance (no double background/padding).
        codeblockPadding: EdgeInsets.zero,
        codeblockDecoration: const BoxDecoration(),
        blockquote: TextStyle(
          color: context.palette.textMuted,
          fontSize: fontSize,
          height: 1.6,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: context.palette.borderDefault, width: 4),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
        listBullet: TextStyle(
          color: context.palette.textMuted,
          fontSize: fontSize,
        ),
        tableHead: TextStyle(
          color: context.palette.textPrimary,
          fontSize: fontSize * 0.95,
          fontWeight: FontWeight.w600,
        ),
        tableBody: TextStyle(
          color: context.palette.textSecondary,
          fontSize: fontSize * 0.95,
        ),
        tableBorder: TableBorder.all(
          color: context.palette.borderDefault,
          width: 1,
        ),
        tableColumnWidth: const FlexColumnWidth(),
        tableCellsPadding: const EdgeInsets.fromLTRB(13, 8, 13, 8),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: context.palette.borderSubtle, width: 1),
          ),
        ),
        a: TextStyle(
          color: AppColors.accent,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.accent.withValues(alpha: 0.4),
          fontSize: fontSize,
        ),
        strong: TextStyle(
          color: context.palette.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
        em: TextStyle(
          color: context.palette.textSecondary,
          fontStyle: FontStyle.italic,
          fontSize: fontSize,
        ),
        del: TextStyle(
          color: context.palette.textMuted,
          decoration: TextDecoration.lineThrough,
          fontSize: fontSize,
        ),
        blockSpacing: 8,
      ),
    );
  }

  Future<void> _handleLink(String? href, String? baseDir) async {
    if (href == null || href.isEmpty) return;

    Uri? uri = Uri.tryParse(href);
    if (uri == null) return;

    // External / protocol links open in the default handler.
    if (uri.hasScheme && uri.scheme != 'file') {
      await _launch(uri);
      return;
    }

    // In-document anchor (e.g. "#section") — nothing to open.
    if (href.startsWith('#')) return;

    // Local/relative target → resolve against the document directory.
    final resolved = _resolveLocal(href, baseDir);
    if (resolved != null) {
      await _launch(Uri.file(resolved));
    }
  }

  Future<void> _launch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        _toast('Could not open: $uri');
      }
    } catch (_) {
      if (mounted) _toast('Could not open link');
    }
  }

  Widget _buildImage(Uri uri, String? alt, String? baseDir) {
    Widget fallback() => _ImageError(alt: alt);

    if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(
        uri.toString(),
        errorBuilder: (_, _, _) => fallback(),
      );
    }

    final path = uri.scheme == 'file' ? uri.toFilePath() : _resolveLocal(uri.toString(), baseDir);
    if (path == null) return fallback();
    final file = File(path);
    if (!file.existsSync()) return fallback();
    return Image.file(file, errorBuilder: (_, _, _) => fallback());
  }

  /// Resolve a relative reference against [baseDir]; returns an absolute path
  /// or null when it cannot be resolved.
  String? _resolveLocal(String ref, String? baseDir) {
    try {
      if (p.isAbsolute(ref)) return ref;
      if (baseDir == null) return null;
      return p.normalize(p.join(baseDir, ref));
    } catch (_) {
      return null;
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static String _formatBytes(int n) {
    if (n < 1024) return '$n B';
    if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(0)} KB';
    return '${(n / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Renders fenced code blocks with syntax highlighting and a copy button.
/// Inline code (single line, no language class) falls back to the default
/// style by returning null.
class _CodeElementBuilder extends MarkdownElementBuilder {
  final double fontSize;

  _CodeElementBuilder({required this.fontSize});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent;
    final className = element.attributes['class'];
    final hasLanguage = className != null && className.startsWith('language-');
    final isBlock = hasLanguage || text.contains('\n');
    if (!isBlock) return null; // inline code → default rendering

    final language = hasLanguage ? className.substring('language-'.length) : null;
    final effectiveLanguage =
        (language != null && isSupportedHighlightLanguage(language)) ? language : null;

    // Trailing newline is common from the parser; trim it for tidy rendering.
    final code = text.endsWith('\n') ? text.substring(0, text.length - 1) : text;

    return _CodeBlock(
      code: code,
      language: effectiveLanguage,
      fontSize: fontSize,
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  final String? language;
  final double fontSize;

  const _CodeBlock({required this.code, required this.language, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: language label + copy button.
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.palette.borderSubtle)),
            ),
            child: Row(
              children: [
                Text(
                  language ?? 'text',
                  style: TextStyle(
                    color: context.palette.textMuted,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                _CopyButton(code: code),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: language != null
                // Highlighted: language is guaranteed registered by the caller.
                ? HighlightView(
                    code,
                    language: language!,
                    theme: atomOneDarkTheme,
                    padding: const EdgeInsets.all(16),
                    textStyle: TextStyle(
                      fontFamily: 'Consolas',
                      fontSize: fontSize * 0.9,
                    ),
                  )
                // No (registered) language → plain monospace, no highlighter.
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      code,
                      style: TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: fontSize * 0.9,
                        color: const Color(0xFFE6EDF3),
                        height: 1.45,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String code;
  const _CopyButton({required this.code});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: widget.code));
        if (!mounted) return;
        setState(() => _copied = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _copied = false);
        });
      },
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(
        _copied ? Icons.check : Icons.copy,
        size: 14,
        color: _copied ? AppColors.success : context.palette.textMuted,
      ),
      label: Text(
        _copied ? 'Copied' : 'Copy',
        style: TextStyle(
          fontSize: 11,
          color: _copied ? AppColors.success : context.palette.textMuted,
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  final String? alt;
  const _ImageError({this.alt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.backgroundElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.palette.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 18, color: context.palette.textMuted),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              alt?.isNotEmpty == true ? alt! : 'Image unavailable',
              style: TextStyle(color: context.palette.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeFileNotice extends StatelessWidget {
  final String sizeLabel;
  final VoidCallback onRender;

  const _LargeFileNotice({required this.sizeLabel, required this.onRender});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 48, color: context.palette.textMuted),
            const SizedBox(height: 16),
            Text(
              'Large document ($sizeLabel)',
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rendering may take a moment and use more memory.',
              style: TextStyle(color: context.palette.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRender,
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Render anyway'),
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
}
