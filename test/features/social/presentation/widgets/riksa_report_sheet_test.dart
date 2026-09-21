import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/social/data/social_api.dart';
import 'package:riksa_app/features/social/presentation/widgets/riksa_report_sheet.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

class _MockSocialApi extends Fake implements SocialApi {
  String? lastTargetType;
  String? lastTargetId;
  String? lastReason;
  String? lastDetails;
  bool shouldThrowConflict = false;

  @override
  Future<void> fileReport({
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  }) async {
    lastTargetType = targetType;
    lastTargetId = targetId;
    lastReason = reason;
    lastDetails = details;
    if (shouldThrowConflict) {
      throw const SocialApiException('You have already reported this content');
    }
  }
}

void main() {
  late _MockSocialApi mockApi;

  setUp(() {
    mockApi = _MockSocialApi();
  });

  Widget createTestWidget({
    String targetType = 'POST',
    String targetId = 'test-post-1',
    String? targetTitle = 'Sample Post Title',
    Locale locale = const Locale('en'),
  }) {
    return ProviderScope(
      overrides: [
        socialApiProvider.overrideWithValue(mockApi),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
        home: Scaffold(
          body: RiksaReportSheet(
            targetType: targetType,
            targetId: targetId,
            targetTitle: targetTitle,
          ),
        ),
      ),
    );
  }

  testWidgets('renders report sheet with title, reasons, and submit button', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Report Content'), findsOneWidget);
    expect(find.text('Sample Post Title'), findsOneWidget);
    expect(find.text('Why are you reporting this content?'), findsOneWidget);
    expect(find.text('Spam or unwanted advertising'), findsOneWidget);
    expect(find.text('Harassment or abusive speech'), findsOneWidget);
    expect(find.text('Inappropriate or explicit content'), findsOneWidget);
    expect(find.byKey(const ValueKey('report-submit-button')), findsOneWidget);
  });

  testWidgets('submits report with selected reason and details', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Select HARASSMENT reason
    await tester.tap(find.byKey(const ValueKey('report-reason-HARASSMENT')));
    await tester.pumpAndSettle();

    // Enter details
    await tester.enterText(
      find.byKey(const ValueKey('report-details-input')),
      'This post is abusive to community members.',
    );
    await tester.pumpAndSettle();

    // Submit
    final submitButton = find.byKey(const ValueKey('report-submit-button'));
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(mockApi.lastTargetType, 'POST');
    expect(mockApi.lastTargetId, 'test-post-1');
    expect(mockApi.lastReason, 'HARASSMENT');
    expect(mockApi.lastDetails, 'This post is abusive to community members.');
  });

  testWidgets('handles conflict gracefully when already reported', (
    tester,
  ) async {
    mockApi.shouldThrowConflict = true;
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final submitButton = find.byKey(const ValueKey('report-submit-button'));
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('You have already reported this content.'), findsOneWidget);
  });

  testWidgets('renders in Khmer with localized copy', (tester) async {
    await tester.pumpWidget(createTestWidget(locale: const Locale('km')));
    await tester.pumpAndSettle();

    expect(find.text('រាយការណ៍ខ្លឹមសារ'), findsOneWidget);
    expect(find.text('សារឥតបានការ ឬការផ្សាយពាណិជ្ជកម្មរំខាន'), findsOneWidget);
    expect(find.text('ផ្ញើការរាយការណ៍'), findsOneWidget);
  });
}
