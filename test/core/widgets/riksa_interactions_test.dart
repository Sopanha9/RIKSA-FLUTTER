import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_components.dart';
import 'package:riksa_app/features/learning/presentation/widgets/learning_atoms.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

Widget host(Widget child, {bool reduced = false}) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en'), Locale('km')],
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets(
    'press reacts immediately, cancellation releases it without activation',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          RiksaTapFeedback(
            child: FilledButton(
              onPressed: () => taps++,
              child: const Text('Continue'),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(FilledButton)),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        .97,
      );
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      expect(taps, 0);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(taps, 1);
    },
  );

  testWidgets('scrolling releases the press and disabled buttons stay still', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        RiksaTapFeedback(
          child: FilledButton(onPressed: () {}, child: const Text('Continue')),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump();
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await gesture.cancel();
    await tester.pumpWidget(
      host(
        const RiksaTapFeedback(
          enabled: false,
          child: FilledButton(onPressed: null, child: Text('Disabled')),
        ),
      ),
    );
    final disabled = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await disabled.cancel();
    await tester.pumpAndSettle();
  });

  testWidgets('native keyboard activation still fires once', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        RiksaTapFeedback(
          child: FilledButton(
            autofocus: true,
            onPressed: () => taps++,
            child: const Text('Continue'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('step arrivals preserve the active text field', (tester) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    Widget field() => SizedBox(
      width: 280,
      child: TextField(controller: controller, focusNode: focus),
    );
    await tester.pumpWidget(
      host(RiksaContentReveal(identity: 'read', child: field())),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'My working');
    await tester.pumpWidget(
      host(RiksaContentReveal(identity: 'respond', child: field())),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(focus.hasFocus, isTrue);
    expect(controller.text, 'My working');
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('reduced motion presents content and success immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const RiksaContentReveal(
          identity: 'done',
          child: RiksaSuccessMark(label: 'Saved'),
        ),
        reduced: true,
      ),
    );
    expect(
      tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.byType(RiksaContentReveal),
              matching: find.byType(FadeTransition),
            ),
          )
          .opacity
          .value,
      1,
    );
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(
      host(
        RiksaTapFeedback(
          child: FilledButton(onPressed: () {}, child: const Text('Continue')),
        ),
        reduced: true,
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await gesture.cancel();
    await tester.pumpAndSettle();
  });

  testWidgets('busy action announces its status and cannot submit twice', (
    tester,
  ) async {
    var taps = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        LearningPrimaryButton(
          label: 'Save and finish',
          busy: true,
          onPressed: () => taps++,
        ),
        reduced: true,
      ),
    );
    expect(find.text('One moment…'), findsOneWidget);
    expect(find.bySemanticsLabel('One moment…'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(taps, 0);
    semantics.dispose();
  });

  testWidgets('empty states scroll at large text sizes', (tester) async {
    tester.view.physicalSize = const Size(360, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: IllustratedEmptyState(
              title: 'Keep a good idea for later',
              body: 'Save a lesson while you study. It will be waiting here.',
              actionLabel: 'Browse lessons',
              onAction: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Browse lessons'));
    expect(tester.takeException(), isNull);
  });
  testWidgets('navigation omits visual transitions under reduced motion', (
    tester,
  ) async {
    const destinationKey = ValueKey('destination-transition');
    Widget destination(bool reduced) => host(
      Builder(
        builder: (context) => KeyedSubtree(
          key: destinationKey,
          child: const RiksaPageTransitionsBuilder().buildTransitions<void>(
            MaterialPageRoute<void>(builder: (_) => const Text('Destination')),
            context,
            const AlwaysStoppedAnimation(.35),
            const AlwaysStoppedAnimation(0),
            const Text('Destination'),
          ),
        ),
      ),
      reduced: reduced,
    );
    await tester.pumpWidget(destination(false));
    expect(
      find.descendant(
        of: find.byKey(destinationKey),
        matching: find.byType(SlideTransition),
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(destination(true));
    expect(
      find.descendant(
        of: find.byKey(destinationKey),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );
    expect(find.text('Destination'), findsOneWidget);
  });
}
