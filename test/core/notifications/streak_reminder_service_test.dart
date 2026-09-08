import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/notifications/streak_reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class _FakeNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  bool initialized = false;
  int? lastScheduledId;
  String? lastScheduledTitle;
  String? lastScheduledBody;
  int? lastCanceledId;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    initialized = true;
    return true;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    lastScheduledId = id;
    lastScheduledTitle = title;
    lastScheduledBody = body;
  }

  @override
  Future<void> cancel({
    required int id,
    String? tag,
  }) async {
    lastCanceledId = id;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('StreakReminderService', () {
    test('calculateNextInstance schedules for 8:00 PM', () {
      final service = StreakReminderService(
        plugin: _FakeNotificationsPlugin(),
      );

      final next = service.calculateNextInstance(hour: 20, minute: 0);
      expect(next.hour, 20);
      expect(next.minute, 0);
      expect(next.isAfter(tz.TZDateTime.now(tz.local)), isTrue);
    });

    test('scheduleDailyStreakReminder calls plugin with correct details', () async {
      final fakePlugin = _FakeNotificationsPlugin();
      SharedPreferences.setMockInitialValues({});
      final service = StreakReminderService(
        plugin: fakePlugin,
      );

      await service.scheduleDailyStreakReminder(
        title: '🔥 Keep your learning streak alive!',
        body: 'Take 5 minutes tonight to practice Khmer, Math, or Science.',
        hour: 20,
        minute: 0,
      );

      expect(fakePlugin.initialized, isTrue);
      expect(
        fakePlugin.lastScheduledId,
        StreakReminderService.streakReminderNotificationId,
      );
      expect(
        fakePlugin.lastScheduledTitle,
        '🔥 Keep your learning streak alive!',
      );
    });

    test('cancelStreakReminder calls plugin cancel', () async {
      final fakePlugin = _FakeNotificationsPlugin();
      SharedPreferences.setMockInitialValues({});
      final service = StreakReminderService(
        plugin: fakePlugin,
      );

      await service.cancelStreakReminder();

      expect(fakePlugin.initialized, isTrue);
      expect(
        fakePlugin.lastCanceledId,
        StreakReminderService.streakReminderNotificationId,
      );
    });

    test('setEnabled persists preference and updates schedule', () async {
      final fakePlugin = _FakeNotificationsPlugin();
      SharedPreferences.setMockInitialValues({});
      final service = StreakReminderService(
        plugin: fakePlugin,
      );

      await service.setEnabled(true, title: 'Keep streak');
      expect(await service.isEnabled(), isTrue);
      expect(fakePlugin.lastScheduledTitle, 'Keep streak');

      await service.setEnabled(false);
      expect(await service.isEnabled(), isFalse);
      expect(
        fakePlugin.lastCanceledId,
        StreakReminderService.streakReminderNotificationId,
      );
    });
  });
}
