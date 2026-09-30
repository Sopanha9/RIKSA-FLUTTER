// Taps every button on every screen of the real app and reports what each
// tap did. Run it with:
//
//   flutter test test/crawler/tap_everything_test.dart
//
// The report is printed and written to build/crawler_report.md. It lists
// taps that crashed or logged an error, taps that did nothing visible, and
// screens that ended up on an error state. The fake server lives in
// crawler_fixtures.dart; add an endpoint there when a new screen needs one.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'crawler_fixtures.dart';
import 'crawler_harness.dart';

final _screens = <String>[
  '/learn',
  '/learn/roadmap/$kMathId',
  '/learn/$kLesson2Id',
  '/learn/saved',
  '/home',
  '/community',
  '/communities',
  '/community/posts/$kPostId',
  '/blog',
  '/blog/my-posts',
  '/blog/$kBlogId',
  '/ai',
  '/ai/chat/$kChatId',
  '/leaderboard',
  '/notifications',
  '/profile',
  '/profile/settings',
  '/profile/$kOtherUserId',
  '/market',
  '/market/wardrobe',
  '/progress',
];

/// Taps that change the session or leave the app; they're reported but the
/// crawler restarts the app afterwards.
const _maxTapsPerScreen = 60;

/// Screens are crawled one screenful at a time, this many screenfuls deep.
const _pages = 3;

String _nameOnly(String label) => label.replaceAll(RegExp(r' @\d+,\d+$'), '');

/// Scrolls the main list down by most of a screen. False when nothing moved.
Future<bool> _scrollDown(WidgetTester tester) async {
  final scrollables = find.byType(Scrollable).hitTestable().evaluate().where((
    e,
  ) {
    final state = (e as StatefulElement).state as ScrollableState;
    return state.widget.axisDirection == AxisDirection.down &&
        state.position.maxScrollExtent > 0;
  }).toList();
  if (scrollables.isEmpty) return false;
  final state = (scrollables.first as StatefulElement).state as ScrollableState;
  final before = state.position.pixels;
  if (before >= state.position.maxScrollExtent) return false;
  state.position.jumpTo(
    (before + 560).clamp(0, state.position.maxScrollExtent).toDouble(),
  );
  await CrawlerApp.settle(tester, max: const Duration(milliseconds: 600));
  return state.position.pixels > before;
}

enum _Outcome {
  navigated,
  overlay,
  snackbar,
  request,
  link,
  changed,
  nothing,
  error,
}

class _Tap {
  _Tap(this.screen, this.label, this.outcome, [this.detail = '']);
  final String screen;
  final String label;
  final _Outcome outcome;
  final String detail;
}

class _Target {
  _Target(this.rect, this.label);
  final Rect rect;
  final String label;
}

void main() {
  testWidgets(
    'tap every button on every screen',
    (tester) async {
      final results = <_Tap>[];
      final screenProblems = <String, String>{};
      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previousOnError);

      // url_launcher and the other plugins have no platform side in tests.
      final platformCalls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          // Taps vibrate and click; only a real hand-off to the system counts.
          if (!call.method.startsWith('HapticFeedback') &&
              !call.method.startsWith('SystemSound') &&
              !call.method.startsWith('Clipboard') &&
              !call.method.startsWith('SystemChrome')) {
            platformCalls.add(call.method);
          }
          return null;
        },
      );

      // url_launcher has no platform side in tests either; record the launch.
      const urlLauncher = MethodChannel('plugins.flutter.io/url_launcher');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        urlLauncher,
        (call) async {
          platformCalls.add('url_launcher.${call.method}');
          return true;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          urlLauncher,
          null,
        ),
      );

      var server = crawlerServer();
      var app = await CrawlerApp.mount(tester, server);

      Future<void> open(String route) async {
        _closeOverlays(tester);
        app.router.go(route);
        await CrawlerApp.settle(tester);
      }

      for (final screen in _screens) {
        await open(screen);
        errors.clear();
        tester.takeException();
        if (_onErrorState(tester)) {
          screenProblems[screen] = 'shows an error state after loading';
        }
        // Gather targets page by page, remembering which scroll page each is on.
        final plan = <(int, String)>[];
        final seenLabels = <String>{};
        for (var page = 0; page < _pages; page++) {
          if (page > 0 && !await _scrollDown(tester)) break;
          for (final t in _targets(tester)) {
            final name = _nameOnly(t.label);
            if (seenLabels.add('$name#${page == 0 ? t.label : name}')) {
              plan.add((page, t.label));
            }
          }
        }
        for (final (page, wanted) in plan.take(_maxTapsPerScreen)) {
          await open(screen);
          errors.clear();
          tester.takeException();
          var scrolled = true;
          for (var p = 0; p < page && scrolled; p++) {
            scrolled = await _scrollDown(tester);
          }
          final current = _targets(tester);
          final target =
              current.where((t) => t.label == wanted).firstOrNull ??
              current
                  .where((t) => _nameOnly(t.label) == _nameOnly(wanted))
                  .firstOrNull;
          if (target == null) continue;

          final beforeLocation = app.router.state.uri.toString();
          final beforeText = _fingerprint(tester);
          final beforeRequests = server.requests.length;
          final beforeLinks = app.openedLinks.length;
          final beforeCalls = platformCalls.length;
          final beforeOverlays = _overlayCount(tester);

          await tester.tapAt(target.rect.center);
          await CrawlerApp.settle(
            tester,
            max: const Duration(milliseconds: 1500),
          );

          final thrown = tester.takeException();
          final logged = errors.where((e) => !_ignorable(e)).toList();
          final newRequests = server.requests
              .skip(beforeRequests)
              .where((r) => !r.startsWith('GET'))
              .toList();
          final afterLocation = app.router.state.uri.toString();
          _Outcome outcome;
          var detail = '';
          if (thrown != null || logged.isNotEmpty) {
            outcome = _Outcome.error;
            detail = (thrown ?? logged.first.exceptionAsString())
                .toString()
                .split('\n')
                .first;
          } else if (afterLocation != beforeLocation) {
            outcome = _Outcome.navigated;
            detail = afterLocation;
          } else if (_overlayCount(tester) > beforeOverlays) {
            outcome = _Outcome.overlay;
          } else if (find.byType(SnackBar).evaluate().isNotEmpty) {
            outcome = _Outcome.snackbar;
            detail = _snackText(tester);
          } else if (newRequests.isNotEmpty) {
            outcome = _Outcome.request;
            detail = newRequests.toSet().join(', ');
          } else if (app.openedLinks.length > beforeLinks ||
              platformCalls.length > beforeCalls) {
            outcome = _Outcome.link;
          } else if (_fingerprint(tester) != beforeText) {
            outcome = _Outcome.changed;
          } else {
            outcome = _Outcome.nothing;
          }
          results.add(_Tap(screen, target.label, outcome, detail));

          // Signing out or a broken session sends the app to sign-in; start over.
          if (afterLocation.startsWith('/auth') ||
              afterLocation.startsWith('/splash')) {
            _closeOverlays(tester);
            await tester.pumpWidget(const SizedBox());
            server = crawlerServer();
            app = await CrawlerApp.mount(tester, server);
          }
        }
      }

      final report = _report(results, screenProblems, server.unhandled);
      Directory('build').createSync(recursive: true);
      File('build/crawler_report.md').writeAsStringSync(report);
      // ignore: avoid_print
      print(report);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

/// Every distinct tappable area on screen, in reading order.
List<_Target> _targets(WidgetTester tester) {
  final seen = <Rect>[];
  final targets = <_Target>[];
  bool tappable(Widget w) => switch (w) {
    InkWell(:final onTap, :final onLongPress) =>
      onTap != null || onLongPress != null,
    InkResponse(:final onTap) => onTap != null,
    GestureDetector(:final onTap) => onTap != null,
    ButtonStyleButton(:final onPressed) => onPressed != null,
    IconButton(:final onPressed) => onPressed != null,
    Switch(:final onChanged) => onChanged != null,
    Checkbox(:final onChanged) => onChanged != null,
    PopupMenuButton() => true,
    _ => false,
  };
  final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  for (final element
      in find.byWidgetPredicate(tappable).hitTestable().evaluate()) {
    final box = element.renderObject;
    if (box is! RenderBox || !box.hasSize || !box.attached) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect.width < 8 || rect.height < 8) continue;
    if (!(Offset.zero & screen).contains(rect.center)) continue;
    // Nested tappables (a button's own InkWell) share the same spot.
    if (seen.any((r) => (r.center - rect.center).distance < 6)) continue;
    seen.add(rect);
    targets.add(_Target(rect, _label(element, rect)));
  }
  targets.sort((a, b) {
    final dy = a.rect.top.compareTo(b.rect.top);
    return dy != 0 ? dy : a.rect.left.compareTo(b.rect.left);
  });
  return targets;
}

/// The text, tooltip or icon that tells a person what the target is.
String _label(Element element, Rect rect) {
  String? text;
  String? icon;
  String? tooltip;
  void visit(Element e) {
    final w = e.widget;
    if (text == null && w is Text) text = w.data ?? w.textSpan?.toPlainText();
    if (text == null && w is RichText) text = w.text.toPlainText();
    if (icon == null && w is Icon && w.icon != null) {
      icon = 'icon ${w.icon!.codePoint.toRadixString(16)}';
    }
    if (tooltip == null && w is Tooltip) tooltip = w.message;
    if (text == null) e.visitChildren(visit);
  }

  visit(element);
  // Icon-only buttons are named by a tooltip or semantics label above them.
  if (text == null && tooltip == null) {
    element.visitAncestorElements((ancestor) {
      final w = ancestor.widget;
      if (w is Tooltip && w.message != null) tooltip = w.message;
      if (w is Semantics && w.properties.label != null) {
        tooltip = w.properties.label;
      }
      return tooltip == null && ancestor.widget is! Scaffold;
    });
  }
  final where = '@${rect.center.dx.round()},${rect.center.dy.round()}';
  final name =
      (text ?? tooltip ?? icon ?? element.widget.runtimeType.toString())
          .replaceAll('\n', ' ')
          .trim();
  return '${name.length > 40 ? '${name.substring(0, 40)}…' : name} $where';
}

/// What's on screen: every onstage widget's type and key, plus its text,
/// icon, colour and selection state, so a tab highlight or a switch flip counts
/// as a change even when no words change. Looping animations are skipped.
String _fingerprint(WidgetTester tester) {
  final out = StringBuffer();
  void visit(Element e) {
    final w = e.widget;
    if (w is TickerMode && !w.enabled) return;
    if (w is Offstage && w.offstage) return;
    switch (w) {
      case Text(:final data):
        out.write('T$data|');
      case Icon(:final icon, :final color):
        out.write('I${icon?.codePoint}$color|');
      case Switch(:final value):
        out.write('S$value|');
      case Checkbox(:final value):
        out.write('C$value|');
      case EditableText(:final controller):
        out.write('E${controller.text}|');
      case DecoratedBox(:final decoration) when decoration is BoxDecoration:
        out.write('D${decoration.color}|');
      case _:
        break;
    }
    if (w.key != null) out.write('K${w.key}|');
    e.visitChildren(visit);
  }

  final root = tester.binding.rootElement;
  if (root != null) visit(root);
  return out.toString();
}

int _overlayCount(WidgetTester tester) =>
    find.byType(Dialog).evaluate().length +
    find.byType(AlertDialog).evaluate().length +
    find.byType(BottomSheet).evaluate().length +
    find.byType(PopupMenuItem).evaluate().length +
    find.byType(DatePickerDialog).evaluate().length;

String _snackText(WidgetTester tester) {
  final texts = find.descendant(
    of: find.byType(SnackBar),
    matching: find.byType(Text),
  );
  return texts.evaluate().map((e) => (e.widget as Text).data ?? '').join(' ');
}

bool _onErrorState(WidgetTester tester) =>
    find.text('Try again').evaluate().isNotEmpty ||
    find.textContaining('Check your connection').evaluate().isNotEmpty;

/// Overflow warnings from test fonts and image loads aren't app bugs here.
bool _ignorable(FlutterErrorDetails details) {
  final text = details.exceptionAsString();
  return text.contains('overflowed') ||
      text.contains('HTTP request failed') ||
      text.contains('NetworkImageLoadException') ||
      text.contains('Unable to load asset');
}

/// Closes dialogs, sheets and menus left open by the last tap.
void _closeOverlays(WidgetTester tester) {
  final scaffolds = find.byType(Scaffold).evaluate();
  if (scaffolds.isEmpty) return;
  final navigator = Navigator.maybeOf(scaffolds.first, rootNavigator: true);
  navigator?.popUntil((route) => route.settings is Page);
  ScaffoldMessenger.maybeOf(scaffolds.first)?.clearSnackBars();
}

String _report(
  List<_Tap> results,
  Map<String, String> screenProblems,
  Set<String> unhandled,
) {
  final out = StringBuffer('# Tap-everything crawler report\n\n');
  final byOutcome = <_Outcome, int>{};
  for (final r in results) {
    byOutcome[r.outcome] = (byOutcome[r.outcome] ?? 0) + 1;
  }
  out
    ..writeln(
      'Screens: ${results.map((r) => r.screen).toSet().length}, '
      'taps: ${results.length}',
    )
    ..writeln(
      'Outcomes: ${byOutcome.entries.map((e) => '${e.key.name} ${e.value}').join(', ')}\n',
    );

  final problems = results.where((r) => r.outcome == _Outcome.error).toList();
  out.writeln('## Errors (${problems.length})\n');
  for (final r in problems) {
    out.writeln('- `${r.screen}` → **${r.label}**: ${r.detail}');
  }
  final dead = results.where((r) => r.outcome == _Outcome.nothing).toList();
  out.writeln('\n## Taps with no visible effect (${dead.length})\n');
  out.writeln(
    'Check these by hand: some are fine (a tab that is already selected, '
    'a text field that only focuses), others are dead buttons.\n',
  );
  for (final r in dead) {
    out.writeln('- `${r.screen}` → ${r.label}');
  }
  out.writeln('\n## Screens on an error state (${screenProblems.length})\n');
  screenProblems.forEach((s, p) => out.writeln('- `$s`: $p'));
  if (unhandled.isNotEmpty) {
    out.writeln('\n## Endpoints the fixtures don\'t answer\n');
    for (final u in unhandled) {
      out.writeln('- `$u`');
    }
  }
  out.writeln('\n## Every tap\n');
  out.writeln('| Screen | Target | Result | Detail |');
  out.writeln('| --- | --- | --- | --- |');
  for (final r in results) {
    out.writeln(
      '| `${r.screen}` | ${r.label.replaceAll('|', '/')} | ${r.outcome.name} | '
      '${r.detail.replaceAll('|', '/')} |',
    );
  }
  return out.toString();
}
