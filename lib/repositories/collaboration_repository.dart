import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';

/// Repository for doctor-to-doctor collaboration features.
/// Uses consultation_sessions + consultation_messages to store chats.
/// See DB changes section in docs for recommended schema additions.
class CollaborationRepository {
  static const String _doctorColumns =
      'id, specialty, profiles(full_name, avatar_url), hospitals(name)';

  /// List all doctors except the current user (for collaboration hub).
  Future<List<Map<String, dynamic>>> listPeerDoctors() async {
    final currentUid = supabase.auth.currentUser?.id;
    if (currentUid == null) throw const AppException(message: 'Not authenticated');

    try {
      final data = await supabase
          .from(Tables.doctors)
          .select(_doctorColumns)
          .neq('profile_id', currentUid)
          .eq('status', 'approved')
          .order('specialty');
      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load peer doctors: $e');
    }
  }

  /// Get or create a direct chat session between two doctors.
  /// Returns the session id.
  ///
  /// Uses a deterministic title lookup on consultation_sessions instead of
  /// a cross-membership query. The old two-step approach queried
  /// consultation_members for the OTHER doctor's rows, but migration 007's
  /// members_select policy only allows seeing your OWN rows
  /// (doctor_id = get_my_doctor_id()), so that query always returned 0 rows
  /// and a new session was created every time — breaking message persistence.
  ///
  /// The sessions_select policy DOES allow seeing sessions you are a member
  /// of (via the id IN consultation_members branch), so querying by the
  /// deterministic title works correctly for both the creator and the other
  /// doctor.
  Future<String> getOrCreateChatSession(
      String currentDoctorId, String otherDoctorId) async {
    try {
      // Deterministic title — sorted so A→B and B→A resolve to the same key.
      final title =
          'dr_chat:${([currentDoctorId, otherDoctorId]..sort()).join(':')}';

      // Single lookup: sessions_select allows this doctor to see any session
      // where they are a member, so both the creator and the invited doctor
      // will find the same row here.
      final existing = await supabase
          .from(Tables.consultationSessions)
          .select('id')
          .eq('title', title)
          .maybeSingle();

      if (existing != null) {
        return existing['id'] as String;
      }

      // No existing session — create one.
      final sessionData = await supabase
          .from(Tables.consultationSessions)
          .insert({
            'title': title,
            'notes': '',
            'created_by': currentDoctorId,
          })
          .select('id')
          .single();

      final sessionId = sessionData['id'] as String;

      await supabase.from(Tables.consultationMembers).insert([
        {'session_id': sessionId, 'doctor_id': currentDoctorId, 'role': 'primary'},
        {'session_id': sessionId, 'doctor_id': otherDoctorId, 'role': 'consultant'},
      ]);

      return sessionId;
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to open chat: $e');
    }
  }

  /// Send a message in a session.
  Future<void> sendMessage({
    required String sessionId,
    required String senderDoctorId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      await supabase.from(Tables.consultationMessages).insert({
        'session_id': sessionId,
        'sender_id': senderDoctorId,
        'content': content,
        'message_type': messageType,
      });
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to send message: $e');
    }
  }

  /// Get messages for a session (oldest first).
  Future<List<Map<String, dynamic>>> getMessages(String sessionId) async {
    try {
      final data = await supabase
          .from(Tables.consultationMessages)
          .select('id, sender_id, content, message_type, created_at')
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load messages: $e');
    }
  }
}
