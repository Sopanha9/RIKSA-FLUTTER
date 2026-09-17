import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/widgets/unsaved_changes_guard.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

/// Leaving a form should never throw away writing by accident.
void main() {
  testWidgets('a clean form closes straight away', (tester) async {
    await _pumpForm(tester, dirty: false);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('discard-changes-dialog')), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('a dirty form asks, and Keep editing stays put', (tester) async {
    await _pumpForm(tester, dirty: true);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('discard-changes-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('discard-changes-keep')));
    await tester.pumpAndSettle();

    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('system back on a dirty form can discard', (tester) async {
    await _pumpForm(tester, dirty: true);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.maybePop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('discard-changes-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('a submitting form cannot be left', (tester) async {
    await _pumpForm(tester, dirty: true, busy: true);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('discard-changes-dialog')), findsNothing);
    expect(find.text('Close'), findsOneWidget);
  });
}

Future<void> _pumpForm(
  WidgetTester tester, {
  required bool dirty,
  bool busy = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('km')],
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              const Text('Home'),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => UnsavedChangesGuard(
                      dirty: dirty,
                      busy: busy,
                      child: Scaffold(
                        body: Builder(
                          builder: (context) => TextButton(
                            onPressed: () => Navigator.maybePop(context),
                            child: const Text('Close'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}
