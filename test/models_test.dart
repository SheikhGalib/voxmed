import 'package:flutter_test/flutter_test.dart';
import 'package:voxmed/models/user_profile.dart';
import 'package:voxmed/models/hospital.dart';
import 'package:voxmed/models/doctor.dart';
import 'package:voxmed/models/doctor_schedule.dart';
import 'package:voxmed/models/appointment.dart';
import 'package:voxmed/models/medical_record.dart';
import 'package:voxmed/models/prescription.dart';
import 'package:voxmed/models/notification_model.dart';
import 'package:voxmed/models/review.dart';
import 'package:voxmed/core/constants/app_constants.dart';

void main() {
  group('UserProfile', () {
    final sampleJson = {
      'id': '550e8400-e29b-41d4-a716-446655440000',
      'role': 'patient',
      'full_name': 'Adrian Test',
      'email': 'adrian@test.com',
      'phone': '+1234567890',
      'date_of_birth': '1990-05-15',
      'gender': 'male',
      'blood_group': 'A+',
      'address': '123 Main St',
      'avatar_url': null,
      'emergency_contact': {'name': 'Jane', 'phone': '555-0100', 'relation': 'spouse'},
      'created_at': '2026-03-28T00:00:00Z',
      'updated_at': '2026-03-28T00:00:00Z',
    };

    test('fromJson creates correct model', () {
      final profile = UserProfile.fromJson(sampleJson);
      expect(profile.id, '550e8400-e29b-41d4-a716-446655440000');
      expect(profile.role, UserRole.patient);
      expect(profile.fullName, 'Adrian Test');
      expect(profile.email, 'adrian@test.com');
      expect(profile.phone, '+1234567890');
      expect(profile.dateOfBirth, DateTime(1990, 5, 15));
      expect(profile.gender, 'male');
      expect(profile.bloodGroup, 'A+');
      expect(profile.emergencyContact?['relation'], 'spouse');
    });

    test('toJson produces correct map', () {
      final profile = UserProfile.fromJson(sampleJson);
      final json = profile.toJson();
      expect(json['full_name'], 'Adrian Test');
      expect(json['role'], 'patient');
      expect(json['email'], 'adrian@test.com');
    });

    test('copyWith preserves unchanged fields', () {
      final profile = UserProfile.fromJson(sampleJson);
      final updated = profile.copyWith(fullName: 'New Name');
      expect(updated.fullName, 'New Name');
      expect(updated.email, 'adrian@test.com');
      expect(updated.role, UserRole.patient);
    });

    test('handles null optional fields', () {
      final minJson = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'role': 'doctor',
        'full_name': 'Dr. Test',
        'email': 'dr@test.com',
        'created_at': '2026-03-28T00:00:00Z',
        'updated_at': '2026-03-28T00:00:00Z',
      };
      final profile = UserProfile.fromJson(minJson);
      expect(profile.role, UserRole.doctor);
      expect(profile.phone, isNull);
      expect(profile.dateOfBirth, isNull);
      expect(profile.emergencyContact, isNull);
    });
  });

  group('Hospital', () {
    final sampleJson = {
      'id': '660e8400-e29b-41d4-a716-446655440001',
      'name': 'Central Medical Pavilion',
      'description': 'Top-tier healthcare facility',
      'address': '456 Hospital Ave',
      'city': 'Dhaka',
      'country': 'Bangladesh',
      'latitude': 23.8103,
      'longitude': 90.4125,
      'services': ['Radiology', 'ICU', 'Cardiology'],
      'rating': 4.9,
      'is_active': true,
      'created_at': '2026-03-28T00:00:00Z',
      'updated_at': '2026-03-28T00:00:00Z',
    };

    test('fromJson creates correct model', () {
      final hospital = Hospital.fromJson(sampleJson);
      expect(hospital.name, 'Central Medical Pavilion');
      expect(hospital.city, 'Dhaka');
      expect(hospital.services, contains('Cardiology'));
      expect(hospital.rating, 4.9);
      expect(hospital.isActive, true);
    });

    test('handles null coordinates', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json.remove('latitude');
      json.remove('longitude');
      final hospital = Hospital.fromJson(json);
      expect(hospital.latitude, isNull);
      expect(hospital.longitude, isNull);
    });
  });

  group('Doctor', () {
    final sampleJson = {
      'id': '770e8400-e29b-41d4-a716-446655440002',
      'profile_id': '550e8400-e29b-41d4-a716-446655440000',
      'hospital_id': '660e8400-e29b-41d4-a716-446655440001',
      'specialty': 'Cardiology',
      'sub_specialty': 'Interventional',
      'qualifications': ['MBBS', 'MD', 'FRCS'],
      'experience_years': 15,
      'consultation_fee': 120.00,
      'patients_count': 2400,
      'reviews_count': 850,
      'rating': 4.9,
      'is_available': true,
      'created_at': '2026-03-28T00:00:00Z',
      'updated_at': '2026-03-28T00:00:00Z',
      'profiles': {
        'full_name': 'Dr. Julian Thorne',
        'avatar_url': null,
        'email': 'julian@hospital.com',
      },
      'hospitals': {
        'name': 'Central Medical Pavilion',
      },
    };

    test('fromJson with joined data', () {
      final doctor = Doctor.fromJson(sampleJson);
      expect(doctor.specialty, 'Cardiology');
      expect(doctor.fullName, 'Dr. Julian Thorne');
      expect(doctor.hospitalName, 'Central Medical Pavilion');
      expect(doctor.consultationFee, 120.00);
      expect(doctor.qualifications, contains('FRCS'));
      expect(doctor.displayName, 'Dr. Julian Thorne');
    });

    test('displayName fallback when no profile', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json.remove('profiles');
      final doctor = Doctor.fromJson(json);
      expect(doctor.displayName, 'Dr. Unknown');
    });
  });

  group('DoctorSchedule', () {
    test('fromJson and dayName', () {
      final json = {
        'id': 'schedule-id-1',
        'doctor_id': 'doctor-id-1',
        'day_of_week': 1,
        'start_time': '09:00',
        'end_time': '17:00',
        'slot_duration_minutes': 30,
        'is_active': true,
        'created_at': '2026-03-28T00:00:00Z',
      };
      final schedule = DoctorSchedule.fromJson(json);
      expect(schedule.dayOfWeek, 1);
      expect(schedule.dayName, 'Monday');
      expect(schedule.shortDayName, 'Mon');
      expect(schedule.slotDurationMinutes, 30);
    });
  });

  group('Appointment', () {
    final sampleJson = {
      'id': 'appt-id-1',
      'patient_id': 'patient-id-1',
      'doctor_id': 'doctor-id-1',
      'scheduled_start_at': '2026-04-01T09:30:00Z',
      'scheduled_end_at': '2026-04-01T10:00:00Z',
      'status': 'scheduled',
      'type': 'in_person',
      'reason': 'Annual checkup',
      'created_at': '2026-03-28T00:00:00Z',
      'updated_at': '2026-03-28T00:00:00Z',
    };

    test('fromJson creates correct model', () {
      final appt = Appointment.fromJson(sampleJson);
      expect(appt.status, AppointmentStatus.scheduled);
      expect(appt.type, AppointmentType.inPerson);
      expect(appt.reason, 'Annual checkup');
      expect(appt.isUpcoming, true);
    });

    test('isUpcoming false for completed', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json['status'] = 'completed';
      final appt = Appointment.fromJson(json);
      expect(appt.isUpcoming, false);
    });
  });

  group('MedicalRecord', () {
    test('fromJson handles all record types', () {
      final json = {
        'id': 'record-id-1',
        'patient_id': 'patient-id-1',
        'record_type': 'lab_result',
        'title': 'Blood Panel',
        'ocr_extracted': true,
        'created_at': '2026-03-28T00:00:00Z',
        'updated_at': '2026-03-28T00:00:00Z',
      };
      final record = MedicalRecord.fromJson(json);
      expect(record.recordType, RecordType.labResult);
      expect(record.ocrExtracted, true);
    });
  });

  group('Prescription', () {
    test('fromJson with items', () {
      final json = {
        'id': 'rx-id-1',
        'patient_id': 'patient-id-1',
        'doctor_id': 'doctor-id-1',
        'diagnosis': 'Hypertension',
        'status': 'active',
        'issued_date': '2026-03-28',
        'created_at': '2026-03-28T00:00:00Z',
        'updated_at': '2026-03-28T00:00:00Z',
        'prescription_items': [
          {
            'id': 'item-id-1',
            'prescription_id': 'rx-id-1',
            'medication_name': 'Amlodipine',
            'dosage': '5mg',
            'frequency': 'Once daily',
            'duration_days': 30,
            'quantity': 30,
            'remaining': 25,
            'created_at': '2026-03-28T00:00:00Z',
          },
        ],
      };
      final rx = Prescription.fromJson(json);
      expect(rx.diagnosis, 'Hypertension');
      expect(rx.status, PrescriptionStatus.active);
      expect(rx.items, isNotNull);
      expect(rx.items!.length, 1);
      expect(rx.items!.first.medicationName, 'Amlodipine');
      expect(rx.items!.first.durationDays, 30);
    });
  });

  group('NotificationModel', () {
    test('fromJson parses notification type', () {
      final json = {
        'id': 'notif-id-1',
        'user_id': 'user-id-1',
        'type': 'appointment_reminder',
        'title': 'Appointment Tomorrow',
        'body': 'You have an appointment at 9:30 AM',
        'is_read': false,
        'created_at': '2026-03-28T00:00:00Z',
      };
      final notif = NotificationModel.fromJson(json);
      expect(notif.type, NotificationType.appointmentReminder);
      expect(notif.isRead, false);
    });
  });

  group('Review', () {
    test('fromJson with joined patient', () {
      final json = {
        'id': 'review-id-1',
        'patient_id': 'patient-id-1',
        'doctor_id': 'doctor-id-1',
        'rating': 5,
        'comment': 'Excellent doctor',
        'created_at': '2026-03-28T00:00:00Z',
        'profiles': {
          'full_name': 'Adrian Test',
          'avatar_url': null,
        },
      };
      final review = Review.fromJson(json);
      expect(review.rating, 5);
      expect(review.patientName, 'Adrian Test');
    });
  });

  group('Enums', () {
    test('AppointmentStatus round-trip', () {
      expect(AppointmentStatus.inProgress.value, 'in_progress');
      expect(AppointmentStatus.fromString('in_progress'), AppointmentStatus.inProgress);
      expect(AppointmentStatus.noShow.value, 'no_show');
      expect(AppointmentStatus.fromString('no_show'), AppointmentStatus.noShow);
    });

    test('AppointmentType round-trip', () {
      expect(AppointmentType.inPerson.value, 'in_person');
      expect(AppointmentType.fromString('in_person'), AppointmentType.inPerson);
      expect(AppointmentType.followUp.value, 'follow_up');
      expect(AppointmentType.fromString('follow_up'), AppointmentType.followUp);
    });

    test('RecordType round-trip', () {
      expect(RecordType.labResult.value, 'lab_result');
      expect(RecordType.fromString('lab_result'), RecordType.labResult);
      expect(RecordType.consultationNote.value, 'consultation_note');
    });

    test('UserRole round-trip', () {
      expect(UserRole.patient.value, 'patient');
      expect(UserRole.fromString('doctor'), UserRole.doctor);
      expect(UserRole.fromString('invalid'), UserRole.patient); // fallback
    });
  });
}
