import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Singleton service for managing local notifications.
///
/// Handles daily reminders ("Gunun hayvani seni bekliyor!") and streak
/// reminders with timezone-aware scheduling.
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

    tz.initializeTimeZones();

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

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Animal Sounds',
      'daily_reminder_body', // Will be localized at display time on supported platforms
      scheduledDate,
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

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20, // 8 PM — evening reminder
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _streakReminderId,
      'Animal Sounds',
      'streak_reminder_body',
      scheduledDate,
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
}
