import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/auth/presentation/widgets/onboarding_art.dart';

Widget _app({required Widget child, bool disableAnimations = false}) =>
    MaterialApp(
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: appChild!,
      ),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('falls back to the matching SVG when Rive is not bundled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        child: const OnboardingArt(
          scene: OnboardingScene.achievement,
          active: true,
          semanticLabel: 'Achievement illustration',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('assets/images/onboarding/achievement.svg')),
      findsOneWidget,
    );
  });

  testWidgets('uses the deterministic SVG path when motion is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        disableAnimations: true,
        child: const OnboardingArt(
          scene: OnboardingScene.community,
          active: true,
          semanticLabel: 'Community illustration',
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('assets/images/onboarding/community.svg')),
      findsOneWidget,
    );
  });

  testWidgets('exposes one image semantic for the artwork', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _app(
        disableAnimations: true,
        child: const OnboardingArt(
          scene: OnboardingScene.learning,
          active: true,
          semanticLabel: 'Learning illustration',
        ),
      ),
    );

    final node = tester.getSemantics(
      find.byKey(const ValueKey('onboarding-art-learning')),
    );
    expect(node.label, 'Learning illustration');
    expect(node.flagsCollection.isImage, isTrue);
    semantics.dispose();
  });
}
