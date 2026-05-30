import 'package:flutter_test/flutter_test.dart';
import 'package:habit_fable/data/habit/habit_repository.dart';

void main() {
  group('HabitRepository date helpers', () {
    test('dateStringFromEpochMs uses local calendar date', () {
      final local = DateTime(2026, 5, 30, 23, 50);
      final epochMs = local.millisecondsSinceEpoch;

      expect(
        HabitRepository.dateStringFromEpochMs(epochMs),
        HabitRepository.dateStringFrom(local),
      );
    });

    test('localDateFromEpochMs returns local midnight', () {
      final local = DateTime(2026, 5, 31, 0, 10);
      final epochMs = local.millisecondsSinceEpoch;

      final recordDate = HabitRepository.localDateFromEpochMs(epochMs);

      expect(recordDate.year, 2026);
      expect(recordDate.month, 5);
      expect(recordDate.day, 31);
      expect(recordDate.hour, 0);
      expect(recordDate.minute, 0);
    });

    test('dateStringFrom normalizes date-only values', () {
      final d = DateTime(2026, 1, 5);
      expect(HabitRepository.dateStringFrom(d), '2026-01-05');
    });
  });
}
