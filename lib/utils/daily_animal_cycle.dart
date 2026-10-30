import 'dart:math';

/// Picks the animal of the day so that every animal appears exactly once per
/// cycle of [length] days and no two consecutive days share an animal.
///
/// Stateless and deterministic: the same day number always maps to the same
/// index on every device. Requires [length] >= 3.
class DailyAnimalCycle {
  const DailyAnimalCycle(this.length);

  /// Number of animals, which is also the cycle length in days.
  final int length;

  /// Days since 1970-01-01 for the calendar date of [date], using UTC
  /// construction so daylight-saving changes cannot skip or repeat a day.
  static int dayNumber(DateTime date) {
    final utcMidnight = DateTime.utc(date.year, date.month, date.day);
    return utcMidnight.difference(DateTime.utc(1970)).inDays;
  }

  int indexForDay(int dayNumber) {
    final cycle = dayNumber ~/ length;
    final position = dayNumber % length;
    return _permutation(cycle)[position];
  }

  /// The shuffled order for [cycle], adjusted so its first animal differs
  /// from the previous cycle's last animal.
  List<int> _permutation(int cycle) {
    final order = _shuffled(cycle);
    if (cycle > 0 && order.first == _shuffled(cycle - 1).last) {
      final first = order[0];
      order[0] = order[1];
      order[1] = first;
    }
    return order;
  }

  List<int> _shuffled(int cycle) =>
      List<int>.generate(length, (i) => i)..shuffle(Random(cycle));
}
