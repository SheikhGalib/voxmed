import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants/app_constants.dart';
import '../core/router/navigation_service.dart';
import '../models/medication_schedule.dart';
import 'medication_schedule_repository.dart';

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

  static const String generalId = 'general';
  static const String generalName = 'General Notifications';
  static const String generalDesc =
      'Appointment updates, lab results, and other alerts.';
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

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if ((launchDetails?.didNotificationLaunchApp ?? false) &&
        launchResponse != null) {
      unawaited(handleNotificationResponse(launchResponse));
    }
  }

  Future<void> _createChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

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

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _Channels.generalId,
        _Channels.generalName,
        description: _Channels.generalDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
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

  // ─────────────────────────── Generic Push ────────────────────────────────

  /// Shows an immediate push notification (no scheduling).
  /// Used for in-app Supabase notification events (appointments, lab results, etc.)
  Future<void> showPush({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    // Stable ID based on title+body hash so duplicate events don't double-notify
    var hash = 7;
    for (final c in '$title$body'.codeUnits) {
      hash = 31 * hash + c;
    }
    final id = hash.abs() % 2147483647;

    const androidDetails = AndroidNotificationDetails(
      _Channels.generalId,
      _Channels.generalName,
      channelDescription: _Channels.generalDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
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
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final androidDetails = AndroidNotificationDetails(
      asAlarm ? _Channels.alarmId : _Channels.medicationId,
      asAlarm ? _Channels.alarmName : _Channels.medicationName,
      channelDescription: asAlarm
          ? _Channels.alarmDesc
          : _Channels.medicationDesc,
      importance: asAlarm ? Importance.max : Importance.high,
      priority: asAlarm ? Priority.max : Priority.high,
      fullScreenIntent: asAlarm,
      category: asAlarm
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
      ticker: 'Medication reminder',
      icon: '@mipmap/ic_launcher',
      actions: [
        const AndroidNotificationAction(
          'taken',
          'Taken ✓',
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          'snooze',
          'Snooze 10 min',
          showsUserInterface: false,
        ),
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
      payload: payload,
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

        final doseTime = DateTime(day.year, day.month, day.day, h, m);

        if (doseTime.isBefore(now)) continue;

        // Build a stable int ID from schedule id hash + day + time
        final notifId = _stableId(schedule.id, dayOffset, h, m);

        await scheduleMedicationReminder(
          id: notifId,
          medicationName: schedule.medicationName,
          dosage: schedule.dosage,
          scheduledTime: doseTime,
          payload: buildMedicationPayload(
            patientId: schedule.patientId,
            scheduleId: schedule.id,
            prescriptionItemId: schedule.prescriptionItemId,
            medicationName: schedule.medicationName,
            dosage: schedule.dosage,
            scheduledTime: doseTime,
          ),
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

  Future<void> handleNotificationResponse(NotificationResponse response) async {
    final actionId = response.actionId ?? '';
    final payload = parseMedicationPayload(response.payload);

    debugPrint(
      '[NotificationService] tapped: ${response.id} action: $actionId',
    );

    if (actionId == 'taken') {
      await _logTaken(payload);
      return;
    }

    if (actionId == 'snooze') {
      await _snooze(payload);
      return;
    }

    final targetRoute =
        payload['target_route'] as String? ?? AppRoutes.commitRate;
    navigateToAppRoute(targetRoute);
  }

  @visibleForTesting
  static String buildMedicationPayload({
    required String patientId,
    required String scheduleId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    String? prescriptionItemId,
    String targetRoute = AppRoutes.commitRate,
  }) {
    final payload = <String, dynamic>{
      'type': 'medication_reminder',
      'target_route': targetRoute,
      'patient_id': patientId,
      'schedule_id': scheduleId,
      'medication_name': medicationName,
      'dosage': dosage,
      'scheduled_time': scheduledTime.toUtc().toIso8601String(),
    };
    if (prescriptionItemId != null) {
      payload['prescription_item_id'] = prescriptionItemId;
    }

    return jsonEncode(payload);
  }

  @visibleForTesting
  static Map<String, dynamic> parseMedicationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return {};

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return {};
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return {};
    }
  }

  Future<void> _logTaken(Map<String, dynamic> payload) async {
    final patientId = payload['patient_id'] as String?;
    final scheduledTimeRaw = payload['scheduled_time'] as String?;
    if (patientId == null || scheduledTimeRaw == null) return;

    final scheduledTime = DateTime.tryParse(scheduledTimeRaw);
    if (scheduledTime == null) return;

    await MedicationScheduleRepository().logAdherence(
      patientId: patientId,
      scheduledTime: scheduledTime,
      status: AdherenceStatus.taken.value,
      scheduleId: payload['schedule_id'] as String?,
      prescriptionItemId: payload['prescription_item_id'] as String?,
      medicationName: payload['medication_name'] as String?,
    );
  }

  Future<void> _snooze(Map<String, dynamic> payload) async {
    final medicationName = payload['medication_name'] as String?;
    final dosage = payload['dosage'] as String?;
    if (medicationName == null || dosage == null) return;

    final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
    final id = snoozeTime.millisecondsSinceEpoch % 2147483647;
    await scheduleMedicationReminder(
      id: id,
      medicationName: medicationName,
      dosage: dosage,
      scheduledTime: snoozeTime,
      payload: jsonEncode({
        ...payload,
        'scheduled_time': snoozeTime.toUtc().toIso8601String(),
      }),
    );
  }

  // ─────────────────────── Appointment Reminders ───────────────────────────

  /// Schedules a local push 15 minutes before [scheduledAt].
  ///
  /// Uses a stable ID derived from [appointmentId] so re-scheduling the same
  /// appointment (e.g. after a realtime reload) never creates a duplicate.
  ///
  /// [isDoctor] controls the notification copy:
  ///   - false (patient): "Appointment in 15 minutes – with Dr. NAME at TIME"
  ///   - true  (doctor):  "Patient arriving in 15 minutes – NAME at TIME"
  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required DateTime scheduledAt,
    required String otherPartyName,
    required bool isDoctor,
  }) async {
    if (!_initialized) await initialize();

    final reminderTime = scheduledAt.subtract(const Duration(minutes: 15));
    if (reminderTime.isBefore(DateTime.now())) return;

    final id = _stableId(appointmentId, 0, scheduledAt.hour, scheduledAt.minute);
    final timeStr =
        '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';

    final title = isDoctor ? 'Patient arriving soon' : 'Appointment in 15 minutes';
    final body = isDoctor
        ? '$otherPartyName at $timeStr'
        : 'With Dr. $otherPartyName at $timeStr';

    const androidDetails = AndroidNotificationDetails(
      _Channels.generalId,
      _Channels.generalName,
      channelDescription: _Channels.generalDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.reminder,
    );

    final tzTime = tz.TZDateTime.from(reminderTime, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: appointmentId,
    );
  }

  /// Cancels the appointment reminder scheduled for [appointmentId].
  Future<void> cancelAppointmentReminder(
    String appointmentId,
    DateTime scheduledAt,
  ) async {
    if (!_initialized) return;
    final id = _stableId(appointmentId, 0, scheduledAt.hour, scheduledAt.minute);
    await _plugin.cancel(id);
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
  unawaited(NotificationService().handleNotificationResponse(response));
}

@pragma('vm:entry-point')
void _onBackgroundNotificationTap(NotificationResponse response) {
  unawaited(NotificationService().handleNotificationResponse(response));
}
