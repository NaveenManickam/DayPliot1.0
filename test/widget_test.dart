import 'package:flutter_test/flutter_test.dart';
import 'package:daypilot/utils/app_strings.dart';
import 'package:daypilot/providers/app_controller.dart';

void main() {
  group('Time-based greeting', () {
    test('uses the expected greeting across all day periods', () {
      expect(AppController.greetingForHour(0), 'Good Night');
      expect(AppController.greetingForHour(4), 'Good Night');
      expect(AppController.greetingForHour(5), 'Good Morning');
      expect(AppController.greetingForHour(11), 'Good Morning');
      expect(AppController.greetingForHour(12), 'Good Afternoon');
      expect(AppController.greetingForHour(16), 'Good Afternoon');
      expect(AppController.greetingForHour(17), 'Good Evening');
      expect(AppController.greetingForHour(20), 'Good Evening');
      expect(AppController.greetingForHour(21), 'Good Night');
      expect(AppController.greetingForHour(23), 'Good Night');
    });
  });

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
