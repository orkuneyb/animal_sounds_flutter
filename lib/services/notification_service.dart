import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Returns the next time the clock shows [hour]:[minute] on this device,
/// strictly after [now].
DateTime nextLocalInstanceOf(DateTime now, int hour, int minute) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  if (today.isAfter(now)) return today;
  return DateTime(now.year, now.month, now.day + 1, hour, minute);
}

/// Whether the first-launch parent dialog should offer the daily reminder.
///
/// Shown once per install (tracked by [offerShown]) and skipped entirely for
/// users who already turned reminders on in Settings.
bool shouldShowReminderOffer({
  required bool offerShown,
  required bool dailyReminderEnabled,
}) =>
    !offerShown && !dailyReminderEnabled;

/// Singleton service for managing local notifications.
///
/// Handles daily reminders ("Gunun hayvani seni bekliyor!") and streak
/// reminders, scheduled against the device's local clock.
class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  static const int _dailyReminderId = 1001;
  static const int _streakReminderId = 1002;

  static const String _prefDailyEnabled = 'notification_daily_enabled';
  static const String _prefDailyHour = 'notification_daily_hour';
  static const String _prefDailyMinute = 'notification_daily_minute';
  static const String _prefStreakEnabled = 'notification_streak_enabled';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // Permission request (mainly for iOS / Android 13+)
  // ---------------------------------------------------------------------------

  Future<bool> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    // iOS permissions are handled via initialization settings
    return true;
  }

  // ---------------------------------------------------------------------------
  // Daily reminder
  // ---------------------------------------------------------------------------

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await _ensureInitialized();

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'app_name'.tr(),
      'daily_reminder_body'.tr(),
      _nextInstanceOf(time.hour, time.minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'Daily animal learning reminder',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Persist preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDailyEnabled, true);
    await prefs.setInt(_prefDailyHour, time.hour);
    await prefs.setInt(_prefDailyMinute, time.minute);
  }

  Future<void> cancelDailyReminder() async {
    await _ensureInitialized();
    await _plugin.cancel(_dailyReminderId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDailyEnabled, false);
  }

  // ---------------------------------------------------------------------------
  // Streak reminder (evening notification)
  // ---------------------------------------------------------------------------

  Future<void> scheduleStreakReminder() async {
    await _ensureInitialized();

    await _plugin.zonedSchedule(
      _streakReminderId,
      'app_name'.tr(),
      'streak_reminder_body'.tr(),
      _nextInstanceOf(20, 0), // 8 PM — evening reminder
      NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_reminder',
          'Streak Reminder',
          channelDescription: 'Reminder to keep your learning streak alive',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefStreakEnabled, true);
  }

  Future<void> cancelStreakReminder() async {
    await _ensureInitialized();
    await _plugin.cancel(_streakReminderId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefStreakEnabled, false);
  }

  // ---------------------------------------------------------------------------
  // Reschedule on app start
  // ---------------------------------------------------------------------------

  /// Re-schedules the reminders the user has enabled so their text follows
  /// the current language and their time follows the device clock.
  ///
  /// Must be called after translations are loaded.
  Future<void> rescheduleEnabledReminders() async {
    if (await isDailyReminderEnabled()) {
      await scheduleDailyReminder(await getDailyReminderTime());
    }
    if (await isStreakReminderEnabled()) {
      await scheduleStreakReminder();
    }
  }

  // ---------------------------------------------------------------------------
  // Cancel all
  // ---------------------------------------------------------------------------

  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDailyEnabled, false);
    await prefs.setBool(_prefStreakEnabled, false);
  }

  // ---------------------------------------------------------------------------
  // Preference getters (for restoring UI state)
  // ---------------------------------------------------------------------------

  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefDailyEnabled) ?? false;
  }

  Future<TimeOfDay> getDailyReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_prefDailyHour) ?? 10;
    final minute = prefs.getInt(_prefDailyMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<bool> isStreakReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefStreakEnabled) ?? false;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  /// The plugin needs a zoned time; the instant is taken from the device's
  /// local clock, so no timezone database has to be loaded.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    return tz.TZDateTime.from(
      nextLocalInstanceOf(DateTime.now(), hour, minute),
      tz.UTC,
    );
  }
}
