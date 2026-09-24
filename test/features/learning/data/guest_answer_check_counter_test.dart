import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/learning/data/guest_answer_check_counter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('stores guest checks across lessons', () async {
    SharedPreferences.setMockInitialValues({});
    final counter = GuestAnswerCheckCounter();

    expect(await counter.count(), 0);
    expect(await counter.recordCheck(), 1);
    expect(await counter.recordCheck(), 2);

    final restored = GuestAnswerCheckCounter();
    expect(await restored.count(), 2);
  });

  test('keeps an in-memory count when local storage throws', () async {
    final counter = GuestAnswerCheckCounter(
      preferencesLoader: () async => throw StateError('storage unavailable'),
    );

    expect(await counter.recordCheck(), 1);
    expect(await counter.count(), 1);
    expect(await counter.recordCheck(), 2);
  });
}
