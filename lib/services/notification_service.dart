import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    try {
      final currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone.name));
    } catch (error) {
      debugPrint('Could not read device timezone; using timezone database default: $error');
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    await android.requestExactAlarmsPermission();
    return granted ?? true;
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    if (at.isBefore(DateTime.now())) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daypilot_reminders',
        'DayPilot reminders',
        channelDescription: 'Task, habit and event reminders',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    try {
      await _plugin.zonedSchedule(
        id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (error) {
      debugPrint('Exact reminder scheduling failed; using inexact mode: $error');
      await _plugin.zonedSchedule(
        id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> cancelAll() => _plugin.cancelAll();
}
