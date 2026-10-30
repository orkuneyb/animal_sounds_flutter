import 'package:animal_sounds_flutter/providers/daily_provider.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/services/analytics_service.dart';
import 'package:animal_sounds_flutter/utils/daily_animal_cycle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService().setBackend(null);
  });

  test("today's animal comes from the non-repeating cycle", () {
    final provider = DailyProvider();
    final expectedIndex = DailyAnimalCycle(AnimalRepository.animals.length)
        .indexForDay(DailyAnimalCycle.dayNumber(DateTime.now()));

    expect(provider.getDailyAnimal().index, expectedIndex);
  });

  test('completing the daily discovery logs the new streak', () async {
    final events = <(String, Map<String, Object>?)>[];
    AnalyticsService().setBackend((name, params) async => events.add((name, params)));
    final provider = DailyProvider();
    await Future<void>.delayed(Duration.zero); // let _init() load prefs

    await provider.completeDailyDiscovery();

    final event = events.where((e) => e.$1 == 'daily_discovery_completed');
    expect(event, hasLength(1));
    expect(event.single.$2, {'streak': 1});
  });
}
