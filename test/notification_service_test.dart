import 'package:animal_sounds_flutter/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late List<MethodCall> calls;

  setUp(() {
    // The test host is not Android, so the plugin does not pick its platform
    // implementation by itself.
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'initialize') return true;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  List<int> idsOf(String method) => calls
      .where((c) => c.method == method)
      .map((c) => (c.arguments as Map)['id'] as int)
      .toList();

  test('rescheduleEnabledReminders cancels reminders that are not enabled', () async {
    // A 1.3.0 user could end up with an alarm set but the cache write failed;
    // startup must clear such stray alarms so they never fire with bad data.
    SharedPreferences.setMockInitialValues({
      'notification_daily_enabled': false,
      'notification_streak_enabled': false,
    });

    await NotificationService().rescheduleEnabledReminders();

    expect(idsOf('cancel'), containsAll([1001, 1002]));
    expect(idsOf('zonedSchedule'), isEmpty);
  });

  test('rescheduleEnabledReminders schedules enabled reminders and cancels the rest',
      () async {
    SharedPreferences.setMockInitialValues({
      'notification_daily_enabled': true,
      'notification_daily_hour': 18,
      'notification_daily_minute': 0,
      'notification_streak_enabled': false,
    });

    await NotificationService().rescheduleEnabledReminders();

    expect(idsOf('zonedSchedule'), [1001]);
    expect(idsOf('cancel'), [1002]);
  });
}
