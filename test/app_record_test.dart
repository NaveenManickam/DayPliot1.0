import 'package:flutter_test/flutter_test.dart';
import 'package:daypilot/models/app_record.dart';

void main() {
  group('AppRecord', () {
    final created = DateTime(2026, 11, 17, 9, 30);
    final record = AppRecord(
      id: 'test-record-1',
      type: 'task',
      date: DateTime(2026, 11, 17),
      title: 'Prepare daily plan',
      body: 'Review priorities',
      startAt: DateTime(2026, 11, 17, 10),
      done: true,
      meta: const {'priority': 'High', 'order': 2},
      createdAt: created,
      updatedAt: created,
    );

    test('JSON export and import preserve all fields', () {
      final restored = AppRecord.fromJson(record.toJson());
      expect(restored.id, record.id);
      expect(restored.type, record.type);
      expect(restored.date, record.date);
      expect(restored.title, record.title);
      expect(restored.body, record.body);
      expect(restored.startAt, record.startAt);
      expect(restored.done, isTrue);
      expect(restored.meta['priority'], 'High');
      expect(restored.meta['order'], 2);
      expect(restored.createdAt, created);
    });

    test('copyWith changes completion but retains identity and content', () {
      final updated = record.copyWith(done: false);
      expect(updated.id, record.id);
      expect(updated.title, record.title);
      expect(updated.done, isFalse);
    });

    test('copyWith can clear schedule timestamps', () {
      final updated = record.copyWith(clearStartAt: true);
      expect(updated.startAt, isNull);
    });
  });
}
