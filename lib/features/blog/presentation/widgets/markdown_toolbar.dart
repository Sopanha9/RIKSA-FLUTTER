import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// One formatting control offered by [BlogMarkdownToolbar].
///
/// The composer stores markdown as plain text, so every action is a pure
/// string edit on the field's value — see [applyBlogMarkdown].
enum BlogMarkdownAction {
  bold,
  italic,
  heading,
  quote,
  bulletList,
  numberedList,
  code,
  link,
}

/// Inline marker wrapped around the selection, or null for a line action.
String? _inlineMarker(BlogMarkdownAction action) => switch (action) {
  BlogMarkdownAction.bold => '**',
  BlogMarkdownAction.italic => '_',
  BlogMarkdownAction.code => '`',
  _ => null,
};

/// Matches the prefix a line action adds, so a second tap removes it.
RegExp? _linePattern(BlogMarkdownAction action) => switch (action) {
  BlogMarkdownAction.heading => RegExp(r'^#{1,6} '),
  BlogMarkdownAction.quote => RegExp(r'^> '),
  BlogMarkdownAction.bulletList => RegExp(r'^[-*+] '),
  BlogMarkdownAction.numberedList => RegExp(r'^\d+\. '),
  _ => null,
};

/// Applies [action] to [value] and returns the value the field should hold.
///
/// Every action toggles: running it over text it already produced strips the
/// markup again, so the toolbar never stacks `****bold****`.
TextEditingValue applyBlogMarkdown(
  TextEditingValue value,
  BlogMarkdownAction action,
) {
  final selection = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: value.text.length);
  final normalized = TextEditingValue(text: value.text, selection: selection);

  if (action == BlogMarkdownAction.link) return _insertLink(normalized);
  final marker = _inlineMarker(action);
  if (marker != null) return _toggleInline(normalized, marker);
  return _toggleLinePrefix(normalized, action);
}

TextEditingValue _toggleInline(TextEditingValue value, String marker) {
  final text = value.text;
  final start = value.selection.start;
  final end = value.selection.end;
  final selected = text.substring(start, end);
  final width = marker.length;

  // The markers sit inside the selection: `**bold**` fully highlighted.
  if (selected.length >= width * 2 &&
      selected.startsWith(marker) &&
      selected.endsWith(marker)) {
    final stripped = selected.substring(width, selected.length - width);
    return TextEditingValue(
      text: text.replaceRange(start, end, stripped),
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + stripped.length,
      ),
    );
  }

  // The markers sit just outside it: only `bold` highlighted in `**bold**`.
  if (start >= width &&
      end + width <= text.length &&
      text.substring(start - width, start) == marker &&
      text.substring(end, end + width) == marker) {
    final unwrapped = text
        .replaceRange(end, end + width, '')
        .replaceRange(start - width, start, '');
    return TextEditingValue(
      text: unwrapped,
      selection: TextSelection(
        baseOffset: start - width,
        extentOffset: end - width,
      ),
    );
  }

  return TextEditingValue(
    text: text.replaceRange(start, end, '$marker$selected$marker'),
    // With nothing selected the caret lands between the markers, ready to
    // type the word the writer was about to emphasise.
    selection: selected.isEmpty
        ? TextSelection.collapsed(offset: start + width)
        : TextSelection(baseOffset: start + width, extentOffset: end + width),
  );
}

TextEditingValue _toggleLinePrefix(
  TextEditingValue value,
  BlogMarkdownAction action,
) {
  final text = value.text;
  final pattern = _linePattern(action)!;
  final blockStart = _lineStartOf(text, value.selection.start);
  final nextBreak = text.indexOf('\n', value.selection.end);
  final blockEnd = nextBreak == -1 ? text.length : nextBreak;

  final lines = text.substring(blockStart, blockEnd).split('\n');
  final written = lines.where((line) => line.trim().isNotEmpty);
  final alreadyApplied =
      written.isNotEmpty && written.every((line) => pattern.hasMatch(line));

  var counter = 0;
  final rebuilt = lines
      .map((line) {
        if (alreadyApplied) return line.replaceFirst(pattern, '');
        if (line.trim().isEmpty) return line;
        // A line can only carry one block prefix, so drop whatever it has first.
        final bare = _stripAnyLinePrefix(line);
        counter++;
        return '${_prefixFor(action, counter)}$bare';
      })
      .join('\n');

  return TextEditingValue(
    text: text.replaceRange(blockStart, blockEnd, rebuilt),
    selection: TextSelection.collapsed(offset: blockStart + rebuilt.length),
  );
}

String _prefixFor(BlogMarkdownAction action, int position) => switch (action) {
  BlogMarkdownAction.heading => '## ',
  BlogMarkdownAction.quote => '> ',
  BlogMarkdownAction.bulletList => '- ',
  BlogMarkdownAction.numberedList => '$position. ',
  _ => '',
};

String _stripAnyLinePrefix(String line) {
  for (final action in const [
    BlogMarkdownAction.heading,
    BlogMarkdownAction.quote,
    BlogMarkdownAction.bulletList,
    BlogMarkdownAction.numberedList,
  ]) {
    final pattern = _linePattern(action)!;
    if (pattern.hasMatch(line)) return line.replaceFirst(pattern, '');
  }
  return line;
}

TextEditingValue _insertLink(TextEditingValue value) {
  final text = value.text;
  final start = value.selection.start;
  final end = value.selection.end;
  final label = text.substring(start, end);
  final snippet = '[$label](url)';
  // Highlight `url` so typing the address replaces the placeholder.
  final urlStart = start + label.length + 3;
  return TextEditingValue(
    text: text.replaceRange(start, end, snippet),
    selection: TextSelection(baseOffset: urlStart, extentOffset: urlStart + 3),
  );
}

/// Index of the first character on the line that holds [index].
int _lineStartOf(String text, int index) {
  if (index <= 0) return 0;
  final from = index > text.length ? text.length : index;
  return text.lastIndexOf('\n', from - 1) + 1;
}

/// Formatting strip pinned above the keyboard while the body has focus.
///
/// Buttons never take focus themselves, so the keyboard stays up and the
/// selection survives the tap.
class BlogMarkdownToolbar extends StatelessWidget {
  const BlogMarkdownToolbar({super.key, required this.onAction});

  final ValueChanged<BlogMarkdownAction> onAction;

  static List<(BlogMarkdownAction, IconData, String)> _controls(
    AppLocalizations l10n,
  ) => [
    (BlogMarkdownAction.bold, Icons.format_bold_rounded, l10n.markdownBold),
    (
      BlogMarkdownAction.italic,
      Icons.format_italic_rounded,
      l10n.markdownItalic,
    ),
    (BlogMarkdownAction.heading, Icons.title_rounded, l10n.markdownHeading),
    (BlogMarkdownAction.quote, Icons.format_quote_rounded, l10n.markdownQuote),
    (
      BlogMarkdownAction.bulletList,
      Icons.format_list_bulleted_rounded,
      l10n.markdownBulletList,
    ),
    (
      BlogMarkdownAction.numberedList,
      Icons.format_list_numbered_rounded,
      l10n.markdownNumberedList,
    ),
    (BlogMarkdownAction.code, Icons.code_rounded, l10n.markdownCode),
    (BlogMarkdownAction.link, Icons.link_rounded, l10n.markdownLink),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final controls = _controls(AppLocalizations.of(context)!);
    return SizedBox(
      // Icons stay 21px; the strip is tall enough for a 48px tap target.
      height: 48,
      // Buttons must not take focus, or the keyboard closes and the
      // selection the action needs is gone before it runs.
      child: ExcludeFocus(
        child: ListView.builder(
          key: const ValueKey('blog-markdown-toolbar'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.xs),
          itemCount: controls.length,
          itemBuilder: (context, index) {
            final (action, icon, label) = controls[index];
            return IconButton(
              key: ValueKey('blog-markdown-${action.name}'),
              onPressed: () => onAction(action),
              tooltip: label,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: palette.inkMuted,
                minimumSize: const Size(48, 48),
              ),
              icon: Icon(icon, size: 21),
            );
          },
        ),
      ),
    );
  }
}
