import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/blog/presentation/widgets/markdown_toolbar.dart';

TextEditingValue valueOf(String text, {int? base, int? extent}) =>
    TextEditingValue(
      text: text,
      selection: TextSelection(
        baseOffset: base ?? text.length,
        extentOffset: extent ?? base ?? text.length,
      ),
    );

void main() {
  group('inline markers', () {
    test('wraps the selection in bold markers', () {
      final result = applyBlogMarkdown(
        valueOf('make this loud', base: 5, extent: 9),
        BlogMarkdownAction.bold,
      );
      expect(result.text, 'make **this** loud');
      expect(result.selection.textInside(result.text), 'this');
    });

    test('unwraps when the markers sit inside the selection', () {
      final result = applyBlogMarkdown(
        valueOf('make **this** loud', base: 5, extent: 13),
        BlogMarkdownAction.bold,
      );
      expect(result.text, 'make this loud');
    });

    test('unwraps when the markers sit outside the selection', () {
      final result = applyBlogMarkdown(
        valueOf('make **this** loud', base: 7, extent: 11),
        BlogMarkdownAction.bold,
      );
      expect(result.text, 'make this loud');
      expect(result.selection.textInside(result.text), 'this');
    });

    test('parks the caret between markers when nothing is selected', () {
      final result = applyBlogMarkdown(
        valueOf('note: ', base: 6),
        BlogMarkdownAction.italic,
      );
      expect(result.text, 'note: __');
      expect(result.selection.baseOffset, 7);
    });

    test('wraps code in backticks', () {
      final result = applyBlogMarkdown(
        valueOf('run flutter test', base: 4, extent: 16),
        BlogMarkdownAction.code,
      );
      expect(result.text, 'run `flutter test`');
    });
  });

  group('line prefixes', () {
    test('quotes the line holding the caret', () {
      final result = applyBlogMarkdown(
        valueOf('first\nsecond\nthird', base: 8),
        BlogMarkdownAction.quote,
      );
      expect(result.text, 'first\n> second\nthird');
    });

    test('a second tap removes the quote', () {
      final result = applyBlogMarkdown(
        valueOf('> quoted', base: 3),
        BlogMarkdownAction.quote,
      );
      expect(result.text, 'quoted');
    });

    test('bullets every line the selection touches', () {
      final result = applyBlogMarkdown(
        valueOf('one\ntwo\nthree', base: 0, extent: 13),
        BlogMarkdownAction.bulletList,
      );
      expect(result.text, '- one\n- two\n- three');
    });

    test('numbers lines in order and skips blank ones', () {
      final result = applyBlogMarkdown(
        valueOf('one\n\ntwo', base: 0, extent: 8),
        BlogMarkdownAction.numberedList,
      );
      expect(result.text, '1. one\n\n2. two');
    });

    test('replaces an existing prefix rather than stacking one', () {
      final result = applyBlogMarkdown(
        valueOf('- item', base: 3),
        BlogMarkdownAction.heading,
      );
      expect(result.text, '## item');
    });

    test('a heading of any depth toggles off', () {
      final result = applyBlogMarkdown(
        valueOf('#### deep', base: 6),
        BlogMarkdownAction.heading,
      );
      expect(result.text, 'deep');
    });
  });

  group('links', () {
    test('keeps the selection as the label and selects the placeholder', () {
      final result = applyBlogMarkdown(
        valueOf('see the docs', base: 8, extent: 12),
        BlogMarkdownAction.link,
      );
      expect(result.text, 'see the [docs](url)');
      expect(result.selection.textInside(result.text), 'url');
    });
  });

  test('an invalid selection appends at the end', () {
    final result = applyBlogMarkdown(
      const TextEditingValue(text: 'tail'),
      BlogMarkdownAction.bold,
    );
    expect(result.text, 'tail****');
  });

  testWidgets('toolbar reports the tapped action', (tester) async {
    final tapped = <BlogMarkdownAction>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlogMarkdownToolbar(onAction: tapped.add),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('blog-markdown-bold')));
    await tester.tap(find.byKey(const ValueKey('blog-markdown-quote')));
    await tester.pump();

    expect(tapped, [BlogMarkdownAction.bold, BlogMarkdownAction.quote]);
  });
}
