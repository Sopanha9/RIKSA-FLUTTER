import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract interface class StreakReminderPlatform {
  Future<void> initialize();
  Future<String> localTimezoneIdentifier();
  Future<bool> requestPermission();
  Future<bool> areNotificationsEnabled();
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime date,
  });
  Future<void> cancel({required int id});
}

class FlutterStreakReminderPlatform implements StreakReminderPlatform {
  FlutterStreakReminderPlatform({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
    );
  }

  @override
  Future<String> localTimezoneIdentifier() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return status?.isEnabled ?? false;
    }
    return false;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime date,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        StreakReminderService.streakChannelId,
        StreakReminderService.streakChannelName,
        channelDescription: StreakReminderService.streakChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: date,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel({required int id}) => _plugin.cancel(id: id);
}

class StreakReminderService {
  StreakReminderService({
    StreakReminderPlatform? platform,
    SharedPreferences? prefs,
    DateTime Function()? now,
  }) : _platform = platform ?? FlutterStreakReminderPlatform(),
       _injectedPrefs = prefs,
       _now = now ?? DateTime.now;

  final StreakReminderPlatform _platform;
  final DateTime Function() _now;
  SharedPreferences? _injectedPrefs;
  bool _initialized = false;
  bool _platformAvailable = true;
  Future<void>? _initialization;

  static const int streakReminderNotificationId = 8001;
  static const String streakChannelId = 'daily_streak_reminders';
  static const String streakChannelName = 'Daily Streak Reminders';
  static const String streakChannelDesc =
      'Daily 8:00 PM reminders to protect your learning streak and daily habit.';
  static const String _prefEnabledKey = 'daily_streak_reminder_enabled';
  static const String _prefPromptShownAtKey =
      'daily_streak_reminder_permission_prompt_shown_at';
  static const String _prefLastLessonDateKey =
      'daily_streak_reminder_last_lesson_date';
  static const fallbackTimezone = 'Asia/Phnom_Penh';
  static const permissionPromptCooldown = Duration(days: 7);
  static const reminderHour = 20;

  Future<SharedPreferences?> _getPrefs() async {
    if (_injectedPrefs != null) return _injectedPrefs;
    try {
      return _injectedPrefs = await SharedPreferences.getInstance();
    } catch (error) {
      debugPrint('StreakReminderService: preferences unavailable: $error');
      return null;
    }
  }

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    return _initialization ??= _initialize().whenComplete(() {
      _initialization = null;
    });
  }

  Future<void> _initialize() async {
    try {
      tz_data.initializeTimeZones();
    } catch (_) {
      // The database can already be initialized by another service.
    }

    try {
      final identifier = await _platform.localTimezoneIdentifier();
      tz.setLocalLocation(tz.getLocation(identifier));
    } catch (error) {
      debugPrint('StreakReminderService: using Phnom Penh timezone: $error');
      tz.setLocalLocation(tz.getLocation(fallbackTimezone));
    }

    try {
      await _platform.initialize();
    } catch (error) {
      // An unavailable notification plugin must not interrupt lesson completion.
      _platformAvailable = false;
      debugPrint('StreakReminderService: initialization failed: $error');
    }
    _initialized = true;
  }

  Future<bool> isEnabled() async {
    final prefs = await _getPrefs();
    return prefs?.getBool(_prefEnabledKey) ?? true;
  }

  Future<bool> hasNotificationPermission() async {
    try {
      await initialize();
      if (!_platformAvailable) return false;
      return await _platform.areNotificationsEnabled();
    } catch (error) {
      debugPrint('StreakReminderService: permission check failed: $error');
      return false;
    }
  }

  Future<bool> canRequestPermission() async {
    try {
      await initialize();
      return _platformAvailable;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      await initialize();
      if (!_platformAvailable) return false;
      return await _platform.requestPermission();
    } catch (error) {
      debugPrint('StreakReminderService: permission request failed: $error');
      return false;
    }
  }

  Future<void> setEnabled(
    bool enabled, {
    String? title,
    String? body,
    int hour = reminderHour,
    int minute = 0,
  }) async {
    final prefs = await _getPrefs();
    try {
      await prefs?.setBool(_prefEnabledKey, enabled);
    } catch (error) {
      debugPrint('StreakReminderService: could not save preference: $error');
    }
    if (enabled) {
      await rescheduleIfEnabled(
        title: title ?? '',
        body: body ?? '',
        hour: hour,
        minute: minute,
      );
    } else {
      await cancelStreakReminder();
    }
  }

  Future<bool> shouldShowPermissionPromptAfterLesson() async {
    final prefs = await _getPrefs();
    final shownAt = prefs?.getInt(_prefPromptShownAtKey);
    if (shownAt == null) return true;
    final elapsed = _now().difference(
      DateTime.fromMillisecondsSinceEpoch(shownAt),
    );
    return elapsed >= permissionPromptCooldown;
  }

  Future<void> markPermissionPromptShown() async {
    final prefs = await _getPrefs();
    try {
      await prefs?.setInt(_prefPromptShownAtKey, _now().millisecondsSinceEpoch);
    } catch (error) {
      debugPrint('StreakReminderService: could not save prompt time: $error');
    }
  }

  tz.TZDateTime calculateNextInstance({
    int hour = reminderHour,
    int minute = 0,
    DateTime? now,
    bool skipToday = false,
  }) {
    final current = tz.TZDateTime.from(now ?? _now(), tz.local);
    final scheduledToday = tz.TZDateTime(
      tz.local,
      current.year,
      current.month,
      current.day,
      hour,
      minute,
    );
    if (!skipToday && scheduledToday.isAfter(current)) return scheduledToday;
    final nextDay = DateTime(current.year, current.month, current.day + 1);
    return tz.TZDateTime(
      tz.local,
      nextDay.year,
      nextDay.month,
      nextDay.day,
      hour,
      minute,
    );
  }

  Future<void> scheduleDailyStreakReminder({
    required String title,
    required String body,
    int hour = reminderHour,
    int minute = 0,
    bool skipToday = false,
  }) async {
    try {
      await initialize();
      if (!await _platform.areNotificationsEnabled()) return;
      final prefs = await _getPrefs();
      final lastLessonDate = prefs?.getString(_prefLastLessonDateKey);
      final now = _now();
      final completedToday =
          lastLessonDate == _dateKey(tz.TZDateTime.from(now, tz.local));
      final scheduledDate = calculateNextInstance(
        hour: hour,
        minute: minute,
        now: now,
        skipToday: skipToday || completedToday,
      );
      await _platform.schedule(
        id: streakReminderNotificationId,
        title: title,
        body: body,
        date: scheduledDate,
      );
    } catch (error) {
      debugPrint(
        'StreakReminderService: scheduling notification failed: $error',
      );
    }
  }

  Future<void> rescheduleIfEnabled({
    required String title,
    required String body,
    int hour = reminderHour,
    int minute = 0,
  }) async {
    if (!await isEnabled()) return;
    await scheduleDailyStreakReminder(
      title: title,
      body: body,
      hour: hour,
      minute: minute,
    );
  }

  Future<void> recordLessonCompleted({
    required String title,
    required String body,
  }) async {
    await initialize();
    final prefs = await _getPrefs();
    try {
      await prefs?.setString(
        _prefLastLessonDateKey,
        _dateKey(tz.TZDateTime.from(_now(), tz.local)),
      );
    } catch (error) {
      debugPrint(
        'StreakReminderService: could not save completed date: $error',
      );
    }
    if (await isEnabled()) {
      await scheduleDailyStreakReminder(
        title: title,
        body: body,
        skipToday: true,
      );
    }
  }

  Future<void> cancelStreakReminder() async {
    try {
      await initialize();
      await _platform.cancel(id: streakReminderNotificationId);
    } catch (error) {
      debugPrint('StreakReminderService: cancel notification failed: $error');
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
