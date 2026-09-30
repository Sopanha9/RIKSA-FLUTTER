import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// LaTeX math inside markdown: `$…$` inline and `$$…$$` on its own.
///
/// Lessons, the AI tutor and articles write formulas the way most tools do,
/// and plain markdown shows them as raw `$U = I \cdot R$`. Pass
/// [markdownMathSyntaxes] and [markdownMathBuilders] to a `MarkdownBody`.
final List<md.InlineSyntax> markdownMathSyntaxes = [_MathSyntax()];

final Map<String, MarkdownElementBuilder> markdownMathBuilders = {
  _mathTag: _MathBuilder(),
};

const _mathTag = 'math';

class _MathSyntax extends md.InlineSyntax {
  // `$$…$$` may span lines. A single `$…$` stays on one line and may not
  // start or end with a space, so prose such as "costs $5 or $10" is left
  // alone.
  _MathSyntax()
    : super(
        r'\$\$([\s\S]+?)\$\$|\$(?![\s$])((?:\\\$|[^$\n])+?)(?<!\s)\$',
        startCharacter: 0x24, // $
      );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final display = match[1] != null;
    final tex = (display ? match[1] : match[2])!.trim();
    if (tex.isEmpty) return false;
    parser.addNode(
      md.Element.text(_mathTag, tex)
        ..attributes['display'] = display.toString(),
    );
    return true;
  }
}

class _MathBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final tex = element.textContent;
    final display = element.attributes['display'] == 'true';
    final style =
        parentStyle ?? preferredStyle ?? DefaultTextStyle.of(context).style;
    Widget formula = Math.tex(
      tex,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: style,
      // Formulas the parser cannot read still show their source rather than
      // disappearing.
      onErrorFallback: (_) => Text(tex, style: style),
    );
    if (display) {
      formula = Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: formula,
        ),
      );
    }
    // A Text.rich lets the markdown builder merge the formula into the
    // sentence around it instead of breaking the paragraph apart.
    return Text.rich(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        baseline: TextBaseline.alphabetic,
        child: formula,
      ),
    );
  }
}
