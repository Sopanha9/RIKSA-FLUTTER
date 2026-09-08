import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class StreakReminderService {
  StreakReminderService({
    FlutterLocalNotificationsPlugin? plugin,
    SharedPreferences? prefs,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _injectedPrefs = prefs;

  final FlutterLocalNotificationsPlugin _plugin;
  SharedPreferences? _injectedPrefs;

  Future<SharedPreferences> _getPrefs() async {
    return _injectedPrefs ??= await SharedPreferences.getInstance();
  }

  static const int streakReminderNotificationId = 8001;
  static const String streakChannelId = 'daily_streak_reminders';
  static const String streakChannelName = 'Daily Streak Reminders';
  static const String streakChannelDesc =
      'Daily 8:00 PM reminders to protect your learning streak and daily habit.';

  static const String _prefEnabledKey = 'daily_streak_reminder_enabled';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {
      // Timezone may already be initialized or unavailable in test environment.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  Future<bool> isEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_prefEnabledKey) ?? true;
  }

  Future<void> setEnabled(
    bool enabled, {
    String? title,
    String? body,
    int hour = 20,
    int minute = 0,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_prefEnabledKey, enabled);
    if (enabled) {
      await scheduleDailyStreakReminder(
        title: title ?? '🔥 Keep your learning streak alive!',
        body: body ??
            'Take 5 minutes tonight to practice Khmer, Math, or Science and protect your streak.',
        hour: hour,
        minute: minute,
      );
    } else {
      await cancelStreakReminder();
    }
  }

  tz.TZDateTime calculateNextInstance({int hour = 20, int minute = 0}) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> scheduleDailyStreakReminder({
    required String title,
    required String body,
    int hour = 20,
    int minute = 0,
  }) async {
    await initialize();

    final scheduledDate = calculateNextInstance(hour: hour, minute: minute);

    const androidDetails = AndroidNotificationDetails(
      streakChannelId,
      streakChannelName,
      channelDescription: streakChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _plugin.zonedSchedule(
        id: streakReminderNotificationId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('StreakReminderService: scheduling notification failed: $e');
    }
  }

  Future<void> cancelStreakReminder() async {
    await initialize();
    try {
      await _plugin.cancel(id: streakReminderNotificationId);
    } catch (e) {
      debugPrint('StreakReminderService: cancel notification failed: $e');
    }
  }
}
