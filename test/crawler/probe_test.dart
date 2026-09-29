// One-off probe: which endpoints does each screen call? Run with
// `flutter test test/crawler/probe_test.dart` and read the printed report.
import 'package:flutter_test/flutter_test.dart';

import 'crawler_harness.dart';
import 'crawler_fixtures.dart';

final _routes = [
  '/learn',
  '/home',
  '/community',
  '/communities',
  '/blog',
  '/blog/my-posts',
  '/ai',
  '/leaderboard',
  '/profile',
  '/profile/settings',
  '/notifications',
  '/market',
  '/market/wardrobe',
  '/learn/saved',
  '/progress',
  '/learn/roadmap/$kMathId',
  '/learn/$kLesson2Id',
  '/community/posts/$kPostId',
  '/blog/$kBlogId',
  '/ai/chat/$kChatId',
  '/profile/$kOtherUserId',
];

void main() {
  testWidgets('probe endpoints per route', (tester) async {
    final server = crawlerServer();
    final app = await CrawlerApp.mount(tester, server);
    final report = StringBuffer('BOOT: ${server.requests.toSet()}\n');
    for (final route in _routes) {
      server.requests.clear();
      app.router.go(route);
      await CrawlerApp.settle(tester);
      final error = tester.takeException();
      report.writeln(
        '$route -> now at ${app.router.state.uri} | '
        '${server.requests.toSet()}${error == null ? '' : ' | EXCEPTION $error'}',
      );
    }
    report.writeln('UNHANDLED: ${server.unhandled}');
    // ignore: avoid_print
    print(report);
  });
}
