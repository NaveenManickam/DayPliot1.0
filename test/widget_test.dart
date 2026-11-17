import 'package:flutter_test/flutter_test.dart';
import 'package:daypilot/utils/app_strings.dart';

void main() {
  group('DayPilot translations', () {
    test('main navigation labels are translated to Tamil', () {
      expect(AppStrings.translate('My Day', 'Tamil'), 'எனது நாள்');
      expect(AppStrings.translate('My Planner', 'Tamil'), 'எனது திட்டமிடல்');
      expect(AppStrings.translate('My Progress', 'Tamil'), 'எனது முன்னேற்றம்');
    });

    test('English labels remain unchanged', () {
      expect(AppStrings.translate('My Day', 'English'), 'My Day');
    });

    test('unknown phrases safely fall back to the source text', () {
      expect(AppStrings.translate('A custom user note', 'Tamil'), 'A custom user note');
    });
  });
}
