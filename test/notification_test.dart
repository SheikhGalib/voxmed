import 'package:flutter_test/flutter_test.dart';
import 'package:voxmed/models/medication_schedule.dart';

void main() {
  // ── MedicationSchedule model ──────────────────────────────────────────────

  group('MedicationSchedule.fromJson', () {
    final baseJson = {
      'id': 'abc-123',
      'patient_id': 'patient-1',
      'prescription_item_id': 'item-1',
      'medication_name': 'Metformin',
      'dosage': '500mg',
      'frequency': 'twice daily',
      'times_of_day': ['08:00', '20:00'],
      'days_of_week': null,
      'is_active': true,
      'notes': null,
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    };

    test('parses required fields correctly', () {
      final s = MedicationSchedule.fromJson(baseJson);
      expect(s.id, 'abc-123');
      expect(s.patientId, 'patient-1');
      expect(s.medicationName, 'Metformin');
      expect(s.dosage, '500mg');
      expect(s.frequency, 'twice daily');
      expect(s.isActive, true);
    });

    test('parses timesOfDay list', () {
      final s = MedicationSchedule.fromJson(baseJson);
      expect(s.timesOfDay, ['08:00', '20:00']);
    });

    test('null days_of_week means every day', () {
      final s = MedicationSchedule.fromJson(baseJson);
      expect(s.daysOfWeek, isNull);
    });

    test('parses days_of_week when provided', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['days_of_week'] = [1, 3, 5]; // Mon, Wed, Fri
      final s = MedicationSchedule.fromJson(json);
      expect(s.daysOfWeek, [1, 3, 5]);
    });

    test('defaults frequency to daily when absent', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('frequency');
      final s = MedicationSchedule.fromJson(json);
      expect(s.frequency, 'daily');
    });

    test('defaults timesOfDay to 08:00 when absent', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('times_of_day');
      final s = MedicationSchedule.fromJson(json);
      expect(s.timesOfDay, ['08:00']);
    });
  });

  group('MedicationSchedule.toJson', () {
    final schedule = MedicationSchedule(
      id: 'abc-123',
      patientId: 'patient-1',
      prescriptionItemId: 'item-1',
      medicationName: 'Metformin',
      dosage: '500mg',
      frequency: 'twice daily',
      timesOfDay: ['08:00', '20:00'],
      daysOfWeek: null,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('serialises core fields', () {
      final json = schedule.toJson();
      expect(json['patient_id'], 'patient-1');
      expect(json['medication_name'], 'Metformin');
      expect(json['dosage'], '500mg');
      expect(json['is_active'], true);
    });

    test('includes prescription_item_id when present', () {
      final json = schedule.toJson();
      expect(json['prescription_item_id'], 'item-1');
    });

    test('omits days_of_week when null', () {
      final json = schedule.toJson();
      expect(json.containsKey('days_of_week'), isFalse);
    });

    test('includes days_of_week when set', () {
      final withDays = schedule.copyWith(daysOfWeek: [1, 5]);
      final json = withDays.toJson();
      expect(json['days_of_week'], [1, 5]);
    });
  });

  group('MedicationSchedule.copyWith', () {
    final original = MedicationSchedule(
      id: 'x',
      patientId: 'p',
      medicationName: 'Aspirin',
      dosage: '100mg',
      frequency: 'daily',
      timesOfDay: ['09:00'],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    test('keeps unchanged fields', () {
      final copy = original.copyWith(dosage: '200mg');
      expect(copy.medicationName, 'Aspirin');
      expect(copy.frequency, 'daily');
    });

    test('updates only specified field', () {
      final copy = original.copyWith(dosage: '200mg');
      expect(copy.dosage, '200mg');
    });

    test('id/patientId cannot change via copyWith', () {
      final copy = original.copyWith(medicationName: 'Ibuprofen');
      expect(copy.id, 'x');
      expect(copy.patientId, 'p');
    });
  });

  // ── todayDoseTimes ────────────────────────────────────────────────────────

  group('todayDoseTimes', () {
    test('returns correct DateTime objects for times', () {
      final s = MedicationSchedule(
        id: '1',
        patientId: 'p',
        medicationName: 'Med',
        dosage: '1x',
        frequency: 'daily',
        timesOfDay: ['08:00', '20:30'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final times = s.todayDoseTimes();
      expect(times.length, 2);
      expect(times[0].hour, 8);
      expect(times[0].minute, 0);
      expect(times[1].hour, 20);
      expect(times[1].minute, 30);
    });

    test('returns empty when today is not in daysOfWeek', () {
      final today = DateTime.now().weekday; // 1..7
      // Pick a day that is NOT today
      final otherDay = today == 1 ? 2 : 1;
      final s = MedicationSchedule(
        id: '2',
        patientId: 'p',
        medicationName: 'Med',
        dosage: '1x',
        frequency: 'daily',
        timesOfDay: ['08:00'],
        daysOfWeek: [otherDay],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(s.todayDoseTimes(), isEmpty);
    });

    test('returns times when today IS in daysOfWeek', () {
      final today = DateTime.now().weekday;
      final s = MedicationSchedule(
        id: '3',
        patientId: 'p',
        medicationName: 'Med',
        dosage: '1x',
        frequency: 'daily',
        timesOfDay: ['08:00'],
        daysOfWeek: [today],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(s.todayDoseTimes(), hasLength(1));
    });
  });

  // ── recentlyDueTimes ──────────────────────────────────────────────────────

  group('recentlyDueTimes', () {
    test('returns times within the window', () {
      final now = DateTime.now();
      // Create a schedule with a dose 30 minutes ago
      final doseHour = now.subtract(const Duration(minutes: 30)).hour;
      final doseMin = now.subtract(const Duration(minutes: 30)).minute;
      final timeStr =
          '${doseHour.toString().padLeft(2, '0')}:${doseMin.toString().padLeft(2, '0')}';

      final s = MedicationSchedule(
        id: '4',
        patientId: 'p',
        medicationName: 'Med',
        dosage: '1x',
        frequency: 'daily',
        timesOfDay: [timeStr],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(s.recentlyDueTimes(windowMinutes: 120), hasLength(1));
    });

    test('excludes future times', () {
      final now = DateTime.now();
      final futureHour = (now.hour + 2) % 24;
      final timeStr = '${futureHour.toString().padLeft(2, '0')}:00';

      final s = MedicationSchedule(
        id: '5',
        patientId: 'p',
        medicationName: 'Med',
        dosage: '1x',
        frequency: 'daily',
        timesOfDay: [timeStr],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(s.recentlyDueTimes(windowMinutes: 60), isEmpty);
    });
  });

  // ── Notification ID stability ─────────────────────────────────────────────

  group('Notification ID generation', () {
    int stableId(String scheduleId, int dayOffset, int hour, int minute) {
      final key = '${scheduleId}_${dayOffset}_${hour}_$minute';
      var hash = 7;
      for (final char in key.codeUnits) {
        hash = 31 * hash + char;
      }
      return hash.abs() % 2147483647;
    }

    test('same inputs produce same ID', () {
      final id1 = stableId('schedule-abc', 0, 8, 0);
      final id2 = stableId('schedule-abc', 0, 8, 0);
      expect(id1, id2);
    });

    test('different days produce different IDs', () {
      final id1 = stableId('schedule-abc', 0, 8, 0);
      final id2 = stableId('schedule-abc', 1, 8, 0);
      expect(id1, isNot(id2));
    });

    test('different times produce different IDs', () {
      final id1 = stableId('schedule-abc', 0, 8, 0);
      final id2 = stableId('schedule-abc', 0, 20, 0);
      expect(id1, isNot(id2));
    });

    test('ID fits in signed 32-bit integer', () {
      final id = stableId('some-schedule-id-123', 6, 23, 59);
      expect(id, greaterThan(0));
      expect(id, lessThan(2147483647));
    });
  });
}
