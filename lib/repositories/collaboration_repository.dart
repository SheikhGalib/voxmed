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
  Future<String> getOrCreateChatSession(
      String currentDoctorId, String otherDoctorId) async {
    try {
      // Look for existing session with both doctors as members
      final myMemberships = await supabase
          .from(Tables.consultationMembers)
          .select('session_id')
          .eq('doctor_id', currentDoctorId);

      final mySessionIds = (myMemberships as List)
          .map((m) => m['session_id'] as String)
          .toList();

      if (mySessionIds.isNotEmpty) {
        final otherMemberships = await supabase
            .from(Tables.consultationMembers)
            .select('session_id')
            .eq('doctor_id', otherDoctorId)
            .inFilter('session_id', mySessionIds);

        final sharedIds = (otherMemberships as List)
            .map((m) => m['session_id'] as String)
            .toList();

        // Verify session is a doctor-chat type (title starts with 'dr_chat:')
        for (final sid in sharedIds) {
          final session = await supabase
              .from(Tables.consultationSessions)
              .select('id, title')
              .eq('id', sid)
              .maybeSingle();
          if (session != null &&
              (session['title'] as String? ?? '').startsWith('dr_chat:')) {
            return sid;
          }
        }
      }

      // Create new session — patient_id is nullable (doctor chat has no patient)
      final sessionData = await supabase
          .from(Tables.consultationSessions)
          .insert({
            'title': 'dr_chat:${[currentDoctorId, otherDoctorId]..sort()..join(':')}',
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
