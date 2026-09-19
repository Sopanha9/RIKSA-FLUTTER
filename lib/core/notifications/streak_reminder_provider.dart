import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'streak_reminder_service.dart';

final streakReminderServiceProvider = Provider<StreakReminderService>((ref) {
  return StreakReminderService();
});

class StreakReminderNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final service = ref.watch(streakReminderServiceProvider);
    return service.isEnabled();
  }

  Future<void> toggle({
    required bool enabled,
    String? title,
    String? body,
    int hour = 20,
    int minute = 0,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(streakReminderServiceProvider);
      await service.setEnabled(
        enabled,
        title: title,
        body: body,
        hour: hour,
        minute: minute,
      );
      return enabled;
    });
  }
}

final streakReminderStateProvider =
    AsyncNotifierProvider<StreakReminderNotifier, bool>(
  StreakReminderNotifier.new,
);
