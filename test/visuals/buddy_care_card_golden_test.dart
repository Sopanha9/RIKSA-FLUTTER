import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/mascot/domain/buddy_care.dart';
import 'package:riksa_app/features/mascot/domain/mascot.dart';
import 'package:riksa_app/features/mascot/data/buddy_api.dart';
import 'package:riksa_app/features/mascot/presentation/widgets/buddy_care_card.dart';
import 'package:riksa_app/features/mascot/presentation/widgets/mascot_scene.dart';
import 'package:riksa_app/features/mascot/providers/buddy_care_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  final latin = FontLoader(RiksaTypography.latinFamily)
    ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'));
  final configuredRoot = Platform.environment['FLUTTER_ROOT'];
  final flutterRoot =
      configuredRoot ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(
      File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes().then(ByteData.sublistView),
    );
  await Future.wait([latin.load(), materialIcons.load()]);
}

class _FixedBuddyCareNotifier extends BuddyCareNotifier {
  _FixedBuddyCareNotifier(this.value);

  final BuddyCareState value;

  @override
  BuddyCareState build() => value;
}

BuddyCareState _stateFor(int energy) {
  final now = DateTime.now();
  final care = BuddyCare(
    energy: energy,
    bond: 0,
    updatedAt: now,
    careDay: phnomPenhCareDay(now),
    dailyCounts: const {BuddyCareSource.lesson: 1},
  );
  return BuddyCareState(
    care: care,
    species: MascotSpecies.crocodile,
    name: 'Croco',
    today: const [
      BuddyTodayAction(key: 'LESSON', done: true, count: 1, cap: null),
      BuddyTodayAction(key: 'BLOG_READ', done: false, count: 0, cap: 2),
      BuddyTodayAction(key: 'POST', done: false, count: 0, cap: 1),
    ],
  );
}

Widget _app({required int energy, required ThemeData theme, Locale? locale}) =>
    ProviderScope(
      overrides: [
        buddyCareProvider.overrideWith(
          () => _FixedBuddyCareNotifier(_stateFor(energy)),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
        home: Scaffold(
          body: SafeArea(
            child: Center(child: SizedBox(width: 328, child: BuddyCareCard())),
          ),
        ),
      ),
    );

Future<void> _precacheImages(WidgetTester tester) async {
  final context = tester.element(find.byType(BuddyCareCard));
  final brightness = Theme.of(context).brightness;
  await tester.runAsync(() async {
    await precacheImage(
      AssetImage(MascotScenes.asset(MascotSpecies.crocodile, brightness)),
      context,
    );
    for (final mood in [MascotMood.idle, MascotMood.happy, MascotMood.sleep]) {
      for (final frame in MascotSprites.frames(MascotSpecies.crocodile, mood)) {
        await precacheImage(AssetImage(frame), context);
      }
    }
    for (final face in [
      MascotFace.happy,
      MascotFace.neutral,
      MascotFace.sleepy,
    ]) {
      for (final frame in MascotFaceSprites.frames(
        MascotSpecies.crocodile,
        face,
      )) {
        await precacheImage(AssetImage(frame), context);
      }
    }
  });
  await tester.pump();
}

void main() {
  setUpAll(_loadFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final dark in [false, true]) {
    for (final energy in [90, 50, 20, 0]) {
      testWidgets('energy $energy ${dark ? 'dark' : 'light'}', (tester) async {
        tester.view.physicalSize = const Size(360, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _app(energy: energy, theme: dark ? AppTheme.dark : AppTheme.light),
        );
        await _precacheImages(tester);
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byKey(const ValueKey('buddy-care-card'))).height,
          lessThanOrEqualTo(180),
        );
        await expectLater(
          find.byKey(const ValueKey('buddy-care-card')),
          matchesGoldenFile(
            'goldens/buddy_care_${energy}_${dark ? 'dark' : 'light'}.png',
          ),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 3));
      });
    }
  }

  testWidgets('fits at 360 dp with a long Khmer buddy name', (tester) async {
    tester.view.physicalSize = const Size(360, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = _stateFor(0);
    final longKhmerName = 'មិត្តសិក្សាដ៏អស្ចារ្យរបស់ខ្ញុំ';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buddyCareProvider.overrideWith(
            () => _FixedBuddyCareNotifier(
              BuddyCareState(
                care: state.care,
                species: state.species,
                name: longKhmerName,
                today: state.today,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('km'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('km')],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const Scaffold(
            body: SafeArea(
              child: Center(
                child: SizedBox(width: 328, child: BuddyCareCard()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('buddy-care-card'))).height,
      lessThanOrEqualTo(180),
    );
  });
}
