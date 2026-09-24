import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/riksa_app.dart';
import 'core/notifications/streak_reminder_provider.dart';
import 'core/providers/locale_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/mascot/domain/mascot.dart';
import 'features/mascot/providers/mascot_provider.dart';
import 'features/userProfile/providers/profile_provider.dart';
import 'l10n/gen/app_localizations.dart';

final List<Object> _startupSubscriptions = [];
Future<void> _reminderRescheduleQueue = Future<void>.value();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(container: container, child: const RiksaApp()),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    void queueReschedule() {
      _reminderRescheduleQueue = _reminderRescheduleQueue.then(
        (_) => _rescheduleExistingReminder(container),
      );
    }

    _startupSubscriptions.add(
      container.listen<AuthState>(authProvider, (_, state) {
        if (state is Authenticated) queueReschedule();
      }, fireImmediately: true),
    );
    _startupSubscriptions.add(
      container.listen<MascotState>(mascotProvider, (_, state) {
        if (state.isReady && container.read(authProvider) is Authenticated) {
          queueReschedule();
        }
      }),
    );
  });
}

Future<void> _rescheduleExistingReminder(ProviderContainer container) async {
  try {
    final service = container.read(streakReminderServiceProvider);
    if (!await service.isEnabled() ||
        !await service.hasNotificationPermission()) {
      return;
    }

    final buddy = container.read(mascotProvider).profile;
    final buddyName =
        buddy?.name ?? MascotProfile.defaultName(MascotSpecies.crocodile);
    var streak = 0;
    try {
      streak = (await container.read(
        profileDashboardProvider.future,
      )).gamification.currentStreak;
    } catch (_) {
      // A cached local reminder should still be rescheduled when the profile
      // endpoint is temporarily unavailable.
    }
    final l10n = await AppLocalizations.delegate.load(
      container.read(localeProvider).locale,
    );
    await service.rescheduleIfEnabled(
      title: streak > 0
          ? l10n.reminderNotificationTitle(buddyName, streak)
          : l10n.reminderNotificationTitleNoStreak(buddyName),
      body: l10n.reminderNotificationBody,
    );
  } catch (error) {
    debugPrint('Streak reminder startup scheduling failed: $error');
  }
}
