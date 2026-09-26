import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:riksa_app/features/userProfile/presentation/profile_setup_overview_screen.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('renders the Figma profile setup overview and invokes its CTA', (
    tester,
  ) async {
    var started = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
        home: ProfileSetupOverviewScreen(onSetUpProfile: () => started = true),
      ),
    );

    expect(find.text('Set up your profile'), findsOneWidget);
    expect(find.text('Add a photo'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);
    expect(find.text('A short bio'), findsOneWidget);
    expect(find.text('Your province'), findsOneWidget);

    final startButton = find.byKey(const Key('profile_setup_start'));
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);

    expect(started, isTrue);
  });
}
