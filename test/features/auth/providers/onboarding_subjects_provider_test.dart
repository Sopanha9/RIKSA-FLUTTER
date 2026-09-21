import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/auth/data/onboarding_models.dart';
import 'package:riksa_app/features/auth/providers/onboarding_provider.dart';
import 'package:riksa_app/features/learning/data/learning_api.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/presentation/learning_design.dart';
import 'package:riksa_app/features/learning/providers/lesson_catalog_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApiWithCategories implements LearningApi {
  _FakeApiWithCategories(this._categories);
  final List<LearningCategory> _categories;

  @override
  Future<List<LearningCategory>> categories() async => _categories;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingApi implements LearningApi {
  @override
  Future<List<LearningCategory>> categories() async =>
      throw Exception('Network offline');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('onboardingSubjectsProvider', () {
    test('hydrates live STEM categories with UUIDs and maps to STEM subjects', () async {
      final container = ProviderContainer(
        overrides: [
          learningApiProvider.overrideWithValue(
            _FakeApiWithCategories(const [
              LearningCategory(
                id: 'uuid-math-01',
                name: 'Mathematics',
                slug: 'mathematics',
              ),
              LearningCategory(
                id: 'uuid-phys-02',
                name: 'Physics',
                slug: 'physics',
              ),
              LearningCategory(
                id: 'uuid-chem-03',
                name: 'Chemistry',
                slug: 'chemistry',
              ),
              LearningCategory(
                id: 'uuid-bio-04',
                name: 'Biology',
                slug: 'biology',
              ),
              LearningCategory(
                id: 'uuid-general-05',
                name: 'General Discussion',
                slug: 'general-discussion',
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final subjects = await container.read(onboardingSubjectsProvider.future);

      // Only STEM categories are kept (General Discussion is filtered out)
      expect(subjects.length, 4);

      final math = subjects.firstWhere((s) => s.id == 'uuid-math-01');
      expect(math.categoryId, 'uuid-math-01');
      expect(math.stemSubject, StemSubject.mathematics);
      expect(math.onboardingSubject, OnboardingSubject.math);
      expect(math.title('km'), 'គណិតវិទ្យា');
      expect(math.title('en'), 'Mathematics');

      final physics = subjects.firstWhere((s) => s.id == 'uuid-phys-02');
      expect(physics.categoryId, 'uuid-phys-02');
      expect(physics.stemSubject, StemSubject.physics);
      expect(physics.onboardingSubject, OnboardingSubject.physics);
    });

    test('supports live categories authored in Khmer script', () async {
      final container = ProviderContainer(
        overrides: [
          learningApiProvider.overrideWithValue(
            _FakeApiWithCategories(const [
              LearningCategory(
                id: 'uuid-km-math',
                name: 'គណិតវិទ្យាថ្នាក់ទី១២',
                slug: 'math-grade-12',
              ),
              LearningCategory(
                id: 'uuid-km-phys',
                name: 'រូបវិទ្យាវិទ្យាសាស្ត្រ',
                slug: 'physics-science',
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final subjects = await container.read(onboardingSubjectsProvider.future);
      expect(subjects.length, 2);
      expect(subjects[0].stemSubject, StemSubject.mathematics);
      expect(subjects[1].stemSubject, StemSubject.physics);
    });

    test('gracefully falls back to default STEM subjects when offline/failing', () async {
      final container = ProviderContainer(
        overrides: [
          learningApiProvider.overrideWithValue(_FailingApi()),
        ],
      );
      addTearDown(container.dispose);

      final subjects = await container.read(onboardingSubjectsProvider.future);
      expect(subjects.length, 4);
      expect(subjects.map((s) => s.id), [
        'MATHEMATICS',
        'PHYSICS',
        'CHEMISTRY',
        'BIOLOGY',
      ]);
    });
  });

  group('OnboardingNotifier category selection & persistence', () {
    test('commitSetup saves subject id, name, and enum key', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final option = OnboardingSubjectOption(
        id: 'uuid-physics-live',
        categoryId: 'uuid-physics-live',
        categorySlug: 'physics',
        onboardingSubject: OnboardingSubject.physics,
        stemSubject: StemSubject.physics,
        titleEn: 'Physics',
        titleKm: 'រូបវិទ្យា',
        subtitleEn: 'Forces & Energy',
        subtitleKm: 'កម្លាំង និងថាមពល',
        icon: stemSubjectIcon(StemSubject.physics),
      );

      container.read(onboardingProvider.notifier).setSubjectOption(option);
      await container.read(onboardingProvider.notifier).commitSetup();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('riksa_onboarding_subject'), 'PHYSICS');
      expect(prefs.getString('riksa_onboarding_subject_id'), 'uuid-physics-live');
      expect(prefs.getString('riksa_onboarding_subject_name'), 'Physics');
    });
  });
}
