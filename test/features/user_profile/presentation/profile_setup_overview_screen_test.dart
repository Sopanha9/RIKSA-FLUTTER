import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/userProfile/presentation/profile_setup_overview_screen.dart';

void main() {
  testWidgets('renders the Figma profile setup overview and invokes its CTA', (
    tester,
  ) async {
    var started = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileSetupOverviewScreen(onSetUpProfile: () => started = true),
      ),
    );

    expect(find.text('Set up your profile'), findsOneWidget);
    expect(find.text('Avatar'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Bio'), findsOneWidget);

    final startButton = find.byKey(const Key('profile_setup_start'));
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);

    expect(started, isTrue);
  });
}
