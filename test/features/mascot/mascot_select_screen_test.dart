import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/mascot/domain/mascot.dart';
import 'package:riksa_app/features/mascot/presentation/mascot_select_screen.dart';
import 'package:riksa_app/features/mascot/presentation/widgets/mascot_face.dart';
import 'package:riksa_app/features/mascot/presentation/widgets/mascot_scene.dart';
import 'package:riksa_app/features/mascot/presentation/widgets/mascot_view.dart';
import 'package:riksa_app/features/mascot/providers/mascot_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app({bool reduceMotion = false}) {
  final router = GoRouter(
    initialLocation: '/mascot-select',
    routes: [
      GoRoute(
        path: '/mascot-select',
        builder: (context, state) => const MascotSelectScreen(),
      ),
      GoRoute(
        path: '/language-select',
        builder: (context, state) => const Text('language page'),
      ),
    ],
  );
  return ProviderScope(
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('km')],
    ),
  );
}

String _stageName(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('mascot_stage_name'))).data!;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('offers both buddies and starts on the crocodile', (
    tester,
  ) async {
    await phone(tester);
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('mascot_crocodile')), findsOneWidget);
    expect(find.byKey(const Key('mascot_capybara')), findsOneWidget);
    expect(_stageName(tester), 'Croco');
  });

  testWidgets('the default name follows the species until the learner types', (
    tester,
  ) async {
    await phone(tester);
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('mascot_capybara')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(_stageName(tester), 'Capy');

    await tester.enterText(find.byKey(const Key('mascot_name')), 'Mochi');
    await tester.pump();
    await tester.tap(find.byKey(const Key('mascot_crocodile')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(_stageName(tester), 'Mochi');
  });

  testWidgets('continue saves the buddy and moves on to language', (
    tester,
  ) async {
    await phone(tester);
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('mascot_capybara')));
    await tester.enterText(find.byKey(const Key('mascot_name')), '  Mochi ');
    await tester.tap(find.byKey(const Key('mascot_continue')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('language page'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('riksa_mascot_species'), 'capybara');
    expect(preferences.getString('riksa_mascot_name'), 'Mochi');
  });

  testWidgets('reduced motion shows still frames and settles', (tester) async {
    await phone(tester);
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.pumpAndSettle();

    expect(find.byType(MascotView), findsNWidgets(3));
    expect(tester.hasRunningAnimations, isFalse);
  });

  test('a saved buddy is restored', () async {
    SharedPreferences.setMockInitialValues({
      'riksa_mascot_species': 'capybara',
      'riksa_mascot_name': 'Mochi',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(mascotProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final profile = container.read(mascotProvider).profile!;
    expect(profile.species, MascotSpecies.capybara);
    expect(profile.name, 'Mochi');
  });

  testWidgets('picker uses a saved buddy after asynchronous restoration', (
    tester,
  ) async {
    await phone(tester);
    SharedPreferences.setMockInitialValues({
      'riksa_mascot_species': 'capybara',
      'riksa_mascot_name': 'Mochi',
    });
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 100));

    expect(_stageName(tester), 'Mochi');
    final name = tester.widget<TextField>(find.byKey(const Key('mascot_name')));
    expect(name.controller!.text, 'Mochi');
  });

  test('a blank name falls back to the species default', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container
        .read(mascotProvider.notifier)
        .choose(MascotSpecies.crocodile, '   ');

    expect(container.read(mascotProvider).profile!.name, 'Croco');
  });

  testWidgets('a reaction plays and then returns to the resting mood', (
    tester,
  ) async {
    final controller = MascotController();
    addTearDown(controller.dispose);

    controller.react(
      MascotMood.love,
      duration: const Duration(milliseconds: 500),
    );
    expect(controller.current, MascotMood.love);
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.current, MascotMood.idle);
  });

  test('every mood of every species has its frames on disk', () {
    for (final species in MascotSpecies.values) {
      for (final frame in MascotSprites.allFrames(species)) {
        expect(File(frame).existsSync(), isTrue, reason: frame);
      }
    }
  });

  test('every face of every species has its frames on disk', () {
    for (final species in MascotSpecies.values) {
      for (final face in MascotFace.values) {
        for (final frame in MascotFaceSprites.frames(species, face)) {
          expect(File(frame).existsSync(), isTrue, reason: frame);
        }
      }
    }
  });

  test('party scene assets and reward icons exist on disk', () {
    for (final species in MascotSpecies.values) {
      for (final brightness in Brightness.values) {
        final path = MascotScenes.asset(species, brightness, party: true);
        final time = brightness == Brightness.dark ? 'night' : 'day';
        final place = switch (species) {
          MascotSpecies.crocodile => 'pond',
          MascotSpecies.capybara => 'park',
        };
        expect(path, 'assets/images/mascots/scenes/${place}_party_$time.webp');
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }

    const rewardIcons = ['streak', 'xp', 'squad', 'trophy', 'calendar', 'gift'];
    for (final icon in rewardIcons) {
      final path = 'assets/images/rewards/$icon.png';
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  testWidgets('a face with loops plays and then comes to rest', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MascotFaceView(
          species: MascotSpecies.capybara,
          face: MascotFace.laughing,
          loops: 2,
        ),
      ),
    );
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the avatar shows the chosen buddy', (tester) async {
    SharedPreferences.setMockInitialValues({
      'riksa_mascot_species': 'capybara',
    });
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MascotFaceAvatar(face: MascotFace.wink, loops: 1),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    final view = tester.widget<MascotFaceView>(find.byType(MascotFaceView));
    expect(view.species, MascotSpecies.capybara);
    expect(view.face, MascotFace.wink);
    await tester.pump(const Duration(seconds: 4));
  });
}
