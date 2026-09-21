import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/locale_provider.dart';
import '../../learning/data/learning_models.dart';
import '../../learning/providers/lesson_catalog_provider.dart';
import '../data/onboarding_models.dart';

class OnboardingNotifier extends Notifier<OnboardingSetupData> {
  static const String _goalKey = 'riksa_onboarding_goal';
  static const String _subjectKey = 'riksa_onboarding_subject';
  static const String _subjectIdKey = 'riksa_onboarding_subject_id';
  static const String _subjectNameKey = 'riksa_onboarding_subject_name';
  static const String _paceKey = 'riksa_onboarding_pace';
  static const String _xpKey = 'riksa_onboarding_earned_xp';

  @override
  OnboardingSetupData build() {
    _restore();
    return const OnboardingSetupData();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final goalId = prefs.getString(_goalKey);
    final subjectId = prefs.getString(_subjectKey);
    final subjectCategoryId = prefs.getString(_subjectIdKey);
    final subjectCategoryName = prefs.getString(_subjectNameKey);
    final paceMins = prefs.getInt(_paceKey);
    final earnedXp = prefs.getInt(_xpKey) ?? 0;

    OnboardingGoal? restoredGoal;
    if (goalId != null) {
      for (final g in OnboardingGoal.values) {
        if (g.id == goalId) restoredGoal = g;
      }
    }

    OnboardingSubject? restoredSubject;
    if (subjectId != null) {
      for (final s in OnboardingSubject.values) {
        if (s.id == subjectId) restoredSubject = s;
      }
    }

    OnboardingSubjectOption? restoredOption;
    if (restoredSubject != null) {
      restoredOption = OnboardingSubjectOption.fromEnum(restoredSubject);
    }

    OnboardingPace? restoredPace;
    if (paceMins != null) {
      for (final p in OnboardingPace.values) {
        if (p.minutes == paceMins) restoredPace = p;
      }
    }

    state = state.copyWith(
      goal: restoredGoal,
      subject: restoredSubject,
      subjectOption: restoredOption,
      subjectCategoryId: subjectCategoryId,
      subjectCategoryName: subjectCategoryName,
      pace: restoredPace,
      earnedXp: earnedXp,
    );
  }

  void setGoal(OnboardingGoal goal) {
    state = state.copyWith(goal: goal);
  }

  void setSubject(OnboardingSubject subject) {
    final option = OnboardingSubjectOption.fromEnum(subject);
    state = state.copyWith(
      subject: subject,
      subjectOption: option,
      subjectCategoryId: option.categoryId,
      subjectCategoryName: option.titleEn,
    );
  }

  void setSubjectOption(OnboardingSubjectOption option) {
    state = state.copyWith(
      subject: option.onboardingSubject,
      subjectOption: option,
      subjectCategoryId: option.categoryId ?? option.id,
      subjectCategoryName: option.titleEn,
    );
  }

  void setProvince({
    required String id,
    required String nameLatin,
    required String nameKhmer,
  }) {
    state = state.copyWith(
      provinceId: id,
      provinceNameLatin: nameLatin,
      provinceNameKhmer: nameKhmer,
    );
  }

  void setPace(OnboardingPace pace) {
    state = state.copyWith(pace: pace);
  }

  void setQuizAnswer1(int index, bool isCorrect) {
    final newXp = (state.earnedXp) + (isCorrect ? 10 : 5);
    state = state.copyWith(
      quizAnswer1Index: index,
      earnedXp: newXp,
    );
  }

  void setQuizAnswer2(int index, bool isCorrect) {
    final newXp = (state.earnedXp) + (isCorrect ? 10 : 5);
    state = state.copyWith(
      quizAnswer2Index: index,
      earnedXp: newXp,
    );
  }

  /// Commits choices to SharedPreferences and updates the locale provider
  /// with the pending province.
  Future<void> commitSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final futures = <Future<void>>[];

    if (state.goal != null) {
      futures.add(prefs.setString(_goalKey, state.goal!.id));
    }
    if (state.subject != null) {
      futures.add(prefs.setString(_subjectKey, state.subject!.id));
    }
    final categoryId = state.subjectCategoryId ?? state.subjectOption?.categoryId;
    if (categoryId != null && categoryId.isNotEmpty) {
      futures.add(prefs.setString(_subjectIdKey, categoryId));
    }
    final categoryName = state.subjectCategoryName ??
        state.subjectOption?.titleEn ??
        state.subject?.name;
    if (categoryName != null && categoryName.isNotEmpty) {
      futures.add(prefs.setString(_subjectNameKey, categoryName));
    }
    if (state.pace != null) {
      futures.add(prefs.setInt(_paceKey, state.pace!.minutes));
    }
    futures.add(prefs.setInt(_xpKey, state.earnedXp));

    final provinceId = state.provinceId;
    if (provinceId != null) {
      futures.add(ref.read(localeProvider.notifier).savePendingProvince(provinceId));
    }

    await Future.wait(futures);
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingSetupData>(
      OnboardingNotifier.new,
    );

final onboardingSubjectsProvider =
    FutureProvider<List<OnboardingSubjectOption>>((ref) async {
  try {
    final api = ref.watch(learningApiProvider);
    final categories = await api.categories();
    final stemCategories = categories
        .where((c) => isStemLearningCategory(c.name))
        .toList(growable: false);

    if (stemCategories.isEmpty) {
      return OnboardingSubjectOption.defaults;
    }

    return stemCategories
        .map(OnboardingSubjectOption.fromCategory)
        .toList(growable: false);
  } catch (_) {
    return OnboardingSubjectOption.defaults;
  }
});
