import 'package:flutter_test/flutter_test.dart';
import 'package:daypilot/utils/app_strings.dart';

void main() {
  group('AppStrings', () {
    test('returns English labels by default', () {
      final strings = AppStrings('English');

      expect(strings.call('my_day'), 'My Day');
      expect(strings.call('planner'), 'My Planner');
      expect(strings.call('notes'), 'My Notes');
    });

    test('returns Tamil labels when Tamil is selected', () {
      final strings = AppStrings('Tamil');

      expect(strings.call('my_day'), 'எனது நாள்');
      expect(strings.call('notes'), 'குறிப்புகள்');
    });

    test('falls back to the key for unknown labels', () {
      final strings = AppStrings('English');

      expect(strings.call('unknown_label'), 'unknown_label');
    });
  });
}
