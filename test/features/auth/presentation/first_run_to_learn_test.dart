import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/app/router/app_router.dart';
import 'package:riksa_app/core/providers/locale_provider.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/providers/learning_home_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _GuestNotifier extends AuthNotifier {
  @override
  AuthState build() => const Unauthenticated();
}

class _FreshLocaleNotifier extends LocaleNotifier {
  @override
  LocaleState build() => const LocaleState(
    locale: Locale('km'),
    isReady: true,
    hasSelection: false,
  );
}

const _physicsLesson = LessonSummary(
  id: 'physics-first',
  title: 'Physics First Lesson',
  description: 'Start with motion.',
  difficulty: LessonDifficulty.easy,
  baseXp: 10,
  categoryId: 'physics-id',
  categoryName: 'Physics',
  exerciseCount: 1,
  completed: false,
  createdAt: null,
  position: 1,
);

const _physics = SubjectProgress(
  category: LearningCategory(id: 'physics-id', name: 'Physics'),
  lessons: [_physicsLesson],
  total: 1,
);

const _home = LearningHomeData(
  subjects: [
    SubjectProgress(
      category: LearningCategory(id: 'math-id', name: 'Mathematics'),
      lessons: [],
    ),
    _physics,
    SubjectProgress(
      category: LearningCategory(id: 'chemistry-id', name: 'Chemistry'),
      lessons: [],
    ),
    SubjectProgress(
      category: LearningCategory(id: 'biology-id', name: 'Biology'),
      lessons: [],
    ),
  ],
  resumeSubject: _physics,
  resumeLesson: _physicsLesson,
);

const _provinces = [
  ProvinceOption(
    id: 'province-phnom-penh',
    nameKhmer: 'ភ្នំពេញ',
    nameLatin: 'Phnom Penh',
  ),
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'fresh start picks a buddy and province, then reaches the subject',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late GoRouter router;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(_GuestNotifier.new),
            localeProvider.overrideWith(_FreshLocaleNotifier.new),
            learningHomeProvider.overrideWith((ref) async => _home),
            provinceOptionsProvider.overrideWith((ref) async => _provinces),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(goRouterProvider);
              return MaterialApp.router(
                theme: AppTheme.light,
                locale: const Locale('km'),
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: true),
                  child: child!,
                ),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('en'), Locale('km')],
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      expect(find.byKey(const ValueKey('splash_get_started')), findsOneWidget);

      var taps = 0;
      Future<void> tap(Key key) async {
        final target = find.byKey(key);
        await tester.ensureVisible(target);
        await tester.tap(target);
        taps++;
        await tester.pumpAndSettle();
      }

      await tap(const ValueKey('splash_get_started'));
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/language-select',
      );

      // Khmer is the first-run default; confirming it is the language decision.
      await tap(const ValueKey('language_continue'));
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/mascot-select',
      );

      await tap(const Key('mascot_continue'));
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/onboarding/setup',
      );

      await tester.tap(find.text('រូបវិទ្យា'));
      taps++;
      await tester.pumpAndSettle();

      await tester.tap(find.text('ភ្នំពេញ'));
      taps++;
      await tester.pumpAndSettle();
      await tap(const Key('onboarding_continue_btn'));
      expect(find.text('ផ្លូវរៀនរូបវិទ្យា របស់អ្នករួចរាល់ហើយ'), findsOneWidget);

      await tap(const ValueKey('onboarding_start_learning'));
      expect(router.routerDelegate.currentConfiguration.uri.path, '/learn');
      // Language, buddy, subject and squad are the only decisions.
      expect(taps, lessThanOrEqualTo(7));
      expect(find.text('Physics First Lesson'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('resume-lesson-physics-first')),
        findsOneWidget,
      );
      expect(find.text('ចាប់ផ្តើមទីនេះ'), findsOneWidget);
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('subject-tile-physics-id')))
            .dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey('subject-tile-math-id')))
              .dy,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
