import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/notifications/streak_reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class _FakeReminderPlatform implements StreakReminderPlatform {
  bool enabled = true;
  bool failInitialization = false;
  bool permissionGranted = false;
  int permissionRequests = 0;
  int? scheduledId;
  String? scheduledTitle;
  String? scheduledBody;
  tz.TZDateTime? scheduledDate;
  int? canceledId;

  @override
  Future<bool> areNotificationsEnabled() async => permissionGranted;

  @override
  Future<void> cancel({required int id}) async => canceledId = id;

  @override
  Future<void> initialize() async {
    if (failInitialization) throw StateError('notification plugin unavailable');
  }

  @override
  Future<String> localTimezoneIdentifier() async => 'Asia/Phnom_Penh';

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    permissionGranted = enabled;
    return permissionGranted;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime date,
  }) async {
    scheduledId = id;
    scheduledTitle = title;
    scheduledBody = body;
    scheduledDate = date;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tz.setLocalLocation(tz.getLocation('Asia/Phnom_Penh'));
  });

  group('StreakReminderService', () {
    test('calculates the next 8 PM in Asia/Phnom_Penh', () async {
      final service = StreakReminderService(
        platform: _FakeReminderPlatform(),
        now: () => DateTime.utc(2026, 9, 24, 12, 59),
      );

      final next = service.calculateNextInstance();

      expect(next.location.name, 'Asia/Phnom_Penh');
      expect(
        (next.year, next.month, next.day, next.hour, next.minute),
        (2026, 9, 24, 20, 0),
      );
    });

    test('moves the reminder to tomorrow after a completed lesson', () async {
      final platform = _FakeReminderPlatform()..permissionGranted = true;
      final service = StreakReminderService(
        platform: platform,
        now: () => DateTime.utc(2026, 9, 24, 12, 30),
      );

      await service.recordLessonCompleted(
        title: 'Croco: your 5-day streak ends tonight',
        body: 'Finish one lesson to keep it alive.',
      );

      expect(
        platform.scheduledId,
        StreakReminderService.streakReminderNotificationId,
      );
      expect(platform.scheduledDate?.location.name, 'Asia/Phnom_Penh');
      expect(
        (
          platform.scheduledDate?.year,
          platform.scheduledDate?.month,
          platform.scheduledDate?.day,
          platform.scheduledDate?.hour,
        ),
        (2026, 9, 25, 20),
      );
    });

    test(
      'notification plugin failure never blocks a completed lesson',
      () async {
        final platform = _FakeReminderPlatform()..failInitialization = true;
        final service = StreakReminderService(platform: platform);

        await expectLater(
          service.recordLessonCompleted(title: 'Buddy', body: 'Study tonight.'),
          completes,
        );
        expect(platform.scheduledDate, isNull);
      },
    );

    test(
      'startup and settings never request permission before a lesson',
      () async {
        final platform = _FakeReminderPlatform()..permissionGranted = false;
        final service = StreakReminderService(platform: platform);

        await service.initialize();
        await service.rescheduleIfEnabled(
          title: 'Buddy',
          body: 'Study tonight.',
        );
        await service.setEnabled(true, title: 'Buddy', body: 'Study tonight.');

        expect(platform.permissionRequests, 0);
        expect(platform.scheduledDate, isNull);
      },
    );

    test('permission prompt cooldown lasts seven days', () async {
      final platform = _FakeReminderPlatform();
      var now = DateTime.utc(2026, 9, 24, 12);
      final service = StreakReminderService(platform: platform, now: () => now);

      expect(await service.shouldShowPermissionPromptAfterLesson(), isTrue);
      await service.markPermissionPromptShown();
      now = now.add(const Duration(days: 6, hours: 23));
      expect(await service.shouldShowPermissionPromptAfterLesson(), isFalse);
      now = now.add(const Duration(hours: 1));
      expect(await service.shouldShowPermissionPromptAfterLesson(), isTrue);
    });

    test('cancel removes the scheduled notification', () async {
      final platform = _FakeReminderPlatform();
      final service = StreakReminderService(platform: platform);

      await service.cancelStreakReminder();

      expect(
        platform.canceledId,
        StreakReminderService.streakReminderNotificationId,
      );
    });
  });
}
