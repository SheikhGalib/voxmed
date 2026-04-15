import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Typed application exception used across the app.
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => 'AppException($code): $message';

  /// Create from a Supabase AuthException.
  factory AppException.fromAuthException(AuthException e) {
    return AppException(
      message: _friendlyAuthMessage(e.message),
      code: e.statusCode,
    );
  }

  /// Create from a PostgrestException.
  factory AppException.fromPostgrestException(PostgrestException e) {
    return AppException(
      message: e.message,
      code: e.code,
    );
  }

  /// Convert generic auth error messages to user-friendly text.
  static String _friendlyAuthMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lower.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    if (lower.contains('password') && lower.contains('short')) {
      return 'Password must be at least 6 characters.';
    }
    return message;
  }
}

/// Show a themed error SnackBar.
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Show a themed success SnackBar.
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}
