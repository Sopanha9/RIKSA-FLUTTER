import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/mathematics_roadmap_screen.dart';
import 'package:riksa_app/features/learning/providers/learning_roadmap_provider.dart';

const _roadmap = LessonRoadmap(
  categoryId: 'math',
  categoryName: 'Mathematics',
  lessons: [
    LessonSummary(id: 'one', title: 'Algebraic Expressions', description: '', difficulty: LessonDifficulty.easy, baseXp: 60, categoryId: 'math', categoryName: 'Mathematics', exerciseCount: 11, completed: false, createdAt: null, position: 1),
    LessonSummary(id: 'two', title: 'Linear Equations', description: '', difficulty: LessonDifficulty.easy, baseXp: 70, categoryId: 'math', categoryName: 'Mathematics', exerciseCount: 3, completed: false, createdAt: null, position: 2, state: LessonProgressState.locked),
  ],
);

void main() {
  testWidgets('renders API lesson states and only opens non-locked lessons', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const LearningRoadmapScreen(categoryId: 'math')),
      GoRoute(path: '/learn/:id', builder: (_, state) => Text('lesson-${state.pathParameters['id']}')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [learningRoadmapProvider('math').overrideWith((ref) async => _roadmap)],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.text('1. Algebraic Expressions'), findsOneWidget);
    expect(find.text('2. Linear Equations'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('roadmap-lesson-one')));
    await tester.pumpAndSettle();
    expect(find.text('lesson-one'), findsOneWidget);
  });
}
