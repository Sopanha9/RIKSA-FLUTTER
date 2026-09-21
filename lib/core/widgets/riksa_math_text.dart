import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

import '../theme/app_theme.dart';

/// A widget that renders text containing optional LaTeX / math expressions.
///
/// Plain text is rendered directly via [Text] with Khmer typography preserved.
/// If math delimiters (`$formula$` or `$$formula$$`) are detected, [RiksaMathText]
/// parses and renders them cleanly using [Math.tex].
class RiksaMathText extends StatelessWidget {
  const RiksaMathText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  static final _mathRegex = RegExp(r'(\$\$[\s\S]+?\$\$|\$[^\$\n]+?\$)');

  /// Markdown inline syntax for embedding math inside [MarkdownBody].
  static List<md.InlineSyntax> get markdownSyntaxes => [RiksaMathSyntax()];

  /// Markdown element builders for rendering `<latex>` tags inside [MarkdownBody].
  static Map<String, MarkdownElementBuilder> get markdownBuilders => {
    'latex': RiksaMathElementBuilder(),
  };

  @override
  Widget build(BuildContext context) {
    if (!text.contains(r'$')) {
      return Text(
        text,
        style: RiksaTypography.bodyStyleFor(text, style),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final spans = _parseSpans(context, text, style);
    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  static List<InlineSpan> _parseSpans(
    BuildContext context,
    String raw,
    TextStyle? baseStyle,
  ) {
    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in _mathRegex.allMatches(raw)) {
      if (match.start > lastIndex) {
        final textPart = raw.substring(lastIndex, match.start);
        spans.add(
          TextSpan(
            text: textPart,
            style: RiksaTypography.bodyStyleFor(textPart, baseStyle),
          ),
        );
      }

      final matchedString = match.group(0)!;
      final isBlock = matchedString.startsWith(r'$$') && matchedString.endsWith(r'$$');
      final latex = isBlock
          ? matchedString.substring(2, matchedString.length - 2).trim()
          : matchedString.substring(1, matchedString.length - 1).trim();

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Math.tex(
              latex,
              textStyle: baseStyle,
              mathStyle: isBlock ? MathStyle.display : MathStyle.text,
              onErrorFallback: (_) => Text(
                matchedString,
                style: (baseStyle ?? const TextStyle()).copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < raw.length) {
      final textPart = raw.substring(lastIndex);
      spans.add(
        TextSpan(
          text: textPart,
          style: RiksaTypography.bodyStyleFor(textPart, baseStyle),
        ),
      );
    }

    return spans;
  }
}

/// Matches `$formula$` and `$$formula$$` within Markdown streams.
class RiksaMathSyntax extends md.InlineSyntax {
  RiksaMathSyntax() : super(r'(\$\$[\s\S]+?\$\$|\$[^\$\n]+?\$)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final raw = match.group(0)!;
    final isBlock = raw.startsWith(r'$$') && raw.endsWith(r'$$');
    final latex = isBlock
        ? raw.substring(2, raw.length - 2).trim()
        : raw.substring(1, raw.length - 1).trim();

    final element = md.Element('latex', [md.Text(latex)]);
    element.attributes['display'] = isBlock ? 'block' : 'inline';
    parser.addNode(element);
    return true;
  }
}

/// Renders `<latex>` markdown nodes using [Math.tex].
class RiksaMathElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final latex = element.textContent;
    final isBlock = element.attributes['display'] == 'block';
    final effectiveStyle = preferredStyle ?? parentStyle;

    return Math.tex(
      latex,
      textStyle: effectiveStyle,
      mathStyle: isBlock ? MathStyle.display : MathStyle.text,
      onErrorFallback: (_) => Text(
        isBlock ? '\$\$$latex\$\$' : '\$$latex\$',
        style: (effectiveStyle ?? const TextStyle()).copyWith(
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
