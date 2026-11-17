import 'package:flutter_test/flutter_test.dart';
import 'package:daypilot/utils/date_helpers.dart';

void main() {
  group('Date helpers', () {
    test('month grid always contains six complete Monday-first weeks', () {
      final days = monthGrid(DateTime(2026, 11, 17));
      expect(days, hasLength(42));
      expect(days.first.weekday, DateTime.monday);
      expect(days.last.weekday, DateTime.sunday);
      expect(days.any((d) => d.year == 2026 && d.month == 11 && d.day == 17), isTrue);
    });

    test('weekDays starts on Monday and ends on Sunday', () {
      final days = weekDays(DateTime(2026, 11, 17));
      expect(days, hasLength(7));
      expect(days.first.weekday, DateTime.monday);
      expect(days.last.weekday, DateTime.sunday);
    });

    test('sameDate ignores time', () {
      expect(sameDate(DateTime(2026, 11, 17, 8), DateTime(2026, 11, 17, 23)), isTrue);
    });
  });
}
