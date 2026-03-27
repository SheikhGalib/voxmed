import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import '../models/user_profile.dart';

/// Provides the AuthRepository instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provides the ProfileRepository instance.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Streams auth state changes (login, logout, token refresh).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).onAuthStateChange;
});

/// Provides the current user's profile (null if not logged in).
/// Auto-refreshes when auth state changes.
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  // Watch auth state so profile refreshes on login/logout
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (state) async {
      if (state.session == null) return null;
      try {
        return await ref.read(profileRepositoryProvider).getCurrentUserProfile();
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

/// Whether the user is currently authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.read(authRepositoryProvider).isAuthenticated;
});
