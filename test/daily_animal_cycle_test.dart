import 'package:animal_sounds_flutter/utils/daily_animal_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cycle = DailyAnimalCycle(30);

  test('30 consecutive days from a cycle start show 30 different animals', () {
    final seen = {for (var day = 60; day < 90; day++) cycle.indexForDay(day)};

    expect(seen, hasLength(30));
  });

  test('30 consecutive days starting mid-cycle never repeat within a cycle', () {
    // days 75..89 belong to cycle 2, days 90..104 to cycle 3
    final firstHalf = {for (var day = 75; day < 90; day++) cycle.indexForDay(day)};
    final secondHalf = {for (var day = 90; day < 105; day++) cycle.indexForDay(day)};

    expect(firstHalf, hasLength(15));
    expect(secondHalf, hasLength(15));
  });

  test('consecutive days never share an animal across 200 cycle boundaries', () {
    for (var boundary = 1; boundary <= 200; boundary++) {
      final day = boundary * 30;
      expect(
        cycle.indexForDay(day),
        isNot(cycle.indexForDay(day - 1)),
        reason: 'boundary at day $day repeats yesterday\'s animal',
      );
    }
  });

  test('every index stays inside the animal list', () {
    for (var day = 0; day < 3000; day++) {
      expect(cycle.indexForDay(day), inInclusiveRange(0, 29));
    }
  });

  test('the same day always gives the same animal', () {
    expect(cycle.indexForDay(12345), cycle.indexForDay(12345));
  });

  group('dayNumber', () {
    test('counts days since 1970-01-01 regardless of the time of day', () {
      expect(DailyAnimalCycle.dayNumber(DateTime(1970, 1, 1, 23, 59)), 0);
      expect(DailyAnimalCycle.dayNumber(DateTime(1970, 1, 2, 0, 1)), 1);
    });

    test('consecutive dates across a year boundary differ by exactly one', () {
      final dec31 = DailyAnimalCycle.dayNumber(DateTime(2026, 12, 31));
      final jan1 = DailyAnimalCycle.dayNumber(DateTime(2027, 1, 1));

      expect(jan1 - dec31, 1);
    });

    test('consecutive dates across the March DST change differ by exactly one', () {
      // Local midnights may be 23 or 25 hours apart; the day number must not care.
      final before = DailyAnimalCycle.dayNumber(DateTime(2026, 3, 29));
      final after = DailyAnimalCycle.dayNumber(DateTime(2026, 3, 30));

      expect(after - before, 1);
    });
  });
}
