import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_constants.dart';
import '../database/app_database.dart';
import '../models/app_record.dart';
import '../services/notification_service.dart';

class AppController extends ChangeNotifier {
  AppController({AppDatabase? database, NotificationService? notifications})
      : _database = database ?? AppDatabase(),
        _notifications = notifications ?? NotificationService();

  final AppDatabase _database;
  final NotificationService _notifications;
  SharedPreferences? _prefs;
  List<AppRecord> _records = [];
  bool _ready = false;
  String _name = '';
  String _theme = 'light';
  String _language = 'English';
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _pinSalt = '';
  String _pinHash = '';

  bool get isReady => _ready;
  List<AppRecord> get records => List.unmodifiable(_records);
  String get name => _name;
  String get theme => _theme;
  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get biometricEnabled => _biometricEnabled;
  bool get hasPin => _pinHash.isNotEmpty;

  ThemeMode get themeMode => switch (_theme) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };

  static const quotes = <String>[
    'Small steps every day create remarkable change.',
    'The secret of getting ahead is getting started.',
    'Discipline is choosing what you want most over what you want now.',
    'Great things are done by a series of small things brought together.',
    'Do what you can, with what you have, where you are.',
    'A little progress each day adds up to big results.',
    'The future depends on what you do today.',
    'Well begun is half done.',
    'Focus on progress, not perfection.',
    'Action is the foundational key to all success.',
    'Your habits shape your days, and your days shape your life.',
    'It always seems impossible until it is done.',
    'Make each day your masterpiece.',
    'Success is the sum of small efforts repeated day in and day out.',
    'Start where you are. Use what you have. Do what you can.',
    'You do not have to be perfect to make progress.',
    'The best way out is always through.',
    'One focused hour can change the direction of a day.',
  ];

  String get todayQuote {
    final now = DateTime.now();
    final dayNumber = DateTime(now.year, now.month, now.day)
        .difference(DateTime(2020, 1, 1))
        .inDays;
    return quotes[dayNumber.abs() % quotes.length];
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _name = _prefs?.getString('user_name') ?? '';
    _theme = _prefs?.getString('theme') ?? 'light';
    _language = _prefs?.getString('language') ?? 'English';
    _notificationsEnabled = _prefs?.getBool('notifications_enabled') ?? true;
    _biometricEnabled = _prefs?.getBool('biometric_enabled') ?? false;
    _pinSalt = _prefs?.getString('pin_salt') ?? '';
    _pinHash = _prefs?.getString('pin_hash') ?? '';
    await _notifications.initialize();
    _records = await _database.getAll();
    _ready = true;
    notifyListeners();
  }

  List<AppRecord> recordsOf(String type) =>
      _records.where((record) => record.type == type).toList();

  List<AppRecord> recordsForDate(DateTime date, {Set<String>? types}) {
    final day = DateTime(date.year, date.month, date.day);
    final matching = _records.where((record) {
      if (types != null && !types.contains(record.type)) return false;
      if (_sameDay(record.date, day)) return true;
      if (record.type == RecordType.event) {
        final recurrence = record.meta['recurrence'] as String? ?? 'none';
        if (recurrence == 'daily' && !day.isBefore(_dateOnly(record.date))) return true;
        if (recurrence == 'weekly' &&
            !day.isBefore(_dateOnly(record.date)) &&
            day.weekday == record.date.weekday) return true;
        if (recurrence == 'monthly' &&
            !day.isBefore(_dateOnly(record.date)) &&
            day.day == record.date.day) return true;
      }
      return false;
    }).toList();
    matching.sort((a, b) {
      final aTime = a.startAt ?? DateTime(a.date.year, a.date.month, a.date.day);
      final bTime = b.startAt ?? DateTime(b.date.year, b.date.month, b.date.day);
      return aTime.compareTo(bTime);
    });
    return matching;
  }

  List<AppRecord> get todayTasks => recordsForDate(DateTime.now(), types: {RecordType.task});
  List<AppRecord> get allHabits => recordsOf(RecordType.habit);
  List<AppRecord> get activeHabits =>
      allHabits.where((r) => r.meta['paused'] != true).toList();

  int get monthTaskCount => _records.where((record) {
        if (record.type != RecordType.task) return false;
        final now = DateTime.now();
        return record.date.year == now.year && record.date.month == now.month;
      }).length;

  int get completedToday => todayTasks.where((r) => r.done).length;
  int get pendingToday => todayTasks.where((r) => !r.done).length;

  Future<AppRecord> createRecord({
    required String type,
    required String title,
    String body = '',
    DateTime? date,
    DateTime? startAt,
    DateTime? endAt,
    bool done = false,
    Map<String, dynamic> meta = const {},
  }) async {
    final now = DateTime.now();
    final id = '${now.microsecondsSinceEpoch}${Random.secure().nextInt(9000) + 1000}';
    final recordMeta = Map<String, dynamic>.from(meta);
    if (type == RecordType.task) {
      recordMeta.putIfAbsent('order', () => recordsForDate(date ?? now, types: {RecordType.task}).length);
    }
    final record = AppRecord(
      id: id,
      type: type,
      date: _dateOnly(date ?? now),
      title: title.trim(),
      body: body.trim(),
      startAt: startAt,
      endAt: endAt,
      done: done,
      meta: recordMeta,
      createdAt: now,
      updatedAt: now,
    );
    await _save(record);
    return record;
  }

  Future<void> updateRecord(AppRecord record) async => _save(
        record.copyWith(updatedAt: DateTime.now()),
      );

  Future<void> _save(AppRecord record) async {
    await _database.upsert(record);
    _records.removeWhere((existing) => existing.id == record.id);
    _records.add(record);
    await _notifications.cancel(_notificationId(record.id));
    await _scheduleRecordReminder(record);
    notifyListeners();
  }

  Future<void> _scheduleRecordReminder(AppRecord record) async {
    final reminder = record.meta['reminderAt'];
    if (!_notificationsEnabled || record.done || reminder is! String) return;
    final at = DateTime.tryParse(reminder);
    if (at == null || !at.isAfter(DateTime.now())) return;
    await _notifications.schedule(
      id: _notificationId(record.id),
      title: record.title,
      body: record.body.isEmpty ? 'Reminder from DayPilot' : record.body,
      at: at,
    );
  }

  Future<void> deleteRecord(AppRecord record) async {
    final idsToDelete = <String>{record.id};
    if (record.type == RecordType.habit) {
      idsToDelete.addAll(_records
          .where((item) => item.type == RecordType.habitCheck && item.meta['habitId'] == record.id)
          .map((item) => item.id));
    }
    for (final id in idsToDelete) {
      await _database.delete(id);
      await _notifications.cancel(_notificationId(id));
    }
    _records.removeWhere((existing) => idsToDelete.contains(existing.id));
    notifyListeners();
  }

  Future<void> toggleTask(AppRecord task) async =>
      updateRecord(task.copyWith(done: !task.done));

  Future<void> reorderTasks(DateTime date, int oldIndex, int newIndex) async {
    final tasks = recordsForDate(date, types: {RecordType.task});
    tasks.sort((a, b) => (a.meta['order'] as int? ?? 999999).compareTo(b.meta['order'] as int? ?? 999999));
    if (newIndex > oldIndex) newIndex--;
    final item = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, item);
    for (var i = 0; i < tasks.length; i++) {
      await _save(tasks[i].copyWith(meta: {...tasks[i].meta, 'order': i}));
    }
  }

  Future<void> toggleHabit(AppRecord habit, [DateTime? onDate]) async {
    final day = _dateOnly(onDate ?? DateTime.now());
    final existing = _records.where((record) =>
        record.type == RecordType.habitCheck &&
        record.meta['habitId'] == habit.id &&
        _sameDay(record.date, day)).firstOrNull;
    if (existing != null) {
      await deleteRecord(existing);
    } else {
      await createRecord(
        type: RecordType.habitCheck,
        title: habit.title,
        date: day,
        meta: {'habitId': habit.id, 'completed': true},
      );
    }
  }

  bool habitDoneToday(AppRecord habit) => _records.any((record) =>
      record.type == RecordType.habitCheck &&
      record.meta['habitId'] == habit.id &&
      _sameDay(record.date, DateTime.now()));

  int habitStreak(AppRecord habit) {
    final completed = _habitDays(habit.id);
    if (completed.isEmpty) return 0;
    var cursor = _dateOnly(DateTime.now());
    if (_isPausedOn(habit, cursor)) return 0;
    if (!_isHabitScheduled(habit, cursor) || !completed.contains(_key(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (!cursor.isBefore(_dateOnly(habit.createdAt))) {
      if (_isPausedOn(habit, cursor)) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      if (_isHabitScheduled(habit, cursor)) {
        if (!completed.contains(_key(cursor))) break;
        streak++;
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int habitMissedDays(AppRecord habit, [DateTime? until]) {
    // A habit is not missed until its scheduled day has finished.
    final end = _dateOnly(until ?? DateTime.now().subtract(const Duration(days: 1)));
    final start = _dateOnly(habit.createdAt);
    final completed = _habitDays(habit.id);
    var missed = 0;
    var date = start;
    while (!date.isAfter(end)) {
      if (_isHabitScheduled(habit, date) &&
          !_isPausedOn(habit, date) &&
          !completed.contains(_key(date))) {
        missed++;
      }
      date = date.add(const Duration(days: 1));
    }
    return missed;
  }

  bool _isHabitScheduled(AppRecord habit, DateTime date) {
    final frequency = habit.meta['frequency'] as String? ?? 'Daily';
    if (frequency == 'Daily') return true;
    final days = (habit.meta['weekdays'] as List? ?? const [1, 2, 3, 4, 5, 6, 7])
        .whereType<num>()
        .map((value) => value.toInt())
        .toSet();
    return days.contains(date.weekday);
  }

  bool _isPausedOn(AppRecord habit, DateTime date) {
    final keyDate = _dateOnly(date);
    final activePause = habit.meta['pauseStartedAt'];
    if (habit.meta['paused'] == true && activePause is String) {
      final started = DateTime.tryParse(activePause);
      if (started != null && !keyDate.isBefore(_dateOnly(started))) return true;
    }
    final history = habit.meta['pauseHistory'];
    if (history is List) {
      for (final item in history.whereType<Map>()) {
        final start = DateTime.tryParse(item['start'] as String? ?? '');
        final end = DateTime.tryParse(item['end'] as String? ?? '');
        if (start != null && end != null &&
            !keyDate.isBefore(_dateOnly(start)) &&
            !keyDate.isAfter(_dateOnly(end))) return true;
      }
    }
    return false;
  }

  Future<void> toggleHabitPause(AppRecord habit) async {
    final meta = Map<String, dynamic>.from(habit.meta);
    if (meta['paused'] == true) {
      final started = DateTime.tryParse(meta['pauseStartedAt'] as String? ?? '');
      if (started != null) {
        final history = (meta['pauseHistory'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        history.add({
          'start': _dateOnly(started).toIso8601String(),
          'end': _dateOnly(DateTime.now()).toIso8601String(),
        });
        meta['pauseHistory'] = history;
      }
      meta['paused'] = false;
      meta.remove('pauseStartedAt');
    } else {
      meta['paused'] = true;
      meta['pauseStartedAt'] = _dateOnly(DateTime.now()).toIso8601String();
    }
    await updateRecord(habit.copyWith(meta: meta));
  }

  int longestHabitStreak(AppRecord habit) {
    final completed = _habitDays(habit.id);
    if (completed.isEmpty) return 0;
    var best = 0;
    var current = 0;
    var date = _dateOnly(habit.createdAt);
    final end = _dateOnly(DateTime.now());
    while (!date.isAfter(end)) {
      if (!_isPausedOn(habit, date) && _isHabitScheduled(habit, date)) {
        if (completed.contains(_key(date))) {
          current++;
          if (current > best) best = current;
        } else {
          current = 0;
        }
      }
      date = date.add(const Duration(days: 1));
    }
    return best;
  }

  int expectedHabitDaysForRange(List<AppRecord> habits, DateTime start, DateTime end) {
    var expected = 0;
    for (final habit in habits) {
      final created = _dateOnly(habit.createdAt);
      var date = created.isAfter(_dateOnly(start)) ? created : _dateOnly(start);
      final last = _dateOnly(end);
      while (!date.isAfter(last)) {
        if (_isHabitScheduled(habit, date) && !_isPausedOn(habit, date)) expected++;
        date = date.add(const Duration(days: 1));
      }
    }
    return expected;
  }

  int _notificationId(String id) {
    // Stable FNV-1a so notifications can be cancelled after an app restart.
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  Set<String> _habitDays(String habitId) => _records
      .where((r) => r.type == RecordType.habitCheck && r.meta['habitId'] == habitId)
      .map((r) => _key(r.date))
      .toSet();

  Future<bool> requestNotificationPermissions() => _notifications.requestPermissions();

  Future<void> setName(String value) async {
    _name = value.trim();
    await _prefs?.setString('user_name', _name);
    notifyListeners();
  }

  Future<void> setTheme(String value) async {
    _theme = value;
    await _prefs?.setString('theme', value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    await _prefs?.setString('language', value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs?.setBool('notifications_enabled', value);
    if (value) {
      await _notifications.requestPermissions();
      for (final record in _records) {
        await _scheduleRecordReminder(record);
      }
    }
    if (!value) await _notifications.cancelAll();
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    _biometricEnabled = value;
    await _prefs?.setBool('biometric_enabled', value);
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    _pinSalt = base64Encode(salt);
    _pinHash = sha256.convert(utf8.encode('$_pinSalt:$pin')).toString();
    await _prefs?.setString('pin_salt', _pinSalt);
    await _prefs?.setString('pin_hash', _pinHash);
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    if (_pinHash.isEmpty) return true;
    final candidate = sha256.convert(utf8.encode('$_pinSalt:$pin')).toString();
    return candidate == _pinHash;
  }

  Future<void> removePin() async {
    _pinHash = '';
    _pinSalt = '';
    await _prefs?.remove('pin_hash');
    await _prefs?.remove('pin_salt');
    notifyListeners();
  }

  String exportBackup() => jsonEncode({
        'app': AppConstants.appName,
        'schemaVersion': AppConstants.databaseVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'records': _records.map((record) => record.toJson()).toList(),
        'settings': {
          'name': _name,
          'theme': _theme,
          'language': _language,
          'notificationsEnabled': _notificationsEnabled,
        },
      });

  Future<void> importBackup(String source) async {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    if (decoded['app'] != AppConstants.appName || decoded['records'] is! List) {
      throw const FormatException('This is not a DayPilot backup file.');
    }
    final imported = (decoded['records'] as List)
        .map((item) => AppRecord.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    await _database.replaceAll(imported);
    _records = imported;
    final settings = Map<String, dynamic>.from(decoded['settings'] as Map? ?? {});
    await setName(settings['name'] as String? ?? _name);
    await setTheme(settings['theme'] as String? ?? _theme);
    await setLanguage(settings['language'] as String? ?? _language);
    await setNotificationsEnabled(settings['notificationsEnabled'] as bool? ?? _notificationsEnabled);
    notifyListeners();
  }

  int waterMlFor(DateTime date) => recordsForDate(date, types: {RecordType.water})
      .fold(0, (total, record) => total + (record.meta['ml'] as int? ?? 0));

  int waterTargetMlFor(DateTime date) {
    final records = recordsForDate(date, types: {RecordType.water});
    return records.isEmpty
        ? AppConstants.defaultWaterTargetMl
        : records.first.meta['targetMl'] as int? ?? AppConstants.defaultWaterTargetMl;
  }

  int exerciseMinutesFor(DateTime date) =>
      recordsForDate(date, types: {RecordType.exercise}).fold(
        0,
        (total, record) => total + (record.meta['minutes'] as int? ?? 0),
      );

  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
  static String _key(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
