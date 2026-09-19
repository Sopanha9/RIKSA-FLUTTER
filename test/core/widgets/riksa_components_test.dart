import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_components.dart';

void main() {
  testWidgets('shared controls remain usable on a narrow scaled layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const _ComponentHarness());
    await tester.pump();

    await tester.enterText(find.byType(RiksaSearchField), 'algebra');
    await tester.tap(find.text('Mathematics'));
    await tester.tap(find.text('Open card'));
    await tester.tap(find.text('Try again'));
    await tester.pump();

    expect(find.text('algebra'), findsOneWidget);
    expect(tester.widget<FilterChip>(find.byType(FilterChip)).selected, isTrue);
    expect(find.text('Card opened'), findsOneWidget);
    expect(find.text('Retried'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ComponentHarness extends StatefulWidget {
  const _ComponentHarness();

  @override
  State<_ComponentHarness> createState() => _ComponentHarnessState();
}

class _ComponentHarnessState extends State<_ComponentHarness> {
  bool selected = false;
  bool opened = false;
  bool retried = false;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: ListView(
          padding: const EdgeInsets.all(RiksaSpacing.md),
          children: [
            const RiksaSearchField(hintText: 'Search lessons'),
            const SizedBox(height: RiksaSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: RiksaChoicePill(
                label: 'Mathematics',
                selected: selected,
                onSelected: (value) => setState(() => selected = value),
              ),
            ),
            const SizedBox(height: RiksaSpacing.sm),
            RiksaPastelCard(
              tone: RiksaPastelTone.blush,
              onTap: () => setState(() => opened = true),
              child: Text(opened ? 'Card opened' : 'Open card'),
            ),
            const SizedBox(height: RiksaSpacing.sm),
            RiksaStateView(
              title: retried ? 'Retried' : 'Nothing here yet',
              body: 'A compact state that remains readable.',
              actionLabel: 'Try again',
              onAction: () => setState(() => retried = true),
            ),
          ],
        ),
      ),
    ),
  );
}
