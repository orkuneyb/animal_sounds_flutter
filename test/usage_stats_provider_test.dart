import 'package:animal_sounds_flutter/providers/usage_stats_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an app open counted at startup survives the initial load', () async {
    SharedPreferences.setMockInitialValues({'stats_app_opens': 4});
    final stats = UsageStatsProvider();

    // Called immediately, before the saved values have been read.
    await stats.incrementAppOpens();

    expect(stats.appOpens, 5);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('stats_app_opens'), 5);
  });
}
