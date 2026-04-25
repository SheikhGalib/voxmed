import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:voxmed/core/constants/app_constants.dart';

void main() {
  group('UserRole enum', () {
    test('doctor role string matches expected value', () {
      expect(UserRole.doctor.value, 'doctor');
    });

    test('patient role string matches expected value', () {
      expect(UserRole.patient.value, 'patient');
    });

    test('fromString returns doctor for "doctor"', () {
      expect(UserRole.fromString('doctor'), UserRole.doctor);
    });

    test('fromString returns patient for "patient"', () {
      expect(UserRole.fromString('patient'), UserRole.patient);
    });

    test('fromString defaults to patient for unknown role', () {
      expect(UserRole.fromString('admin'), UserRole.patient);
      expect(UserRole.fromString(''), UserRole.patient);
    });
  });

  group('System prompts JSON', () {
    late Map<String, dynamic> prompts;

    setUpAll(() {
      final file = File('supabase/functions/gemini-triage/system_prompts.json');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'system_prompts.json must exist',
      );
      prompts = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('contains patient and doctor keys', () {
      expect(prompts.containsKey('patient'), isTrue);
      expect(prompts.containsKey('doctor'), isTrue);
    });

    test('patient prompt identifies as Care Guide', () {
      final patient = prompts['patient'] as String;
      expect(patient, contains('VoxMed Care Guide'));
      expect(patient, contains('triage'));
    });

    test('doctor prompt identifies as Clinical Copilot', () {
      final doctor = prompts['doctor'] as String;
      expect(doctor, contains('VoxMed Clinical Copilot'));
      expect(doctor, contains('productivity'));
    });

    test('patient and doctor prompts are different', () {
      expect(prompts['patient'], isNot(equals(prompts['doctor'])));
    });

    test('both prompts contain safety rules', () {
      final patient = prompts['patient'] as String;
      final doctor = prompts['doctor'] as String;
      expect(patient.toLowerCase(), contains('safety'));
      expect(doctor.toLowerCase(), contains('safety'));
    });
  });

  group('AI role detection logic', () {
    // Mirrors the logic in AiAssistantScreen.initState and
    // gemini-triage edge function for role selection.

    bool isDoctor(Map<String, dynamic>? userMetadata) {
      final role = userMetadata?['role'] as String?;
      return role == UserRole.doctor.value;
    }

    String selectPrompt(Map<String, dynamic> prompts, bool isDoctorRole) {
      return isDoctorRole
          ? prompts['doctor'] as String
          : prompts['patient'] as String;
    }

    test('patient metadata selects patient role', () {
      final metadata = {'role': 'patient', 'full_name': 'John Doe'};
      expect(isDoctor(metadata), isFalse);
    });

    test('doctor metadata selects doctor role', () {
      final metadata = {'role': 'doctor', 'full_name': 'Dr. Smith'};
      expect(isDoctor(metadata), isTrue);
    });

    test('null metadata defaults to patient', () {
      expect(isDoctor(null), isFalse);
    });

    test('missing role key defaults to patient', () {
      final metadata = {'full_name': 'Someone'};
      expect(isDoctor(metadata), isFalse);
    });

    test('correct prompt selected for doctor', () {
      final prompts = {'patient': 'patient prompt', 'doctor': 'doctor prompt'};
      expect(selectPrompt(prompts, true), 'doctor prompt');
    });

    test('correct prompt selected for patient', () {
      final prompts = {'patient': 'patient prompt', 'doctor': 'doctor prompt'};
      expect(selectPrompt(prompts, false), 'patient prompt');
    });
  });
}
