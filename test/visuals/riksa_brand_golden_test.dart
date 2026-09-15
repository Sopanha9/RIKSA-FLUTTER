import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_brand.dart';

import 'golden_fonts.dart';

void main() {
  setUpAll(loadRiksaGoldenFonts);

  for (final dark in [false, true]) {
    testWidgets('brand kit ${dark ? 'dark' : 'light'}', (tester) async {
      tester.view.physicalSize = const Size(720, 460);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      RiksaWordmark(fontSize: 64),
                      SizedBox(width: 40),
                      RiksaWordmark(fontSize: 32),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (final pose in RiksaMascotPose.values) ...[
                        RiksaMascot(size: 120, pose: pose),
                        const SizedBox(width: 24),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 18,
                    children: [
                      for (final kind in RiksaDoodleKind.values)
                        RiksaDoodle(kind, size: 40),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton(onPressed: () {}, child: const Text('Log in')),
                      const SizedBox(width: 12),
                      const RiksaIconTile(
                        icon: Icons.science_outlined,
                        background: AppColors.tileGreen,
                      ),
                      const SizedBox(width: 12),
                      const RiksaIconTile(
                        icon: Icons.functions_rounded,
                        background: AppColors.tilePink,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/riksa_brand_${dark ? 'dark' : 'light'}.png'),
      );
    });
  }
}
