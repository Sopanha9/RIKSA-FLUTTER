import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/mascot/data/buddy_api.dart';
import 'package:riksa_app/features/mascot/domain/mascot.dart';
import 'package:riksa_app/features/mascot/presentation/widgets/buddy_look.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const slots = <String, Map<BuddyItemSlot, String>>{
    'none': {},
    'hat': {BuddyItemSlot.hat: 'hat_straw'},
    'glasses': {BuddyItemSlot.eyewear: 'glasses_round'},
    'both': {
      BuddyItemSlot.hat: 'hat_straw',
      BuddyItemSlot.eyewear: 'glasses_round',
    },
  };

  for (final species in MascotSpecies.values) {
    for (final entry in slots.entries) {
      for (final dark in [false, true]) {
        final themeName = dark ? 'dark' : 'light';
        testWidgets('BuddyLook ${species.name} ${entry.key} $themeName', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(180, 180);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final theme = dark ? AppTheme.dark : AppTheme.light;
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('km')],
              home: Scaffold(
                body: Center(
                  child: BuddyLook(
                    species: species,
                    face: MascotFace.neutral,
                    equipped: entry.value,
                    size: 120,
                    loops: 0,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final itemCount = entry.value.length;
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is CustomPaint &&
                  widget.painter is BuddyItemPlaceholderPainter,
            ),
            findsNWidgets(itemCount),
          );
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/buddy_look_${species.name}_${entry.key}_$themeName.png',
            ),
          );
        });
      }
    }
  }
}
