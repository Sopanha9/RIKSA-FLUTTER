import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/json_response.dart';
import '../../auth/providers/auth_provider.dart';
import '../../userProfile/providers/profile_provider.dart';

/// A one-time "get started" quest for a new account, e.g. verifying a phone.
class SetupTask {
  const SetupTask({
    required this.key,
    required this.title,
    required this.titleKm,
    required this.xpReward,
    required this.done,
    required this.claimed,
  });

  final String key;
  final String title;
  final String titleKm;
  final int xpReward;
  final bool done;
  final bool claimed;

  bool get claimable => done && !claimed;

  String titleFor(String languageCode) =>
      languageCode == 'km' && titleKm.trim().isNotEmpty ? titleKm : title;

  /// Where "Go" takes the learner to finish the step.
  String get destination => switch (key) {
    'VERIFY_PHONE' || 'WRITE_BIO' => '/profile/edit',
    'CHOOSE_PROVINCE' => '/province-select',
    'JOIN_COMMUNITY' => '/communities',
    'FIRST_POST' => '/community/create',
    _ => '/profile/edit',
  };

  factory SetupTask.fromJson(Map<String, dynamic> json) => SetupTask(
    key: json['key'] as String? ?? '',
    title: json['title'] as String? ?? '',
    titleKm: json['titleKm'] as String? ?? '',
    xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
    done: json['done'] as bool? ?? false,
    claimed: json['claimed'] as bool? ?? false,
  );
}

class SetupQuestsApi {
  SetupQuestsApi(this._client);

  final DioClient _client;

  Future<List<SetupTask>> list() async {
    final response = await _client.dio.get('/quests/setup');
    final data = response.data;
    return [
      for (final item in (data is List ? data : const []))
        if (item is Map) SetupTask.fromJson(item.cast<String, dynamic>()),
    ];
  }

  Future<SetupTask> claim(String key) async {
    final response = await _client.dio.post('/quests/setup/$key/claim');
    return SetupTask.fromJson(jsonMap(response));
  }
}

final setupQuestsApiProvider = Provider<SetupQuestsApi>(
  (ref) => SetupQuestsApi(ref.watch(dioClientProvider)),
);

/// The get-started quests; empty for guests and once every one is claimed.
class SetupQuestsNotifier extends AsyncNotifier<List<SetupTask>> {
  @override
  Future<List<SetupTask>> build() async {
    watchCurrentUserId(ref);
    // Rechecked when the profile changes (a bio, a verified phone, …).
    ref.watch(authProvider);
    if (ref.read(authProvider) is! Authenticated) return const [];
    try {
      return await ref.watch(setupQuestsApiProvider).list();
    } catch (_) {
      // Optional extras: a failed load (or a server without them yet) just
      // hides the section instead of retrying in the background.
      return const [];
    }
  }

  Future<void> claim(String key) async {
    final claimed = await ref.read(setupQuestsApiProvider).claim(key);
    final current = state.value ?? const <SetupTask>[];
    state = AsyncData([
      for (final task in current) task.key == key ? claimed : task,
    ]);
    // The XP totals and history just changed.
    ref.invalidate(profileDashboardProvider);
    ref.invalidate(xpHistoryProvider);
  }
}

final setupQuestsProvider =
    AsyncNotifierProvider<SetupQuestsNotifier, List<SetupTask>>(
      SetupQuestsNotifier.new,
    );
