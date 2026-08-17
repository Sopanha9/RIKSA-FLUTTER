import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_provider.dart';

class ProfileSetupState {
  const ProfileSetupState({
    this.province,
    this.topics = const {},
    this.learningGoal,
    this.avatarId,
    this.username,
    this.bio = '',
    this.interests = const {},
    this.isComplete = false,
  });

  final String? province;
  final Set<String> topics;
  final LearningGoal? learningGoal;
  final String? avatarId;
  final String? username;
  final String bio;
  final Set<String> interests;
  final bool isComplete;

  ProfileSetupState copyWith({
    String? province,
    Set<String>? topics,
    LearningGoal? learningGoal,
    String? avatarId,
    String? username,
    String? bio,
    Set<String>? interests,
    bool? isComplete,
  }) =>
      ProfileSetupState(
        province: province ?? this.province,
        topics: topics ?? this.topics,
        learningGoal: learningGoal ?? this.learningGoal,
        avatarId: avatarId ?? this.avatarId,
        username: username ?? this.username,
        bio: bio ?? this.bio,
        interests: interests ?? this.interests,
        isComplete: isComplete ?? this.isComplete,
      );
}

enum LearningGoal { learn, compete, streak, community }

class ProfileSetupNotifier extends AsyncNotifier<ProfileSetupState> {
  String? _userId;

  @override
  Future<ProfileSetupState> build() async {
    final auth = ref.watch(authProvider);
    if (auth is! Authenticated) return const ProfileSetupState();
    _userId = auth.userId;
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'profile_setup_${auth.userId}_';
    final goalName = prefs.getString('${prefix}goal');
    return ProfileSetupState(
      province: prefs.getString('${prefix}province'),
      topics: (prefs.getStringList('${prefix}topics') ?? []).toSet(),
      learningGoal: LearningGoal.values.where((goal) => goal.name == goalName).firstOrNull,
      avatarId: prefs.getString('${prefix}avatar'),
      username: prefs.getString('${prefix}username'),
      bio: prefs.getString('${prefix}bio') ?? '',
      interests: (prefs.getStringList('${prefix}interests') ?? []).toSet(),
      isComplete: prefs.getBool('${prefix}complete') ?? false,
    );
  }

  void selectProvince(String province) => _update((current) => current.copyWith(province: province));

  void toggleTopic(String topic) => _update((current) {
        final topics = {...current.topics};
        topics.contains(topic) ? topics.remove(topic) : topics.add(topic);
        return current.copyWith(topics: topics);
      });

  void selectGoal(LearningGoal goal) => _update((current) => current.copyWith(learningGoal: goal));

  void selectAvatar(String avatarId) => _update((current) => current.copyWith(avatarId: avatarId));

  void setUsername(String username) => _update((current) => current.copyWith(username: username));

  void setBio(String bio) => _update((current) => current.copyWith(bio: bio));

  void toggleInterest(String interest) => _update((current) {
        final interests = {...current.interests};
        interests.contains(interest) ? interests.remove(interest) : interests.add(interest);
        return current.copyWith(interests: interests);
      });

  Future<void> complete() async {
    final current = switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (current == null || _userId == null) return;
    final completed = current.copyWith(isComplete: true);
    state = AsyncData(completed);
    await _save(completed);
  }

  void _update(ProfileSetupState Function(ProfileSetupState) update) {
    final current = switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (current == null) return;
    final next = update(current);
    state = AsyncData(next);
    _save(next);
  }

  Future<void> _save(ProfileSetupState value) async {
    if (_userId == null) return;
    // TODO(api): Replace this per-user local cache with the profile setup API.
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'profile_setup_${_userId}_';
    await Future.wait([
      prefs.setBool('riksa_intro_seen', true),
      prefs.setString('${prefix}province', value.province ?? ''),
      prefs.setStringList('${prefix}topics', value.topics.toList()),
      prefs.setString('${prefix}goal', value.learningGoal?.name ?? ''),
      prefs.setString('${prefix}avatar', value.avatarId ?? ''),
      prefs.setString('${prefix}username', value.username ?? ''),
      prefs.setString('${prefix}bio', value.bio),
      prefs.setStringList('${prefix}interests', value.interests.toList()),
      prefs.setBool('${prefix}complete', value.isComplete),
    ]);
  }
}

final profileSetupProvider = AsyncNotifierProvider<ProfileSetupNotifier, ProfileSetupState>(
  ProfileSetupNotifier.new,
);
