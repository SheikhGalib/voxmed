import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/utils/error_handler.dart';

/// Repository for authentication operations.
class AuthRepository {
  /// Sign up with email, password, full name, and role.
  /// The database trigger `handle_new_user()` automatically creates
  /// a profile row using the metadata.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      return await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
        },
      );
    } on AuthException catch (e) {
      throw AppException.fromAuthException(e);
    } catch (e) {
      throw AppException(message: 'Sign up failed: $e');
    }
  }

  /// Sign in with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AppException.fromAuthException(e);
    } catch (e) {
      throw AppException(message: 'Sign in failed: $e');
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      throw AppException.fromAuthException(e);
    } catch (e) {
      throw AppException(message: 'Sign out failed: $e');
    }
  }

  /// Get the current session (null if not logged in).
  Session? get currentSession => supabase.auth.currentSession;

  /// Get the current user (null if not logged in).
  User? get currentUser => supabase.auth.currentUser;

  /// Stream of auth state changes.
  Stream<AuthState> get onAuthStateChange =>
      supabase.auth.onAuthStateChange;

  /// Whether a user is currently signed in.
  bool get isAuthenticated => currentSession != null;
}
