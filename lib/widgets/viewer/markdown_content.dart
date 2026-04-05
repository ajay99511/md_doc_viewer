import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import 'package:markdown/markdown.dart' as md;

/// Production-grade GitHub-style markdown renderer.
/// Uses flutter_markdown_plus with GitHub Flavored Markdown (GFM).
/// Supports: headings, tables, task lists, code blocks, blockquotes,
/// strikethrough, footnotes, and proper list rendering.
class MarkdownContent extends ConsumerWidget {
  final String content;
  final double? customFontSize;

  const MarkdownContent({super.key, required this.content, this.customFontSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = customFontSize ?? ref.watch(settingsProvider).markdownFontSize;

    return Markdown(
      data: content,
      selectable: true,
      padding: const EdgeInsets.all(24),
      // GitHub Flavored Markdown
      extensionSet: md.ExtensionSet.gitHubFlavored,
      // Link tap handler
      onTapLink: (text, href, title) {
        // Links are rendered but external opening would need url_launcher
      },
      styleSheet: MarkdownStyleSheet(
        // Headings - GitHub style
        h1: TextStyle(
          color: AppColors.textPrimary,
          fontSize: fontSize + 14,
          fontWeight: FontWeight.w800,
          height: 1.25,
          letterSpacing: -0.5,
        ),
        h2: TextStyle(
          color: AppColors.textPrimary,
          fontSize: fontSize + 10,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        h3: TextStyle(
          color: AppColors.textPrimary,
          fontSize: fontSize + 6,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        h4: TextStyle(
          color: AppColors.textPrimary,
          fontSize: fontSize + 2,
          fontWeight: FontWeight.w600,
        ),
        h5: TextStyle(
          color: AppColors.textPrimary,
          fontSize: fontSize + 1,
          fontWeight: FontWeight.w600,
        ),
        h6: TextStyle(
          color: AppColors.textMuted,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
        // Paragraphs - GitHub body text style
        p: TextStyle(
          color: AppColors.textSecondary,
          fontSize: fontSize,
          height: 1.7,
          fontWeight: FontWeight.w400,
        ),
        // Inline code
        code: TextStyle(
          color: const Color(0xFFE6EDF3),
          backgroundColor: const Color(0xFF161B22),
          fontSize: fontSize * 0.9,
          fontFamily: 'Consolas',
          fontWeight: FontWeight.w400,
        ),
        codeblockPadding: const EdgeInsets.all(16),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        // Blockquotes - GitHub style with left border
        blockquote: TextStyle(
          color: AppColors.textMuted,
          fontSize: fontSize,
          height: 1.6,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.borderDefault, width: 4),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
        // Lists
        listBullet: TextStyle(
          color: AppColors.textMuted,
          fontSize: fontSize,
        ),
        // Tables - GitHub style
        tableHead: TextStyle(
          color: AppColors.textPrimary,
          fontSize: fontSize * 0.95,
          fontWeight: FontWeight.w600,
        ),
        tableBody: TextStyle(
          color: AppColors.textSecondary,
          fontSize: fontSize * 0.95,
        ),
        tableBorder: TableBorder.all(
          color: AppColors.borderDefault,
          width: 1,
        ),
        tableColumnWidth: const FlexColumnWidth(),
        tableCellsPadding: const EdgeInsets.fromLTRB(13, 8, 13, 8),
        // Horizontal rule
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
        ),
        // Links
        a: TextStyle(
          color: AppColors.accent,
          decoration: TextDecoration.none,
          fontSize: fontSize,
        ),
        // Strong/bold
        strong: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
        // Emphasis/italic
        em: TextStyle(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
          fontSize: fontSize,
        ),
        // Strikethrough
        del: TextStyle(
          color: AppColors.textMuted,
          decoration: TextDecoration.lineThrough,
          fontSize: fontSize,
        ),
        // Block spacing
        blockSpacing: 8,
      ),
    );
  }
}
