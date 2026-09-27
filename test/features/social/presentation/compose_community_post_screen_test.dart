import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/social/data/social_api.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/compose_community_post_screen.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/features/mascot/providers/buddy_care_provider.dart';
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

  testWidgets('gallery accepts four photos and blocks the fifth', (
    tester,
  ) async {
    final picker = _TestImagePicker(
      galleryPhotos: [for (var i = 0; i < 5; i++) XFile('/tmp/photo-$i.png')],
    );
    final api = _ComposerApi();
    await _pump(tester, _loadedFeed(), picker: picker, api: api);

    await _pickFromGallery(tester);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('post-photo-item-picked-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('post-photo-item-picked-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('post-photo-item-picked-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('post-photo-item-picked-3')),
      findsOneWidget,
    );
    expect(picker.lastLimit, 4);
    expect(api.uploadedPaths, hasLength(4));

    final add = find.byKey(const ValueKey('compose-add-photo'));
    await tester.ensureVisible(add);
    expect(tester.widget<IconButton>(add).onPressed, isNull);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(picker.galleryCalls, 1);
  });

  testWidgets('photo thumbnails can be removed and reordered', (tester) async {
    final picker = _TestImagePicker(
      galleryPhotos: [
        XFile('/tmp/first.png'),
        XFile('/tmp/second.png'),
        XFile('/tmp/third.png'),
      ],
    );
    await _pump(tester, _loadedFeed(), picker: picker, api: _ComposerApi());
    await _pickFromGallery(tester);
    await tester.pumpAndSettle();

    final first = find.byKey(const ValueKey('post-photo-item-picked-0'));
    final second = find.byKey(const ValueKey('post-photo-item-picked-1'));
    final startX = tester.getTopLeft(first).dx;
    // Thumbnails use a delayed drag: hold first, then move.
    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('post-photo-reorder-picked-0')),
      ),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    for (var i = 0; i < 11; i++) {
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(first).dx, greaterThan(startX));
    expect(
      tester.getTopLeft(first).dx,
      greaterThan(tester.getTopLeft(second).dx),
    );

    await tester.tap(find.byKey(const ValueKey('post-photo-remove-picked-0')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('post-photo-item-picked-0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('post-photos-reorder-list')),
      findsOneWidget,
    );
  });

  testWidgets('a failed upload blocks submit until retried', (tester) async {
    final picker = _TestImagePicker(galleryPhotos: [XFile('/tmp/retry.png')]);
    final api = _ComposerApi()..failedUploads = 1;
    await _pump(tester, _loadedFeed(), picker: picker, api: api);
    await _pickFromGallery(tester);
    await tester.pumpAndSettle();

    expect(find.text('Network unavailable'), findsOneWidget);
    expect(_publish(tester).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('post-photo-retry-picked-0')));
    await tester.pumpAndSettle();

    expect(_publish(tester).onPressed, isNotNull);
    expect(api.uploadedPaths, hasLength(2));
  });

  testWidgets('removing a failed upload releases the submit block', (
    tester,
  ) async {
    final picker = _TestImagePicker(galleryPhotos: [XFile('/tmp/remove.png')]);
    final api = _ComposerApi()..failedUploads = 1;
    await _pump(tester, _loadedFeed(), picker: picker, api: api);
    await _pickFromGallery(tester);
    await tester.pumpAndSettle();
    expect(_publish(tester).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('post-photo-remove-picked-0')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('compose-body')),
      'A short post with no photo.',
    );
    await tester.pump();
    expect(_publish(tester).onPressed, isNotNull);
  });

  testWidgets('a photo-only post submits without title or body', (
    tester,
  ) async {
    final picker = _TestImagePicker(galleryPhotos: [XFile('/tmp/only.png')]);
    final api = _ComposerApi();
    await _pump(tester, _loadedFeed(), picker: picker, api: api);
    await _pickFromGallery(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();

    expect(api.createdTitle, '');
    expect(api.createdContent, '');
    expect(api.createdMedia, hasLength(1));
  });

  testWidgets('an empty post shows one inline message', (tester) async {
    await _pump(tester, _loadedFeed(), api: _ComposerApi());

    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('compose-empty-post-message')),
      findsOneWidget,
    );
    expect(
      find.text('Add some details or attach a photo before publishing.'),
      findsOneWidget,
    );
  });

  testWidgets('editing with every photo removed sends an empty media list', (
    tester,
  ) async {
    final post = _postWithMedia([
      const SocialPostMedia(url: 'https://example.org/photo.png'),
    ]);
    final api = _ComposerApi();
    await _pump(tester, _loadedFeed(), api: api, post: post);

    await tester.tap(
      find.byKey(const ValueKey('post-photo-remove-existing-0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();

    expect(api.updatedMedia, isEmpty);
  });

  testWidgets('editing text alone leaves existing photos unchanged', (
    tester,
  ) async {
    final post = _postWithMedia([
      const SocialPostMedia(
        url: 'https://example.org/photo.png',
        width: 1200,
        height: 900,
      ),
    ]);
    final api = _ComposerApi();
    await _pump(tester, _loadedFeed(), api: api, post: post);

    await tester.enterText(
      find.byKey(const ValueKey('compose-body')),
      'Updated body text.',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('compose-submit')));
    await tester.pumpAndSettle();

    expect(api.updatedMedia, isNull);
  });
}

FilledButton _publish(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const ValueKey('compose-submit')));

_Feed _loadedFeed() => _Feed(
  const SocialFeedLoaded(categories: [_biology], posts: [], hasNextPage: false),
);

Future<void> _pump(
  WidgetTester tester,
  _Feed feed, {
  String? communityId,
  _TestImagePicker? picker,
  _ComposerApi? api,
  SocialPost? post,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socialFeedProvider.overrideWith(() => feed),
        socialApiProvider.overrideWithValue(api ?? _ComposerApi()),
        authProvider.overrideWith(_SignedInAuth.new),
        buddyCareProvider.overrideWith(_TestBuddyCare.new),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
        home: ComposeCommunityPostScreen(
          communityId: communityId,
          post: post,
          imagePicker: picker,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pickFromGallery(WidgetTester tester) async {
  final add = find.byKey(const ValueKey('compose-add-photo'));
  await tester.ensureVisible(add);
  await tester.tap(add);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('pick-from-gallery')));
  await tester.pumpAndSettle();
}

SocialPost _postWithMedia(List<SocialPostMedia> media) => SocialPost(
  id: 'post-edit',
  title: 'Edited post',
  content: 'Current body content.',
  media: media,
  reactionCount: 0,
  commentCount: 0,
  shareCount: 0,
  author: const SocialAuthor(
    id: 'me',
    username: 'sopanha',
    displayName: 'Sopanha',
    avatarUrl: '',
  ),
  category: _biology,
  createdAt: DateTime.utc(2026, 8, 24),
  updatedAt: DateTime.utc(2026, 8, 24),
);

class _SignedInAuth extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    AuthUser(
      id: 'me',
      username: 'sopanha',
      displayName: 'Sopanha',
      emailVerified: true,
      phoneVerified: true,
      role: 'USER',
    ),
  );
}

class _TestImagePicker extends ImagePicker {
  _TestImagePicker({required this.galleryPhotos});

  final List<XFile> galleryPhotos;
  final XFile? cameraPhoto = null;
  int galleryCalls = 0;
  int? lastLimit;

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async {
    galleryCalls++;
    lastLimit = limit;
    return galleryPhotos;
  }

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => cameraPhoto;
}

class _ComposerApi implements SocialApi {
  final List<String> uploadedPaths = [];
  int failedUploads = 0;
  String? createdTitle;
  String? createdContent;
  List<SocialPostMedia>? createdMedia;
  List<SocialPostMedia>? updatedMedia;

  @override
  Future<SocialPostMedia> uploadMedia(
    String filePath, {
    String? filename,
    ProgressCallback? onSendProgress,
  }) async {
    uploadedPaths.add(filePath);
    onSendProgress?.call(20, 100);
    if (failedUploads > 0) {
      failedUploads--;
      throw const SocialApiException('Network unavailable');
    }
    return SocialPostMedia(
      url: 'https://example.org/${uploadedPaths.length}.png',
      width: 1200,
      height: 900,
    );
  }

  @override
  Future<SocialPost> createPostWithMedia({
    required String title,
    required String content,
    required String categoryId,
    List<SocialPostMedia> media = const [],
  }) async {
    createdTitle = title;
    createdContent = content;
    createdMedia = media;
    return _createdPostWithMedia(media);
  }

  @override
  Future<SocialPost> updatePostWithMedia({
    required String id,
    required String title,
    required String content,
    List<SocialPostMedia>? media,
  }) async {
    updatedMedia = media;
    return _createdPostWithMedia(media ?? const []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SocialPost _createdPostWithMedia(List<SocialPostMedia> media) => SocialPost(
  id: 'created-post',
  title: 'Photo post',
  content: 'Photo post body',
  media: media,
  reactionCount: 0,
  commentCount: 0,
  shareCount: 0,
  author: const SocialAuthor(
    id: 'me',
    username: 'sopanha',
    displayName: 'Sopanha',
    avatarUrl: '',
  ),
  category: _biology,
  createdAt: DateTime.utc(2026, 8, 24),
  updatedAt: DateTime.utc(2026, 8, 24),
);

class _TestBuddyCare extends BuddyCareNotifier {
  @override
  BuddyCareState build() => BuddyCareState.initial(DateTime(2026, 9, 1));

  @override
  Future<void> refresh() async {}
}
