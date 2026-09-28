import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_bottom_navigation_bar.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

/// The shell's layout: a Scaffold that extends its body under the floating
/// bar, holding a tab screen whose own Scaffold has a lifted action button.
Widget _shell(ValueNotifier<bool> expanded) => MaterialApp(
  theme: AppTheme.dark,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en'), Locale('km')],
  home: ValueListenableBuilder<bool>(
    valueListenable: expanded,
    builder: (context, isExpanded, _) => Scaffold(
      extendBody: true,
      body: BottomNavigationExpansion(
        expanded: expanded,
        child: Builder(
          builder: (context) => Scaffold(
            body: const SizedBox.expand(),
            floatingActionButton: AboveBottomNavigation(
              context: context,
              child: FloatingActionButton(
                key: const ValueKey('tab-fab'),
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: RiksaBottomNavigationBar(
        currentIndex: 0,
        onSelected: (_) {},
        isExpanded: isExpanded,
        onExpand: () => expanded.value = true,
      ),
    ),
  ),
);

void main() {
  testWidgets('the tab button sits above the open bar and takes the AI '
      "button's place when the bar collapses", (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final expanded = ValueNotifier(true);
    addTearDown(expanded.dispose);

    await tester.pumpWidget(_shell(expanded));
    await tester.pumpAndSettle();

    final fab = find.byKey(const ValueKey('tab-fab'));
    final openBar = tester.getRect(
      find.byKey(const ValueKey('full-bottom-nav-bar')),
    );
    final aiButton = tester.getRect(find.bySemanticsLabel(RegExp('AI')).last);
    expect(tester.getRect(fab).bottom, lessThanOrEqualTo(openBar.top));

    // Scrolling down collapses the bar: the button drops into the AI slot.
    expanded.value = false;
    await tester.pumpAndSettle();
    final dropped = tester.getRect(fab);
    expect(dropped.center.dy, closeTo(aiButton.center.dy, 4));
    expect(dropped.right, closeTo(aiButton.right, 4));
    final collapsed = tester.getRect(
      find.byKey(const ValueKey('collapsed-bottom-nav-fab')),
    );
    expect(dropped.overlaps(collapsed), isFalse);

    // Scrolling back up opens the bar and lifts the button again.
    expanded.value = true;
    await tester.pumpAndSettle();
    expect(tester.getRect(fab).bottom, lessThanOrEqualTo(openBar.top));
  });

  testWidgets('outside a shell the lift stays as before', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: 80)),
          child: Builder(
            builder: (context) => Scaffold(
              floatingActionButton: AboveBottomNavigation(
                context: context,
                child: const SizedBox(key: ValueKey('child'), width: 10),
              ),
            ),
          ),
        ),
      ),
    );
    final padding = tester.widget<AnimatedPadding>(
      find.ancestor(
        of: find.byKey(const ValueKey('child')),
        matching: find.byType(AnimatedPadding),
      ),
    );
    expect(padding.padding, const EdgeInsets.only(bottom: 80));
  });
}
