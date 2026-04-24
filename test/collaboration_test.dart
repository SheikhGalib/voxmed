import 'package:flutter_test/flutter_test.dart';
import 'package:voxmed/core/constants/app_constants.dart';
import 'package:voxmed/core/theme/app_colors.dart';
import 'package:voxmed/repositories/collaboration_repository.dart';
import 'package:flutter/material.dart';

void main() {
  group('DoctorColors', () {
    test('primary is blue 800', () {
      expect(DoctorColors.primary, const Color(0xFF1565C0));
    });
    test('primaryContainer is blue 50', () {
      expect(DoctorColors.primaryContainer, const Color(0xFFE3F2FD));
    });
    test('border is non-null', () {
      expect(DoctorColors.border, isNotNull);
    });
    test('onPrimary is white', () {
      expect(DoctorColors.onPrimary, Colors.white);
    });
  });

  group('AppRoutes — doctor routes', () {
    test('doctorChat route is correct', () {
      expect(AppRoutes.doctorChat, '/doctor-chat');
    });
    test('doctorSchedule route is correct', () {
      expect(AppRoutes.doctorSchedule, '/doctor-schedule');
    });
    test('approvalQueue route is correct', () {
      expect(AppRoutes.approvalQueue, '/approval-queue');
    });
    test('collaborativeHub route is correct', () {
      expect(AppRoutes.collaborativeHub, '/collaborative-hub');
    });
    test('myPatients route is correct', () {
      expect(AppRoutes.myPatients, '/my-patients');
    });
  });

  group('RenewalStatus enum', () {
    test('fromString returns pending for unknown', () {
      final result = RenewalStatus.fromString('unknown_value');
      expect(result, RenewalStatus.pending);
    });
    test('fromString parses approved', () {
      expect(RenewalStatus.fromString('approved'), RenewalStatus.approved);
    });
    test('fromString parses rejected', () {
      expect(RenewalStatus.fromString('rejected'), RenewalStatus.rejected);
    });
  });

  group('CollaborationRepository', () {
    test('instantiates without error', () {
      final repo = CollaborationRepository();
      expect(repo, isNotNull);
    });
  });
}
