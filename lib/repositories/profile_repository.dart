import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/user_profile.dart';

/// Repository for user profile CRUD operations.
class ProfileRepository {
  /// Get a profile by user ID.
  Future<UserProfile> getProfile(String userId) async {
    try {
      final data = await supabase
          .from(Tables.profiles)
          .select()
          .eq('id', userId)
          .single();
      return UserProfile.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load profile: $e');
    }
  }

  /// Get the current logged-in user's profile.
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    return getProfile(user.id);
  }

  /// Update a profile.
  Future<UserProfile> updateProfile(String userId, Map<String, dynamic> updates) async {
    try {
      final data = await supabase
          .from(Tables.profiles)
          .update(updates)
          .eq('id', userId)
          .select()
          .single();
      return UserProfile.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to update profile: $e');
    }
  }
}
