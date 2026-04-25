import 'package:flutter_test/flutter_test.dart';
import 'package:voxmed/models/doctor_schedule.dart';

void main() {
  // ---------------------------------------------------------------------------
  // DoctorSchedule model — unit tests
  // ---------------------------------------------------------------------------

  group('DoctorSchedule.fromJson', () {
    const fullJson = {
      'id': 'sched-001',
      'doctor_id': 'doc-001',
      'day_of_week': 1,
      'start_time': '09:00:00',
      'end_time': '17:00:00',
      'slot_duration_minutes': 30,
      'is_active': true,
      'created_at': '2026-04-25T08:00:00Z',
    };

    test('parses all fields correctly', () {
      final s = DoctorSchedule.fromJson(fullJson);
      expect(s.id, 'sched-001');
      expect(s.doctorId, 'doc-001');
      expect(s.dayOfWeek, 1);
      expect(s.startTime, '09:00:00');
      expect(s.endTime, '17:00:00');
      expect(s.slotDurationMinutes, 30);
      expect(s.isActive, true);
    });

    test('defaults slot_duration_minutes to 30 when absent', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..remove('slot_duration_minutes');
      final s = DoctorSchedule.fromJson(json);
      expect(s.slotDurationMinutes, 30);
    });

    test('defaults is_active to true when absent', () {
      final json = Map<String, dynamic>.from(fullJson)..remove('is_active');
      final s = DoctorSchedule.fromJson(json);
      expect(s.isActive, true);
    });
  });

  // ---------------------------------------------------------------------------
  // DoctorSchedule.toJson
  // ---------------------------------------------------------------------------

  group('DoctorSchedule.toJson', () {
    test('round-trip fromJson → toJson preserves all values', () {
      const json = {
        'id': 'sched-002',
        'doctor_id': 'doc-002',
        'day_of_week': 3,
        'start_time': '10:00:00',
        'end_time': '14:00:00',
        'slot_duration_minutes': 20,
        'is_active': false,
        'created_at': '2026-04-25T08:00:00Z',
      };
      final s = DoctorSchedule.fromJson(json);
      final out = s.toJson();

      expect(out['doctor_id'], 'doc-002');
      expect(out['day_of_week'], 3);
      expect(out['start_time'], '10:00:00');
      expect(out['end_time'], '14:00:00');
      expect(out['slot_duration_minutes'], 20);
      expect(out['is_active'], false);
    });

    test('toJson does not include id or created_at', () {
      const json = {
        'id': 'sched-003',
        'doctor_id': 'doc-003',
        'day_of_week': 5,
        'start_time': '08:00:00',
        'end_time': '12:00:00',
        'slot_duration_minutes': 15,
        'is_active': true,
        'created_at': '2026-04-25T08:00:00Z',
      };
      final out = DoctorSchedule.fromJson(json).toJson();
      expect(out.containsKey('id'), false);
      expect(out.containsKey('created_at'), false);
    });
  });

  // ---------------------------------------------------------------------------
  // Day name helpers
  // ---------------------------------------------------------------------------

  group('DoctorSchedule day name helpers', () {
    DoctorSchedule _make(int day) => DoctorSchedule.fromJson({
          'id': 'x',
          'doctor_id': 'y',
          'day_of_week': day,
          'start_time': '09:00:00',
          'end_time': '17:00:00',
          'created_at': '2026-04-25T00:00:00Z',
        });

    test('dayName returns full names for all 7 days', () {
      const expected = [
        'Sunday', 'Monday', 'Tuesday', 'Wednesday',
        'Thursday', 'Friday', 'Saturday'
      ];
      for (int i = 0; i < 7; i++) {
        expect(_make(i).dayName, expected[i], reason: 'day $i');
      }
    });

    test('shortDayName returns 3-letter abbreviations', () {
      const expected = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      for (int i = 0; i < 7; i++) {
        expect(_make(i).shortDayName, expected[i], reason: 'day $i');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Slot count calculation
  // ---------------------------------------------------------------------------

  group('Slot count (derived from schedule fields)', () {
    /// Helper: computes how many slots fit between [start] and [end].
    int slotCount(String start, String end, int durationMinutes) {
      int toMinutes(String t) {
        final parts = t.split(':');
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }

      final totalMinutes = toMinutes(end) - toMinutes(start);
      if (totalMinutes <= 0 || durationMinutes <= 0) return 0;
      return totalMinutes ~/ durationMinutes;
    }

    test('09:00–17:00 with 30-min slots = 16 slots', () {
      expect(slotCount('09:00', '17:00', 30), 16);
    });

    test('09:00–13:00 with 30-min slots = 8 slots (matches seed data)', () {
      expect(slotCount('09:00', '13:00', 30), 8);
    });

    test('09:00–10:00 with 15-min slots = 4 slots', () {
      expect(slotCount('09:00', '10:00', 15), 4);
    });

    test('returns 0 when end is before start', () {
      expect(slotCount('17:00', '09:00', 30), 0);
    });

    test('returns 0 when duration is 0', () {
      expect(slotCount('09:00', '17:00', 0), 0);
    });
  });
}
