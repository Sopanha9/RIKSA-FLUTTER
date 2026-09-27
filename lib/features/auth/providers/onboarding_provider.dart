import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/locale_provider.dart';
import '../data/onboarding_models.dart';

class OnboardingNotifier extends Notifier<OnboardingSetupData> {
  static const String _goalKey = 'riksa_onboarding_goal';
  static const String _subjectKey = 'riksa_onboarding_subject';
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
    final paceMins = prefs.getInt(_paceKey);
    // Read the legacy value for one release so existing installs can restore
    // cleanly; the new onboarding no longer awards or writes setup XP.
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

    OnboardingPace? restoredPace;
    if (paceMins != null) {
      for (final p in OnboardingPace.values) {
        if (p.minutes == paceMins) restoredPace = p;
      }
    }

    state = state.copyWith(
      goal: restoredGoal,
      subject: restoredSubject,
      pace: restoredPace,
      earnedXp: earnedXp,
    );
  }

  void setGoal(OnboardingGoal goal) {
    state = state.copyWith(goal: goal);
  }

  /// Switching the starting subject clears any legacy warm-up answers.
  void setSubject(OnboardingSubject subject) {
    if (subject == state.subject) return;
    final answered =
        state.quizAnswer1Index != null || state.quizAnswer2Index != null;
    if (!answered) {
      state = state.copyWith(subject: subject);
      return;
    }
    state = OnboardingSetupData(
      goal: state.goal,
      subject: subject,
      provinceId: state.provinceId,
      provinceNameLatin: state.provinceNameLatin,
      provinceNameKhmer: state.provinceNameKhmer,
      pace: state.pace,
    );
  }

  /// Records the answer to the first question, asked right after the subject.
  void answerFirstQuestion(int index) {
    state = state.copyWith(quizAnswer1Index: index);
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
    if (state.pace != null) {
      futures.add(prefs.setInt(_paceKey, state.pace!.minutes));
    }
    final provinceId = state.provinceId;
    if (provinceId != null) {
      futures.add(
        ref.read(localeProvider.notifier).savePendingProvince(provinceId),
      );
    }

    await Future.wait(futures);
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingSetupData>(
      OnboardingNotifier.new,
    );
