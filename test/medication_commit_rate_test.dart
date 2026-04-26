import 'package:flutter_test/flutter_test.dart';
import 'package:voxmed/core/constants/app_constants.dart';
import 'package:voxmed/models/medication_schedule.dart';
import 'package:voxmed/repositories/notification_service.dart';

void main() {
  group('Commit Rate route', () {
    test('route constant is available for notification deep links', () {
      expect(AppRoutes.commitRate, '/commit-rate');
    });
  });

  group('MedicationSchedule.formatDoseTimeLabel', () {
    test('formats midnight with AM', () {
      final label = MedicationSchedule.formatDoseTimeLabel(
        DateTime(2026, 4, 27, 0, 5),
      );

      expect(label, '12:05 AM');
    });

    test('formats afternoon with PM', () {
      final label = MedicationSchedule.formatDoseTimeLabel(
        DateTime(2026, 4, 27, 13, 30),
      );

      expect(label, '1:30 PM');
    });
  });

  group('MedicationAdherenceEntry', () {
    test('parses logged intake rows', () {
      final entry = MedicationAdherenceEntry.fromJson({
        'id': 'log-1',
        'schedule_id': 'schedule-1',
        'prescription_item_id': 'item-1',
        'medication_name': 'Metformin',
        'scheduled_time': '2026-04-27T08:00:00',
        'response_time': '2026-04-27T08:09:00',
        'status': 'taken',
      });

      expect(entry.id, 'log-1');
      expect(entry.medicationName, 'Metformin');
      expect(entry.status, AdherenceStatus.taken);
      expect(entry.statusLabel, 'Taken');
    });

    test('falls back to joined schedule medication name', () {
      final entry = MedicationAdherenceEntry.fromJson({
        'id': 'log-2',
        'schedule_id': 'schedule-2',
        'scheduled_time': '2026-04-27T20:00:00',
        'status': 'missed',
        'medication_schedules': {
          'medication_name': 'Amlodipine',
          'dosage': '5mg',
        },
      });

      expect(entry.medicationName, 'Amlodipine');
      expect(entry.dosage, '5mg');
      expect(entry.statusLabel, 'Missed');
    });

    test('creates derived missed entries from schedules', () {
      final schedule = MedicationSchedule(
        id: 'schedule-3',
        patientId: 'patient-1',
        medicationName: 'Vitamin D3',
        dosage: '1000 IU',
        frequency: 'daily',
        timesOfDay: const ['13:00'],
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      );

      final entry = MedicationAdherenceEntry.derivedMissed(
        schedule: schedule,
        scheduledTime: DateTime(2026, 4, 27, 13),
      );

      expect(entry.isDerived, isTrue);
      expect(entry.status, AdherenceStatus.missed);
      expect(entry.medicationName, 'Vitamin D3');
    });
  });

  group('Notification medication payload', () {
    test('round-trips medication notification deep-link payload', () {
      final scheduled = DateTime.utc(2026, 4, 27, 8);
      final payload = NotificationService.buildMedicationPayload(
        patientId: 'patient-1',
        scheduleId: 'schedule-1',
        prescriptionItemId: 'item-1',
        medicationName: 'Metformin',
        dosage: '500mg',
        scheduledTime: scheduled,
      );

      final parsed = NotificationService.parseMedicationPayload(payload);

      expect(parsed['target_route'], AppRoutes.commitRate);
      expect(parsed['patient_id'], 'patient-1');
      expect(parsed['schedule_id'], 'schedule-1');
      expect(parsed['prescription_item_id'], 'item-1');
      expect(parsed['medication_name'], 'Metformin');
      expect(parsed['scheduled_time'], '2026-04-27T08:00:00.000Z');
    });

    test('invalid payloads parse as empty maps', () {
      expect(NotificationService.parseMedicationPayload('not-json'), isEmpty);
      expect(NotificationService.parseMedicationPayload(null), isEmpty);
    });
  });
}
