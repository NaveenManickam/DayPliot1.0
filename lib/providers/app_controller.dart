import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' show DateTimeComponents;
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
  int _pinIterations = 0;

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

  static const quotesTamil = <String>[
    'ஒவ்வொரு நாளும் சிறிய முன்னேற்றம் பெரிய மாற்றத்தை உருவாக்கும்.',
    'முன்னேறுவதற்கான ரகசியம் தொடங்குவதில்தான் உள்ளது.',
    'இப்போது விரும்புவதை விட, உண்மையில் முக்கியமானதைத் தேர்ந்தெடுப்பதே ஒழுக்கம்.',
    'சிறிய முயற்சிகள் ஒன்றிணைந்தால் பெரிய சாதனைகள் உருவாகும்.',
    'உங்களிடம் உள்ளவற்றைக் கொண்டு, முடிந்ததைச் செய்யுங்கள்.',
    'ஒவ்வொரு நாளின் சிறிய முன்னேற்றமும் பெரிய வெற்றியாகும்.',
    'நாளைய எதிர்காலம் இன்று நீங்கள் செய்வதில்தான் உள்ளது.',
    'நல்ல தொடக்கம் பாதி வெற்றியாகும்.',
    'முழுமையை விட முன்னேற்றத்தில் கவனம் செலுத்துங்கள்.',
    'செயலே வெற்றிக்கான அடிப்படை.',
    'உங்கள் பழக்கங்கள் உங்கள் நாட்களை உருவாக்குகின்றன.',
    'முடியும் வரை அது முடியாதது போலத் தோன்றும்.',
    'ஒவ்வொரு நாளையும் சிறப்பான நாளாக மாற்றுங்கள்.',
    'தொடர்ந்து செய்யப்படும் சிறிய முயற்சிகளே வெற்றியைத் தரும்.',
    'இருக்கும் இடத்திலிருந்து தொடங்கி, முடிந்ததைச் செய்யுங்கள்.',
    'முன்னேறுவதற்கு முழுமையானவராக இருக்க வேண்டியதில்லை.',
    'சிரமத்தை கடந்து செல்வதே சிறந்த வழி.',
    'ஒரு மணி நேர கவனம் ஒரு நாளின் திசையை மாற்றும்.',
  ];

  String get todayQuote {
    final now = DateTime.now();
    final dayNumber = DateTime(now.year, now.month, now.day)
        .difference(DateTime(2020, 1, 1))
        .inDays;
    final index = dayNumber.abs() % quotes.length;
    return _language == 'Tamil' ? quotesTamil[index] : quotes[index];
  }

  String get greeting => greetingForHour(DateTime.now().hour);

  static String greetingForHour(int hour) {
    if (hour < 0 || hour > 23) throw RangeError.range(hour, 0, 23, 'hour');
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
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
    _pinIterations = _prefs?.getInt('pin_iterations') ?? 0;
    await _notifications.initialize();
    _records = await _database.getAll();
    // Rebuild reminders from the local database after every app launch.
    for (final record in _records) {
      await _cancelRecordReminders(record.id);
      await _scheduleRecordReminder(record);
    }
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
    await _cancelRecordReminders(record.id);
    await _scheduleRecordReminder(record);
    notifyListeners();
  }

  Future<void> _cancelRecordReminders(String recordId) async {
    await _notifications.cancel(_notificationId(recordId));
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      await _notifications.cancel(_notificationId('${recordId}:habit:$weekday'));
    }
  }

  Future<void> _scheduleRecordReminder(AppRecord record) async {
    if (!_notificationsEnabled || record.done) return;
    final reminder = record.meta['reminderAt'];
    if (reminder is! String) return;
    final reminderTime = DateTime.tryParse(reminder);
    if (reminderTime == null) return;
    final body = record.body.isEmpty ? 'Reminder from DayPilot' : record.body;

    if (record.type == RecordType.habit) {
      if (record.meta['paused'] == true) return;
      final frequency = record.meta['frequency'] as String? ?? 'Daily';
      if (frequency == 'Daily') {
        var next = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          reminderTime.hour,
          reminderTime.minute,
        );
        if (!next.isAfter(DateTime.now())) {
          next = next.add(const Duration(days: 1));
        }
        await _notifications.schedule(
          id: _notificationId(record.id),
          title: record.title,
          body: body,
          at: next,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        final weekdays = (record.meta['weekdays'] as List? ?? const [])
            .whereType<num>()
            .map((value) => value.toInt())
            .where((day) => day >= 1 && day <= 7)
            .toSet()
            .toList()
          ..sort();
        for (final weekday in weekdays) {
          final at = _nextWeekdayTime(DateTime.now(), weekday, reminderTime);
          await _notifications.schedule(
            id: _notificationId('${record.id}:habit:$weekday'),
            title: record.title,
            body: body,
            at: at,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      }
      return;
    }

    if (!reminderTime.isAfter(DateTime.now())) return;
    await _notifications.schedule(
      id: _notificationId(record.id),
      title: record.title,
      body: body,
      at: reminderTime,
    );
  }

  DateTime _nextWeekdayTime(DateTime now, int weekday, DateTime reminderTime) {
    final daysAhead = (weekday - now.weekday + 7) % 7;
    var candidate = DateTime(
      now.year,
      now.month,
      now.day + daysAhead,
      reminderTime.hour,
      reminderTime.minute,
    );
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
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
      await _cancelRecordReminders(id);
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
    const iterations = 120000;
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final key = await cryptography.Pbkdf2(
      macAlgorithm: cryptography.Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKey(secretKey: cryptography.SecretKey(utf8.encode(pin)), nonce: salt);
    _pinSalt = base64Encode(salt);
    _pinHash = base64Encode(await key.extractBytes());
    _pinIterations = iterations;
    await _prefs?.setString('pin_salt', _pinSalt);
    await _prefs?.setString('pin_hash', _pinHash);
    await _prefs?.setInt('pin_iterations', _pinIterations);
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    if (_pinHash.isEmpty) return true;
    if (_pinIterations <= 0) {
      // Upgrade PINs created by earlier DayPilot builds after a successful check.
      final legacy = sha256.convert(utf8.encode('$_pinSalt:$pin')).toString();
      if (legacy != _pinHash) return false;
      await setPin(pin);
      return true;
    }
    try {
      final key = await cryptography.Pbkdf2(
        macAlgorithm: cryptography.Hmac.sha256(),
        iterations: _pinIterations,
        bits: 256,
      ).deriveKey(
        secretKey: cryptography.SecretKey(utf8.encode(pin)),
        nonce: base64Decode(_pinSalt),
      );
      final candidate = await key.extractBytes();
      final stored = base64Decode(_pinHash);
      if (candidate.length != stored.length) return false;
      var difference = 0;
      for (var i = 0; i < candidate.length; i++) {
        difference |= candidate[i] ^ stored[i];
      }
      return difference == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> removePin() async {
    _pinHash = '';
    _pinSalt = '';
    _pinIterations = 0;
    await _prefs?.remove('pin_hash');
    await _prefs?.remove('pin_salt');
    await _prefs?.remove('pin_iterations');
    notifyListeners();
  }

  Future<String> exportEncryptedBackup(String passphrase) async {
    const iterations = 150000;
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final algorithm = cryptography.AesGcm.with256bits();
    final key = await cryptography.Pbkdf2(
      macAlgorithm: cryptography.Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKey(
      secretKey: cryptography.SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
    final encrypted = await algorithm.encrypt(
      utf8.encode(exportBackup()),
      secretKey: key,
      nonce: algorithm.newNonce(),
    );
    return jsonEncode({
      'app': AppConstants.appName,
      'format': 'daypilot-encrypted-backup-v1',
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': iterations,
      'cipher': 'AES-256-GCM',
      'salt': base64Encode(salt),
      'nonce': base64Encode(encrypted.nonce),
      'cipherText': base64Encode(encrypted.cipherText),
      'mac': base64Encode(encrypted.mac.bytes),
    });
  }

  Future<void> importEncryptedBackup(String source, String passphrase) async {
    final envelope = jsonDecode(source) as Map<String, dynamic>;
    if (envelope['format'] != 'daypilot-encrypted-backup-v1') {
      await importBackup(source); // Backward compatibility for older plain JSON backups.
      return;
    }
    if (envelope['app'] != AppConstants.appName ||
        envelope['kdf'] != 'PBKDF2-HMAC-SHA256' ||
        envelope['cipher'] != 'AES-256-GCM') {
      throw const FormatException('Unsupported DayPilot backup format.');
    }
    final iterations = envelope['iterations'] as int? ?? 0;
    if (iterations < 100000 || iterations > 300000) {
      throw const FormatException('Invalid backup encryption settings.');
    }
    final salt = base64Decode(envelope['salt'] as String);
    final nonce = base64Decode(envelope['nonce'] as String);
    final cipherText = base64Decode(envelope['cipherText'] as String);
    final mac = base64Decode(envelope['mac'] as String);
    final key = await cryptography.Pbkdf2(
      macAlgorithm: cryptography.Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKey(
      secretKey: cryptography.SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
    final clearText = await cryptography.AesGcm.with256bits().decrypt(
      cryptography.SecretBox(cipherText, nonce: nonce, mac: cryptography.Mac(mac)),
      secretKey: key,
    );
    await importBackup(utf8.decode(clearText));
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
