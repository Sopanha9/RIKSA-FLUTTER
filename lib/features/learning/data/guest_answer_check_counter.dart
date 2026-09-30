import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final guestAnswerCheckCounterProvider = Provider<GuestAnswerCheckCounter>(
  (ref) => GuestAnswerCheckCounter(),
);

class GuestAnswerCheckCounter {
  GuestAnswerCheckCounter({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const _key = 'riksa_guest_answer_checks';

  final Future<SharedPreferences> Function() _preferencesLoader;
  int _fallbackCount = 0;

  Future<int> count() async {
    try {
      final storedCount = (await _preferencesLoader()).getInt(_key) ?? 0;
      _fallbackCount = storedCount > _fallbackCount
          ? storedCount
          : _fallbackCount;
      return _fallbackCount;
    } catch (_) {
      return _fallbackCount;
    }
  }

  Future<int> recordCheck() async {
    final count = await this.count() + 1;
    _fallbackCount = count;
    try {
      await (await _preferencesLoader()).setInt(_key, count);
    } catch (_) {
      // Guest answer checking stays available when local storage is not.
    }
    return count;
  }
}
