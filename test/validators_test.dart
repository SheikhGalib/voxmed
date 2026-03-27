import 'package:flutter_test/flutter_test.dart';
import 'package:voxmed/core/utils/validators.dart';

void main() {
  group('Email Validator', () {
    test('returns error for empty email', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email(null), 'Email is required');
      expect(Validators.email('   '), 'Email is required');
    });

    test('returns error for invalid email', () {
      expect(Validators.email('notanemail'), 'Enter a valid email address');
      expect(Validators.email('missing@'), 'Enter a valid email address');
      expect(Validators.email('@missing.com'), 'Enter a valid email address');
      expect(Validators.email('spaces in@email.com'), 'Enter a valid email address');
    });

    test('returns null for valid email', () {
      expect(Validators.email('test@example.com'), isNull);
      expect(Validators.email('user.name+tag@domain.co'), isNull);
      expect(Validators.email('doctor@hospital.org'), isNull);
    });
  });

  group('Password Validator', () {
    test('returns error for empty password', () {
      expect(Validators.password(''), 'Password is required');
      expect(Validators.password(null), 'Password is required');
    });

    test('returns error for short password', () {
      expect(Validators.password('12345'), 'Password must be at least 6 characters');
      expect(Validators.password('ab'), 'Password must be at least 6 characters');
    });

    test('returns null for valid password', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('strongpassword'), isNull);
    });
  });

  group('Confirm Password Validator', () {
    test('returns error when empty', () {
      expect(Validators.confirmPassword('', 'pass'), 'Please confirm your password');
      expect(Validators.confirmPassword(null, 'pass'), 'Please confirm your password');
    });

    test('returns error when mismatch', () {
      expect(Validators.confirmPassword('abc', 'def'), 'Passwords do not match');
    });

    test('returns null when matching', () {
      expect(Validators.confirmPassword('password', 'password'), isNull);
    });
  });

  group('Name Validator', () {
    test('returns error for empty name', () {
      expect(Validators.name(''), 'Name is required');
      expect(Validators.name(null), 'Name is required');
      expect(Validators.name(' '), 'Name is required');
    });

    test('returns error for very short name', () {
      expect(Validators.name('A'), 'Name must be at least 2 characters');
    });

    test('returns null for valid name', () {
      expect(Validators.name('Dr. Smith'), isNull);
      expect(Validators.name('Adrian'), isNull);
    });
  });

  group('Phone Validator', () {
    test('returns null for empty (optional)', () {
      expect(Validators.phone(''), isNull);
      expect(Validators.phone(null), isNull);
    });

    test('returns error for invalid phone', () {
      expect(Validators.phone('abc'), 'Enter a valid phone number');
      expect(Validators.phone('12'), 'Enter a valid phone number');
    });

    test('returns null for valid phone', () {
      expect(Validators.phone('+8801712345678'), isNull);
      expect(Validators.phone('1234567890'), isNull);
    });
  });

  group('Required Validator', () {
    test('returns error with field name', () {
      expect(Validators.required('', 'Specialty'), 'Specialty is required');
      expect(Validators.required(null), 'This field is required');
    });

    test('returns null for non-empty', () {
      expect(Validators.required('value'), isNull);
    });
  });
}
