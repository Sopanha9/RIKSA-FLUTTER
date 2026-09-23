import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/mascot/providers/buddy_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists the learner buddy reaction preference', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(buddyReactionsEnabledProvider.notifier)
        .setEnabled(true);

    expect(container.read(buddyReactionsEnabledProvider), isTrue);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(BuddyPreferencesNotifier.storageKey),
      isTrue,
    );
  });

  test('an in-session choice wins over a late restore', () async {
    SharedPreferences.setMockInitialValues({
      BuddyPreferencesNotifier.storageKey: true,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(buddyReactionsEnabledProvider.notifier)
        .setEnabled(false);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(buddyReactionsEnabledProvider), isFalse);
  });
}
