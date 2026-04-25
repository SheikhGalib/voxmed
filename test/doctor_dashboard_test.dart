import 'package:flutter_test/flutter_test.dart';
import 'package:voxmed/core/constants/app_constants.dart';
import 'package:voxmed/models/appointment.dart';
import 'package:voxmed/models/prescription.dart';

void main() {
  group('Doctor Dashboard — AppRoutes', () {
    test('new routes exist', () {
      expect(AppRoutes.doctorSchedule, '/doctor-schedule');
      expect(AppRoutes.myPatients, '/my-patients');
      expect(AppRoutes.patientDetail, '/patient-detail');
    });
  });

  group('Doctor Dashboard — Appointment model', () {
    test('fromJson parses patientName', () {
      final json = {
        'id': 'appt-1',
        'patient_id': 'patient-1',
        'doctor_id': 'doctor-1',
        'hospital_id': null,
        'scheduled_start_at': '2025-01-15T09:00:00Z',
        'scheduled_end_at': '2025-01-15T09:30:00Z',
        'status': 'scheduled',
        'type': 'in_person',
        'reason': 'Routine checkup',
        'notes': null,
        'rescheduled_from': null,
        'created_at': '2025-01-10T00:00:00Z',
        'updated_at': '2025-01-10T00:00:00Z',
        'doctors': {
          'specialty': 'General',
          'profiles': {'full_name': 'Dr. Smith', 'avatar_url': null}
        },
        'hospitals': null,
        'profiles': {'full_name': 'John Doe', 'avatar_url': null},
      };
      final appt = Appointment.fromJson(json);
      expect(appt.patientName, 'John Doe');
      expect(appt.doctorName, 'Dr. Smith');
      expect(appt.status, AppointmentStatus.scheduled);
      expect(appt.type, AppointmentType.inPerson);
    });

    test('AppointmentType followUp serializes correctly', () {
      expect(AppointmentType.followUp.value, 'follow_up');
      expect(AppointmentType.fromString('follow_up'), AppointmentType.followUp);
    });

    test('AppointmentStatus fromString handles in_progress', () {
      expect(AppointmentStatus.fromString('in_progress'), AppointmentStatus.inProgress);
    });
  });

  group('Doctor Dashboard — Prescription model', () {
    test('fromJson with items', () {
      final json = {
        'id': 'rx-1',
        'patient_id': 'patient-1',
        'doctor_id': 'doctor-1',
        'appointment_id': null,
        'diagnosis': 'Hypertension',
        'notes': 'Take with food',
        'status': 'active',
        'issued_date': '2025-01-15',
        'valid_until': null,
        'created_at': '2025-01-15T00:00:00Z',
        'updated_at': '2025-01-15T00:00:00Z',
        'doctors': {
          'specialty': 'Cardiology',
          'profiles': {'full_name': 'Dr. Jones', 'avatar_url': null}
        },
        'prescription_items': [
          {
            'id': 'item-1',
            'prescription_id': 'rx-1',
            'medication_name': 'Amlodipine',
            'dosage': '5mg',
            'frequency': 'Once daily',
            'duration_days': 30,
            'instructions': 'Morning',
            'quantity': 30,
            'remaining': 30,
            'created_at': '2025-01-15T00:00:00Z',
          }
        ],
      };
      final rx = Prescription.fromJson(json);
      expect(rx.diagnosis, 'Hypertension');
      expect(rx.status, PrescriptionStatus.active);
      expect(rx.items?.length, 1);
      expect(rx.items?.first.medicationName, 'Amlodipine');
    });

    test('PrescriptionStatus.fromString handles cancelled', () {
      expect(PrescriptionStatus.fromString('cancelled'), PrescriptionStatus.cancelled);
    });
  });

  group('Doctor Dashboard — visit frequency chart logic', () {
    test('groups visits by month correctly', () {
      final now = DateTime.now();
      final visits = [
        _makeAppt(DateTime(now.year, now.month, 5)),
        _makeAppt(DateTime(now.year, now.month, 10)),
        _makeAppt(DateTime(now.year, now.month - 1, 20)),
      ];

      // Count visits in current month
      final thisMonthCount = visits
          .where((v) =>
              v.scheduledStartAt.year == now.year &&
              v.scheduledStartAt.month == now.month)
          .length;
      expect(thisMonthCount, 2);
    });

    test('medication frequency aggregation', () {
      final medications = ['Amlodipine', 'Metformin', 'Amlodipine', 'Aspirin', 'Metformin'];
      final Map<String, int> freq = {};
      for (final m in medications) {
        freq[m] = (freq[m] ?? 0) + 1;
      }
      expect(freq['Amlodipine'], 2);
      expect(freq['Metformin'], 2);
      expect(freq['Aspirin'], 1);
    });
  });
}

// Helper
Appointment _makeAppt(DateTime dateTime) {
  return Appointment(
    id: 'appt-${dateTime.millisecondsSinceEpoch}',
    patientId: 'patient-1',
    doctorId: 'doctor-1',
    scheduledStartAt: dateTime,
    scheduledEndAt: dateTime.add(const Duration(minutes: 30)),
    createdAt: dateTime,
    updatedAt: dateTime,
  );
}
