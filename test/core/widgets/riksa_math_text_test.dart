import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_math_text.dart';

void main() {
  testWidgets('renders plain text directly without math widgets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: RiksaMathText(text: 'Standard Newton Unit'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Standard Newton Unit'), findsOneWidget);
    expect(find.byType(Math), findsNothing);
  });

  testWidgets('renders Khmer text with proper typography', (tester) async {
    const khmerText = 'កម្លាំង និង សន្ទុះ';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: RiksaMathText(text: khmerText)),
      ),
    );
    await tester.pump();

    expect(find.text(khmerText), findsOneWidget);
  });

  testWidgets('renders inline formula via Math.tex when \$ delimiters are present', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: RiksaMathText(text: r'Force is $F = m \cdot a$'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Math), findsOneWidget);
  });

  testWidgets('renders display formula via Math.tex with display style', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: RiksaMathText(text: r'$$\frac{-b \pm \sqrt{\Delta}}{2a}$$'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Math), findsOneWidget);
    final mathWidget = tester.widget<Math>(find.byType(Math));
    expect(mathWidget.mathStyle, equals(MathStyle.display));
  });

  testWidgets('renders math embedded within MarkdownBody', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MarkdownBody(
            data: r'Calculate net force: $F = 2 \times 5 = 10\text{ N}$',
            inlineSyntaxes: RiksaMathText.markdownSyntaxes,
            builders: RiksaMathText.markdownBuilders,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Math), findsOneWidget);
  });

  testWidgets('malformed LaTeX falls back safely without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: RiksaMathText(text: r'Malformed $\frac{unclosed$ formula'),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
