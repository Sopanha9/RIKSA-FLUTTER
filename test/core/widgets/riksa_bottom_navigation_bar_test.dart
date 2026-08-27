import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_bottom_navigation_bar.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

Widget _testApp(
  ThemeData theme, {
  bool collapsed = false,
  int currentIndex = 0,
}) {
  return MaterialApp(
    theme: theme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('km')],
    home: Scaffold(
      bottomNavigationBar: RiksaBottomNavigationBar(
        currentIndex: currentIndex,
        collapsed: collapsed,
        onSelected: (_) {},
        onCollapsedTap: () {},
      ),
    ),
  );
}

BoxDecoration _decoration(WidgetTester tester, String key) {
  return tester.widget<AnimatedContainer>(find.byKey(ValueKey(key))).decoration!
      as BoxDecoration;
}

BoxDecoration _destinationDecoration(WidgetTester tester, int index) {
  return tester
          .widget<AnimatedContainer>(
            find.byKey(ValueKey('bottom-nav-destination-$index')),
          )
          .decoration!
      as BoxDecoration;
}

void main() {
  testWidgets('light navigation uses the editorial palette', (tester) async {
    await tester.pumpWidget(_testApp(AppTheme.light));

    expect(
      _decoration(tester, 'bottom-nav-surface').color,
      AppColors.editorialNeutralSurface,
    );
    expect(
      _destinationDecoration(tester, 0).color,
      AppColors.editorialPinkSoft,
    );
    expect(find.byKey(const ValueKey('bottom-nav-label-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav-label-1')), findsNothing);

    final activeIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('bottom-nav-destination-0')),
        matching: find.byType(Icon),
      ),
    );
    expect(activeIcon.color, AppColors.editorialAubergine);
  });

  testWidgets('dark navigation uses the dark editorial palette', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(AppTheme.dark));

    expect(
      _decoration(tester, 'bottom-nav-surface').color,
      AppColors.editorialAubergineRaised,
    );
    expect(_destinationDecoration(tester, 0).color, AppColors.editorialPink);
  });

  testWidgets('collapsed navigation is one centered button without a halo', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(AppTheme.light, collapsed: true));

    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('bottom-nav-expanded-content')),
          )
          .opacity,
      0,
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('bottom-nav-collapsed-content')),
          )
          .opacity,
      1,
    );
    expect(
      find.byKey(const ValueKey('bottom-nav-collapsed-item')),
      findsOneWidget,
    );

    final activeCircle = tester.widget<Positioned>(
      find.byKey(const ValueKey('bottom-nav-active-circle')),
    );
    expect(activeCircle.left, 3);
    expect(activeCircle.bottom, 0);
    expect(activeCircle.width, 52);
    expect(activeCircle.height, 52);
  });

  testWidgets('selected pill accommodates a longer localized label', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp(AppTheme.light, currentIndex: 3));

    final label = tester.renderObject<RenderParagraph>(
      find.byKey(const ValueKey('bottom-nav-label-3')),
    );
    expect(label.didExceedMaxLines, isFalse);
  });

  testWidgets('collapse visibly animates before reaching compact state', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(AppTheme.light));
    final morph = find.byKey(const ValueKey('bottom-nav-morph'));
    final expandedWidth = tester.getSize(morph).width;

    await tester.pumpWidget(_testApp(AppTheme.light, collapsed: true));
    await tester.pump(const Duration(milliseconds: 190));

    final animatedWidth = tester.getSize(morph).width;
    expect(animatedWidth, greaterThan(58));
    expect(animatedWidth, lessThan(expandedWidth));
    final expandedOpacity = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('bottom-nav-expanded-content')),
    );
    final collapsedOpacity = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('bottom-nav-collapsed-content')),
    );
    expect(expandedOpacity.opacity, 0);
    expect(collapsedOpacity.opacity, 1);

    await tester.pumpAndSettle();
    expect(tester.getSize(morph).width, 58);
  });
}
