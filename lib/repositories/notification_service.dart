import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/medication_schedule.dart';

/// Channel identifiers for Android notification categories.
class _Channels {
  static const String medicationId = 'medication_reminder';
  static const String medicationName = 'Medication Reminders';
  static const String medicationDesc =
      'Daily reminders to take your prescribed medications.';

  static const String alarmId = 'medication_alarm';
  static const String alarmName = 'Medication Alarms';
  static const String alarmDesc =
      'Alarm-style notifications for critical medication times.';
}

/// Central notification service used by the app.
///
/// Wraps `flutter_local_notifications` to:
/// - schedule exact-time daily medication reminders
/// - support alarm-style full-screen notifications (Android)
/// - reschedule all reminders from a list of [MedicationSchedule]s
///
/// Call [initialize] once from `main()` and [requestPermissions] after
/// a user logs in.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ─────────────────────────── Init ────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    await _createChannels();
    _initialized = true;
  }

  Future<void> _createChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _Channels.medicationId,
        _Channels.medicationName,
        description: _Channels.medicationDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        _Channels.alarmId,
        _Channels.alarmName,
        description: _Channels.alarmDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      ),
    );
  }

  // ─────────────────────────── Permissions ─────────────────────────────────

  /// Requests notification + exact-alarm permissions.
  /// Returns true if all essential permissions are granted.
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return true;

    // POST_NOTIFICATIONS (Android 13+)
    final notifStatus = await Permission.notification.request();

    // SCHEDULE_EXACT_ALARM (Android 12+) — falls back gracefully if denied
    await Permission.scheduleExactAlarm.request();

    return notifStatus.isGranted;
  }

  // ─────────────────────────── Schedule ────────────────────────────────────

  /// Schedules a single medication reminder for [scheduledTime].
  ///
  /// [id] must be unique per notification. Use a deterministic hash
  /// based on schedule ID + time string.
  Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    bool asAlarm = false,
  }) async {
    if (!_initialized) await initialize();

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final androidDetails = AndroidNotificationDetails(
      asAlarm ? _Channels.alarmId : _Channels.medicationId,
      asAlarm ? _Channels.alarmName : _Channels.medicationName,
      channelDescription:
          asAlarm ? _Channels.alarmDesc : _Channels.medicationDesc,
      importance: asAlarm ? Importance.max : Importance.high,
      priority: asAlarm ? Priority.max : Priority.high,
      fullScreenIntent: asAlarm,
      category: asAlarm
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
      ticker: 'Medication reminder',
      icon: '@mipmap/ic_launcher',
      actions: [
        const AndroidNotificationAction('taken', 'Taken ✓',
            showsUserInterface: false),
        const AndroidNotificationAction('snooze', 'Snooze 10 min',
            showsUserInterface: false),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      '💊 Time for $medicationName',
      '$dosage — tap to confirm you have taken it.',
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedules all reminders for a single [MedicationSchedule] for today
  /// and the next [lookaheadDays] days.
  Future<void> scheduleAllReminders(
    MedicationSchedule schedule, {
    int lookaheadDays = 7,
  }) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();

    for (var dayOffset = 0; dayOffset < lookaheadDays; dayOffset++) {
      final day = now.add(Duration(days: dayOffset));
      final weekday = day.weekday;

      // Skip days not in the schedule
      if (schedule.daysOfWeek != null &&
          !schedule.daysOfWeek!.contains(weekday)) {
        continue;
      }

      for (final timeStr in schedule.timesOfDay) {
        final parts = timeStr.split(':');
        final h = int.tryParse(parts[0]) ?? 8;
        final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

        final doseTime =
            DateTime(day.year, day.month, day.day, h, m);

        if (doseTime.isBefore(now)) continue;

        // Build a stable int ID from schedule id hash + day + time
        final notifId = _stableId(schedule.id, dayOffset, h, m);

        await scheduleMedicationReminder(
          id: notifId,
          medicationName: schedule.medicationName,
          dosage: schedule.dosage,
          scheduledTime: doseTime,
        );
      }
    }
  }

  /// Cancel all scheduled notifications for a specific [scheduleId].
  /// Uses the same stable ID algorithm used during scheduling.
  Future<void> cancelScheduleReminders(
    MedicationSchedule schedule, {
    int lookaheadDays = 7,
  }) async {
    if (!_initialized) await initialize();

    for (var dayOffset = 0; dayOffset < lookaheadDays; dayOffset++) {
      for (final timeStr in schedule.timesOfDay) {
        final parts = timeStr.split(':');
        final h = int.tryParse(parts[0]) ?? 8;
        final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        await _plugin.cancel(_stableId(schedule.id, dayOffset, h, m));
      }
    }
  }

  /// Cancel ALL scheduled notifications (e.g. on sign-out).
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  // ─────────────────────────── Helpers ─────────────────────────────────────

  /// Deterministic notification ID that fits in a 32-bit signed integer.
  int _stableId(String scheduleId, int dayOffset, int hour, int minute) {
    // Use a simple polynomial hash that fits in 2^31-1.
    final key = '${scheduleId}_${dayOffset}_${hour}_$minute';
    var hash = 7;
    for (final char in key.codeUnits) {
      hash = 31 * hash + char;
    }
    return hash.abs() % 2147483647;
  }
}

// Top-level handlers required by flutter_local_notifications for background
// callbacks (must be top-level / static functions).
@pragma('vm:entry-point')
void _onNotificationTap(NotificationResponse response) {
  // Notification tap handled inside the app; routing happens via app state.
  debugPrint(
      '[NotificationService] tapped: ${response.id} action: ${response.actionId}');
}

@pragma('vm:entry-point')
void _onBackgroundNotificationTap(NotificationResponse response) {
  debugPrint(
      '[NotificationService] background tap: ${response.id} action: ${response.actionId}');
}
