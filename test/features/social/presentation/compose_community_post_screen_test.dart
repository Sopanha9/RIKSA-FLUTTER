import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/compose_community_post_screen.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

const _biology = SocialCategory(
  id: 'biology',
  name: 'Biology',
  slug: 'biology',
  memberCount: 2,
  joined: true,
);
const _general = SocialCategory(
  id: 'general',
  name: 'General Discussion',
  slug: 'general',
  memberCount: 5000,
  joined: true,
);

/// A feed whose state the test drives by hand.
class _Feed extends SocialFeedNotifier {
  _Feed(this.initial);

  final SocialFeedState initial;
  int loads = 0;

  @override
  SocialFeedState build() => initial;

  @override
  Future<void> load({String? categoryId}) async {
    loads++;
    state = const SocialFeedLoading();
  }

  void emit(SocialFeedState next) => state = next;
}

/// Not knowing which communities someone belongs to is not the same as them
/// belonging to none.
void main() {
  testWidgets('a failed community list offers a retry, not "join first"', (
    tester,
  ) async {
    final feed = _Feed(const SocialFeedFailure('offline'));
    await _pump(tester, feed);

    expect(
      find.byKey(const ValueKey('compose-communities-failed')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('compose-browse-communities')),
      findsNothing,
    );
    expect(_publish(tester).onPressed, isNull);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(feed.loads, 1);
    expect(find.text('Loading your communities…'), findsOneWidget);
  });

  testWidgets('the starting community survives the list loading', (
    tester,
  ) async {
    final feed = _Feed(const SocialFeedLoading());
    await _pump(tester, feed, communityId: 'biology');

    expect(find.text('Loading your communities…'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('compose-browse-communities')),
      findsNothing,
    );

    feed.emit(
      const SocialFeedLoaded(
        categories: [_general, _biology],
        posts: [],
        hasNextPage: false,
      ),
    );
    await tester.pump();

    expect(find.text('Biology'), findsOneWidget);
    expect(find.text('General Discussion'), findsNothing);
  });

  testWidgets('an empty membership list asks the author to join first', (
    tester,
  ) async {
    final feed = _Feed(
      const SocialFeedLoaded(categories: [], posts: [], hasNextPage: false),
    );
    await _pump(tester, feed);

    expect(
      find.byKey(const ValueKey('compose-browse-communities')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('compose-communities-failed')),
      findsNothing,
    );
  });

  testWidgets('bold formats the selection and preview renders markdown', (
    tester,
  ) async {
    await _pump(tester, _Feed(const SocialFeedFailure('offline')));

    final bodyFinder = find.byKey(const ValueKey('compose-body'));
    final controller = tester.widget<TextFormField>(bodyFinder).controller!;
    await tester.tap(bodyFinder);
    controller.value = const TextEditingValue(
      text: 'important',
      selection: TextSelection(baseOffset: 0, extentOffset: 9),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('blog-markdown-bold')));
    await tester.pump();
    expect(controller.text, '**important**');

    await tester.tap(find.byKey(const ValueKey('compose-preview')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('compose-markdown-preview')),
      findsOneWidget,
    );
    expect(find.text('important'), findsOneWidget);
  });
}

FilledButton _publish(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const ValueKey('compose-submit')));

Future<void> _pump(
  WidgetTester tester,
  _Feed feed, {
  String? communityId,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [socialFeedProvider.overrideWith(() => feed)],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
        home: ComposeCommunityPostScreen(communityId: communityId),
      ),
    ),
  );
  await tester.pump();
}
