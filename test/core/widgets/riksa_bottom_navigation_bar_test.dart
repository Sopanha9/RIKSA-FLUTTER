import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_bottom_navigation_bar.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

Widget _testApp({
  int currentIndex = 0,
  ValueChanged<int>? onSelected,
  Locale locale = const Locale('en'),
  bool dark = false,
  double textScale = 1,
  bool isExpanded = true,
}) {
  var expanded = isExpanded;
  return MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    locale: locale,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('km')],
    home: StatefulBuilder(
      builder: (context, setState) {
        return Scaffold(
          bottomNavigationBar: RiksaBottomNavigationBar(
            currentIndex: currentIndex,
            onSelected: onSelected ?? (_) {},
            isExpanded: expanded,
            onExpand: () => setState(() => expanded = true),
          ),
        );
      },
    ),
  );
}

void main() {
  testWidgets('floating pill labels every tab and keeps all tabs accessible', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_testApp(currentIndex: 1));
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('bottom-nav-surface'));
    // A translucent glass pill floats off the screen edges, with the round AI
    // Tutor button beside it.
    final surfaceColor =
        (tester.widget<Container>(surface).decoration! as ShapeDecoration)
            .color!;
    expect(surfaceColor.a, lessThan(1));
    expect(surfaceColor.r, Colors.white.r);
    expect(surfaceColor.g, Colors.white.g);
    expect(surfaceColor.b, Colors.white.b);
    expect(tester.getRect(surface).left, greaterThanOrEqualTo(16));
    expect(
      tester.getRect(find.byKey(const ValueKey('bottom-nav-item-2'))).left,
      greaterThan(tester.getRect(surface).right),
    );
    for (var index = 0; index < 5; index++) {
      expect(
        find.byKey(ValueKey('bottom-nav-label-$index')),
        index == RiksaBottomNavigationBar.aiTutorIndex
            ? findsNothing
            : findsOneWidget,
      );
      final semantics = tester.getSemantics(
        find.byKey(ValueKey('bottom-nav-destination-$index')),
      );
      expect(
        semantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(semantics.label, isNotEmpty);
    }
    handle.dispose();
  });

  testWidgets('every destination can be selected', (tester) async {
    int? selected;
    await tester.pumpWidget(_testApp(onSelected: (value) => selected = value));
    for (var index = 0; index < 5; index++) {
      await tester.tap(find.byKey(ValueKey('bottom-nav-item-$index')));
      expect(selected, index);
    }
  });

  testWidgets('collapsed navigation opens the full destination bar', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(isExpanded: false));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('collapsed-bottom-nav-fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('full-bottom-nav-bar')), findsOneWidget);
  });

  testWidgets('selection pill slides between non-AI destinations', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    final firstLeft = tester
        .getRect(find.byKey(const ValueKey('bottom-nav-selection-pill')))
        .left;

    await tester.pumpWidget(_testApp(currentIndex: 3));
    await tester.pump(const Duration(milliseconds: 160));
    final midAnimationLeft = tester
        .getRect(find.byKey(const ValueKey('bottom-nav-selection-pill')))
        .left;
    await tester.pumpAndSettle();
    final settledLeft = tester
        .getRect(find.byKey(const ValueKey('bottom-nav-selection-pill')))
        .left;

    expect(midAnimationLeft, greaterThan(firstLeft));
    expect(midAnimationLeft, lessThan(settledLeft));
    expect(
      settledLeft,
      closeTo(
        tester.getRect(find.byKey(const ValueKey('bottom-nav-item-3'))).left,
        1,
      ),
    );
  });

  for (final locale in const [Locale('en'), Locale('km')]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '${locale.languageCode} labels fit at $scale text scale on a narrow phone',
        (tester) async {
          tester.view.physicalSize = const Size(360, 780);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          for (var index = 0; index < 5; index++) {
            await tester.pumpWidget(
              _testApp(
                currentIndex: index,
                locale: locale,
                textScale: scale,
                dark: index.isOdd,
              ),
            );
            await tester.pumpAndSettle();
            if (index != RiksaBottomNavigationBar.aiTutorIndex) {
              final label = tester.renderObject<RenderParagraph>(
                find.byKey(ValueKey('bottom-nav-label-$index')),
              );
              expect(label.didExceedMaxLines, isFalse);
            }
            for (var tab = 0; tab < 5; tab++) {
              final rect = tester.getRect(
                find.byKey(ValueKey('bottom-nav-item-$tab')),
              );
              expect(rect.width, greaterThanOrEqualTo(48));
              expect(rect.height, greaterThanOrEqualTo(48));
            }
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }
}
