import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../../core/theme/app_theme.dart';

/// Shared reader and composer-preview styling for community post markdown.
MarkdownStyleSheet socialMarkdownStyleSheet(
  BuildContext context,
  String content,
) {
  final theme = Theme.of(context);
  final palette = context.riksa;
  final hasKhmer = RiksaTypography.containsKhmer(content);

  TextStyle socialStyle(TextStyle? style) =>
      RiksaTypography.bodyStyleFor(content, style) ?? const TextStyle();

  final paragraph = socialStyle(
    theme.textTheme.bodyMedium?.copyWith(
      color: palette.ink,
      height: hasKhmer ? 1.55 : 1.5,
      fontSize: 16,
    ),
  );
  final heading = socialStyle(
    theme.textTheme.titleLarge?.copyWith(
      color: palette.ink,
      fontWeight: FontWeight.w600,
      height: hasKhmer ? 1.5 : 1.35,
    ),
  );

  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    textAlign: WrapAlignment.start,
    p: paragraph,
    pPadding: const EdgeInsets.only(bottom: 5),
    h1: heading.copyWith(fontSize: 20),
    h2: heading.copyWith(fontSize: 18),
    h3: heading.copyWith(fontSize: 16),
    h1Padding: const EdgeInsets.only(top: 8, bottom: 6),
    h2Padding: const EdgeInsets.only(top: 7, bottom: 5),
    h3Padding: const EdgeInsets.only(top: 6, bottom: 4),
    strong: socialStyle(const TextStyle(fontWeight: FontWeight.w700)),
    em: socialStyle(const TextStyle(fontStyle: FontStyle.italic)),
    a: socialStyle(
      TextStyle(
        color: palette.brandStrong,
        decoration: TextDecoration.underline,
      ),
    ),
    code: socialStyle(
      theme.textTheme.bodyMedium?.copyWith(
        color: palette.ink,
        backgroundColor: palette.surfaceRaised,
      ),
    ),
    codeblockDecoration: BoxDecoration(
      color: palette.surfaceRaised,
      borderRadius: AppRadii.smallBorder,
      border: Border.all(color: palette.outline),
    ),
    codeblockPadding: const EdgeInsets.all(12),
    blockquote: paragraph.copyWith(color: palette.inkMuted),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: palette.outline, width: 3)),
    ),
    blockquotePadding: const EdgeInsets.only(left: 12),
    listBullet: paragraph,
    blockSpacing: 10,
    listIndent: 22,
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: palette.outline)),
    ),
  );
}
