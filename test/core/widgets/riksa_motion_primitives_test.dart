import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_components.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(body: Center(child: child)),
  ),
);

double _opacityOf(WidgetTester tester) =>
    tester.widget<Opacity>(find.byType(Opacity)).opacity;

void main() {
  group('RiksaCountUp', () {
    testWidgets('counts up from zero and lands on the value', (tester) async {
      await tester.pumpWidget(
        _host(RiksaCountUp(value: 4120, format: (value) => '$value XP')),
      );

      // First frame is the start of the count, not the answer.
      expect(find.text('0 XP'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      final midway = tester.widget<Text>(find.byType(Text)).data!;
      expect(midway, isNot('0 XP'));
      expect(midway, isNot('4120 XP'));

      await tester.pumpAndSettle();
      expect(find.text('4120 XP'), findsOneWidget);
    });

    testWidgets('announces only the final value to assistive tech', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(RiksaCountUp(value: 12, format: (value) => '#$value')),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Mid-count the label is already the destination, so a screen reader is
      // never read a number the learner does not have.
      expect(find.bySemanticsLabel('#12'), findsOneWidget);
      await tester.pumpAndSettle();
      handle.dispose();
    });

    testWidgets('paints the value outright under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          RiksaCountUp(value: 4120, format: (value) => '$value XP'),
          disableAnimations: true,
        ),
      );

      expect(find.text('4120 XP'), findsOneWidget);
      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    });
  });

  group('RiksaEntrance', () {
    testWidgets('rises into place and then stops wrapping its child', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const RiksaEntrance(index: 0, child: Text('row'))),
      );

      expect(_opacityOf(tester), lessThan(1));

      await tester.pumpAndSettle();
      // The landed row carries no Opacity layer, so a long list does not pay
      // for a saveLayer per row forever.
      expect(find.byType(Opacity), findsNothing);
      expect(find.text('row'), findsOneWidget);
    });

    testWidgets('later rows start after earlier ones', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RiksaEntrance(index: 0, child: Text('first')),
              RiksaEntrance(index: 6, child: Text('sixth')),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 120));

      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((widget) => widget.opacity)
          .toList();
      // The sixth row has not begun while the first is nearly landed. That gap
      // is the stagger; without it both would sit at the same opacity.
      expect(opacities, hasLength(2));
      expect(opacities.first, greaterThan(0.5));
      expect(opacities.last, 0);

      await tester.pumpAndSettle();
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('lands immediately under reduced motion', (tester) async {
      await tester.pumpWidget(
        _host(
          const RiksaEntrance(index: 5, child: Text('row')),
          disableAnimations: true,
        ),
      );

      expect(find.byType(Opacity), findsNothing);
      expect(find.text('row'), findsOneWidget);
    });
  });
}
