import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_rank_badge.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';
import 'package:riksa_app/features/userProfile/presentation/widgets/profile_ui.dart';

void main() {
  testWidgets('rank artwork loads at small sizes on light and dark surfaces', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('rank-gallery'),
            child: Column(
              children: [
                for (final theme in [AppTheme.light, AppTheme.dark])
                  Theme(
                    data: theme,
                    child: ColoredBox(
                      color: theme.scaffoldBackgroundColor,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            for (final size in [32.0, 52.0])
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  for (final tier in profileTierLadder)
                                    RiksaRankBadge(tier: tier, size: size),
                                ],
                              ),
                            const SizedBox(height: 16),
                            const ProfileTierRail(
                              tiers: profileTierLadder,
                              currentIndex: 2,
                              startLabel: '',
                              endLabel: '',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    // Await the real bundled PNG decodes before comparing their pixels.
    final context = tester.element(find.byKey(const ValueKey('rank-gallery')));
    await tester.runAsync(() async {
      for (final tier in profileTierLadder) {
        await precacheImage(
          AssetImage('assets/images/ranks/${tier.toLowerCase()}.png'),
          context,
          onError: (error, stack) => fail('Badge failed to load: $error'),
        );
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('rank-gallery')),
      matchesGoldenFile('goldens/rank_badges.png'),
    );
  });

  testWidgets('unknown tiers never display an earned rank', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Row(
          children: [
            RiksaRankBadge(tier: null),
            RiksaRankBadge(tier: 'STARTER'),
            RiksaRankBadge(tier: 'future-tier'),
          ],
        ),
      ),
    );
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.shield_outlined), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
