# Task
Make the daily streak reminder actually fire on Android and iOS, in the buddy's voice.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER, Flutter + Riverpod + flutter_local_notifications ^22.3.0.

# Relevant files
- lib/core/notifications/streak_reminder_service.dart — the service; schedules at 20:00 via zonedSchedule
- lib/features/userProfile/presentation/profile_settings_screen.dart (~lines 167, 331) — the only caller today (the toggle)
- lib/main.dart — app start
- android/app/src/main/AndroidManifest.xml — no notification permission or receivers today
- android/app/build.gradle(.kts) — coreLibraryDesugaring is already enabled
- ios/Runner/AppDelegate.swift, ios/Runner/Info.plist
- lib/features/learning/presentation/lesson_experience_screen.dart — `_complete()` finishes a lesson

# Context
Three verified bugs:
1. The reminder is only scheduled when the settings toggle is flipped. It defaults to "on" but nothing schedules it at startup, so it never fires.
2. No POST_NOTIFICATIONS permission in the manifest and no runtime request (Android 13+). No iOS permission request (requestAlertPermission etc. are all false).
3. `tz.local` is never set, so 20:00 is 20:00 UTC = 03:00 in Cambodia.

# Do
1. Add `flutter_timezone`; in `initialize()` call `tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()))`, falling back to `Asia/Phnom_Penh`.
2. Manifest: add POST_NOTIFICATIONS and RECEIVE_BOOT_COMPLETED, plus the plugin's ScheduledNotificationReceiver and ScheduledNotificationBootReceiver as documented for v22. Use `AndroidScheduleMode.inexactAllowWhileIdle`; do NOT require SCHEDULE_EXACT_ALARM.
3. Add `Future<bool> requestPermission()` (Android `requestNotificationsPermission`; iOS `requestPermissions(alert, badge, sound)`). Ask at a moment of value: right after the learner's FIRST completed lesson, with a small in-app explainer sheet first ("Want me to remind you so your streak doesn't die?"), never at app start. If declined, don't ask again for 7 days.
4. At app start (after the first frame, non-blocking): if enabled and permitted, (re)schedule.
5. After a lesson is completed, reschedule so today's reminder is skipped and the next is tomorrow 20:00.
6. Text from l10n in en and km, written as the buddy speaking, using the buddy's name from `mascotProvider` (e.g. "Croco: your 5-day streak ends tonight 😢").
7. Tests in test/core/notifications/: next-instance time in Asia/Phnom_Penh, skip-today after completion, no permission request before the first lesson. Put the plugin behind a small interface to fake it.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify files outside: lib/core/notifications/**, lib/main.dart (startup call only), android/app/src/main/AndroidManifest.xml, ios/Runner/**, pubspec.yaml, pubspec.lock, lib/l10n/**, lib/features/learning/presentation/lesson_experience_screen.dart (one hook in `_complete`), lib/features/userProfile/presentation/profile_settings_screen.dart, test/core/notifications/**.
- Do not touch the bottom navigation bar.
- Do not add dependencies other than flutter_timezone without stating so.

# Deliverable
Changed files, real output of `flutter analyze` and `flutter test test/core`, and exact manual steps to verify on an Android 13+ device.

# Risks
End with a "## Risks" section: anything unsure, unverified, or out of scope.
