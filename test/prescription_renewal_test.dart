import 'package:flutter_test/flutter_test.dart';
import 'package:voxmed/core/constants/app_constants.dart';
import 'package:voxmed/models/prescription.dart';

void main() {
  // ── RenewalStatus enum ────────────────────────────────────────────────────

  group('RenewalStatus', () {
    test('values list contains followUp', () {
      expect(RenewalStatus.values, contains(RenewalStatus.followUp));
    });

    test('followUp DB value is follow_up', () {
      expect(RenewalStatus.followUp.value, 'follow_up');
    });

    test('pending/approved/rejected use lowercase name as value', () {
      expect(RenewalStatus.pending.value, 'pending');
      expect(RenewalStatus.approved.value, 'approved');
      expect(RenewalStatus.rejected.value, 'rejected');
    });

    test('fromString("follow_up") returns followUp', () {
      expect(RenewalStatus.fromString('follow_up'), RenewalStatus.followUp);
    });

    test('fromString("approved") returns approved', () {
      expect(RenewalStatus.fromString('approved'), RenewalStatus.approved);
    });

    test('fromString("rejected") returns rejected', () {
      expect(RenewalStatus.fromString('rejected'), RenewalStatus.rejected);
    });

    test('fromString of unknown value falls back to pending', () {
      expect(RenewalStatus.fromString('unknown_xyz'), RenewalStatus.pending);
    });
  });

  // ── NotificationType enum ─────────────────────────────────────────────────

  group('NotificationType', () {
    test('renewalFollowUp value converts to snake_case correctly', () {
      expect(NotificationType.renewalFollowUp.value, 'renewal_follow_up');
    });

    test('renewalRequest value is renewal_request', () {
      expect(NotificationType.renewalRequest.value, 'renewal_request');
    });

    test('renewalApproved value is renewal_approved', () {
      expect(NotificationType.renewalApproved.value, 'renewal_approved');
    });

    test('renewalRejected value is renewal_rejected', () {
      expect(NotificationType.renewalRejected.value, 'renewal_rejected');
    });

    test('fromString("renewal_follow_up") returns renewalFollowUp', () {
      expect(
        NotificationType.fromString('renewal_follow_up'),
        NotificationType.renewalFollowUp,
      );
    });

    test('fromString("renewal_request") returns renewalRequest', () {
      expect(
        NotificationType.fromString('renewal_request'),
        NotificationType.renewalRequest,
      );
    });

    test('appointmentCompleted exists in values', () {
      expect(NotificationType.values, contains(NotificationType.appointmentCompleted));
    });

    test('general falls back for unknown string', () {
      expect(NotificationType.fromString('no_such_type'), NotificationType.general);
    });
  });

  // ── Prescription model ────────────────────────────────────────────────────

  group('Prescription.fromJson', () {
    Map<String, dynamic> _base() => {
      'id': 'rx-001',
      'patient_id': 'patient-1',
      'doctor_id': 'doctor-1',
      'appointment_id': null,
      'diagnosis': 'Hypertension',
      'notes': null,
      'status': 'active',
      'issued_date': '2026-01-10',
      'valid_until': '2026-07-10',
      'created_at': '2026-01-10T09:00:00Z',
      'updated_at': '2026-01-10T09:00:00Z',
      'doctors': {
        'specialty': 'Cardiology',
        'profiles': {'full_name': 'Dr. Ayaan', 'avatar_url': null},
      },
      'prescription_items': [
        {
          'id': 'item-1',
          'prescription_id': 'rx-001',
          'medication_name': 'Amlodipine',
          'dosage': '5mg',
          'frequency': 'once daily',
          'duration_days': 180,
          'instructions': 'Take in the morning',
          'quantity': 180,
          'remaining': 90,
          'created_at': '2026-01-10T09:00:00Z',
        },
      ],
    };

    test('parses status as active', () {
      final rx = Prescription.fromJson(_base());
      expect(rx.status, PrescriptionStatus.active);
    });

    test('parses validUntil date', () {
      final rx = Prescription.fromJson(_base());
      expect(rx.validUntil, DateTime(2026, 7, 10));
    });

    test('isExpired returns false when validUntil is in the future', () {
      final rx = Prescription.fromJson(_base());
      // valid_until is 2026-07-10 which is in the future from test date 2026-04-27
      expect(rx.isExpired, isFalse);
    });

    test('isExpired returns true when validUntil is in the past', () {
      final json = _base()..['valid_until'] = '2024-01-01';
      final rx = Prescription.fromJson(json);
      expect(rx.isExpired, isTrue);
    });

    test('isExpired returns false when validUntil is null', () {
      final json = _base()..['valid_until'] = null;
      final rx = Prescription.fromJson(json);
      expect(rx.isExpired, isFalse);
    });

    test('isNearExpiry returns true when expires within 30 days', () {
      final soon = DateTime.now().add(const Duration(days: 15));
      final dateStr = '${soon.year}-${soon.month.toString().padLeft(2, '0')}-${soon.day.toString().padLeft(2, '0')}';
      final json = _base()..['valid_until'] = dateStr;
      final rx = Prescription.fromJson(json);
      expect(rx.isNearExpiry, isTrue);
    });

    test('isNearExpiry returns false when more than 30 days remain', () {
      final far = DateTime.now().add(const Duration(days: 60));
      final dateStr = '${far.year}-${far.month.toString().padLeft(2, '0')}-${far.day.toString().padLeft(2, '0')}';
      final json = _base()..['valid_until'] = dateStr;
      final rx = Prescription.fromJson(json);
      expect(rx.isNearExpiry, isFalse);
    });

    test('parses items list', () {
      final rx = Prescription.fromJson(_base());
      expect(rx.items?.length, 1);
      expect(rx.items?.first.medicationName, 'Amlodipine');
    });

    test('parses doctor name from nested join', () {
      final rx = Prescription.fromJson(_base());
      expect(rx.doctorName, 'Dr. Ayaan');
      expect(rx.doctorSpecialty, 'Cardiology');
    });
  });

  // ── PrescriptionItem model ─────────────────────────────────────────────────

  group('PrescriptionItem.fromJson', () {
    final itemJson = {
      'id': 'item-1',
      'prescription_id': 'rx-001',
      'medication_name': 'Metformin',
      'dosage': '500mg',
      'frequency': 'twice daily',
      'duration_days': 90,
      'instructions': 'Take with food',
      'quantity': 180,
      'remaining': 60,
      'created_at': '2026-01-15T10:00:00Z',
    };

    test('parses all fields', () {
      final item = PrescriptionItem.fromJson(itemJson);
      expect(item.medicationName, 'Metformin');
      expect(item.dosage, '500mg');
      expect(item.frequency, 'twice daily');
      expect(item.durationDays, 90);
      expect(item.quantity, 180);
      expect(item.remaining, 60);
    });

    test('remaining defaults to quantity when absent', () {
      final json = Map<String, dynamic>.from(itemJson)..remove('remaining');
      final item = PrescriptionItem.fromJson(json);
      expect(item.remaining, 180);
    });

    test('quantity is null when absent', () {
      final json = Map<String, dynamic>.from(itemJson)
        ..remove('quantity')
        ..remove('remaining');
      final item = PrescriptionItem.fromJson(json);
      expect(item.quantity, isNull);
    });
  });

  // ── Renewal notification message logic ───────────────────────────────────

  group('Renewal notification copy', () {
    String _bodyFor(RenewalStatus status, {String? notes}) {
      switch (status) {
        case RenewalStatus.approved:
          return 'Your doctor approved your prescription renewal. Your medication is ready.';
        case RenewalStatus.rejected:
          return notes != null && notes.isNotEmpty
              ? 'Renewal denied: $notes'
              : 'Your doctor declined the prescription renewal request.';
        case RenewalStatus.followUp:
          return notes != null && notes.isNotEmpty
              ? 'Your doctor needs a follow-up: $notes'
              : 'Your doctor has requested a follow-up before renewing your prescription.';
        default:
          return '';
      }
    }

    test('approved body is correct', () {
      final body = _bodyFor(RenewalStatus.approved);
      expect(body, contains('approved'));
    });

    test('rejected body without notes is generic', () {
      final body = _bodyFor(RenewalStatus.rejected);
      expect(body, contains('declined'));
    });

    test('rejected body with notes includes notes', () {
      final body = _bodyFor(RenewalStatus.rejected, notes: 'Dosage too high');
      expect(body, contains('Dosage too high'));
    });

    test('followUp body without notes is generic', () {
      final body = _bodyFor(RenewalStatus.followUp);
      expect(body, contains('follow-up'));
    });

    test('followUp body with notes includes notes', () {
      final body = _bodyFor(RenewalStatus.followUp, notes: 'Blood pressure check needed');
      expect(body, contains('Blood pressure check needed'));
    });

    test('other statuses return empty body (not sent)', () {
      expect(_bodyFor(RenewalStatus.pending), isEmpty);
    });
  });
}
