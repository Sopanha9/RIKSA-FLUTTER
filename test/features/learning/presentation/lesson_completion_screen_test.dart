import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/learning/presentation/learning_result_screens.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

void main() {
  Widget buildScreen({
    Locale locale = const Locale('en'),
    int xpEarned = 35,
    String? lessonTitle = 'Cell Biology & Organelles',
    String? categoryName = 'Biology',
    String? roadmapCategoryId = 'biology',
    int? totalExercises = 4,
  }) {
    return MaterialApp(
      locale: locale,
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('km')],
      home: LessonCompletionScreen(
        xpEarned: xpEarned,
        lessonTitle: lessonTitle,
        categoryName: categoryName,
        roadmapCategoryId: roadmapCategoryId,
        totalExercises: totalExercises,
      ),
    );
  }

  testWidgets(
    'renders English lesson completion celebration with XP and exercises pills',
    (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Lesson Mastered!'), findsOneWidget);
      expect(find.text('Cell Biology & Organelles'), findsOneWidget);
      expect(find.text('+35 XP Earned'), findsOneWidget);
      expect(find.text('4 Exercises Completed'), findsOneWidget);

      expect(find.byKey(const ValueKey('lesson-completion-share')), findsOneWidget);
      expect(find.text('Share Achievement to Community'), findsOneWidget);

      expect(
        find.byKey(const ValueKey('lesson-completion-continue')),
        findsOneWidget,
      );
      expect(find.text('Back to roadmap'), findsOneWidget);

      expect(find.byKey(const ValueKey('lesson-completion-home')), findsOneWidget);
      expect(find.text('Back home'), findsOneWidget);
    },
  );

  testWidgets(
    'renders Khmer lesson completion with localized labels and grammar',
    (tester) async {
      await tester.pumpWidget(
        buildScreen(
          locale: const Locale('km'),
          lessonTitle: 'ជីវវិទ្យាកោសិកា',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('បានបញ្ចប់មេរៀនជោគជ័យ!'), findsOneWidget);
      expect(find.text('ជីវវិទ្យាកោសិកា'), findsOneWidget);
      expect(find.text('+35 ពិន្ទុ XP ទទួលបាន'), findsOneWidget);
      expect(find.text('4 លំហាត់បានអនុវត្ត'), findsOneWidget);

      expect(find.text('ចែករំលែកទៅកាន់សហគមន៍'), findsOneWidget);
      expect(find.text('ត្រឡប់ទៅផែនទីសិក្សា'), findsOneWidget);
      expect(find.text('ត្រឡប់ទៅទំព័រដើម'), findsOneWidget);
    },
  );

  testWidgets(
    'renders generic continue learning when roadmapCategoryId is null',
    (tester) async {
      await tester.pumpWidget(
        buildScreen(roadmapCategoryId: null, totalExercises: null),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue learning'), findsOneWidget);
      // No exercises pill when totalExercises is null
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    },
  );
}
