import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/video_call.dart';

/// Repository for video call room management.
class VideoCallRepository {
  static const String _tableName = 'video_calls';

  static const String _columns =
      'id, appointment_id, room_id, patient_id, doctor_id, status, '
      'started_at, ended_at, duration_seconds, created_at, updated_at';

  /// Create a video call room for an appointment.
  Future<VideoCall> createVideoCall({
    required String appointmentId,
    required String patientId,
    required String doctorId,
  }) async {
    // Generate a unique room ID from appointment ID + timestamp
    final roomId =
        'voxmed_${appointmentId.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final result = await supabase
          .from(_tableName)
          .insert({
            'appointment_id': appointmentId,
            'room_id': roomId,
            'patient_id': patientId,
            'doctor_id': doctorId,
            'status': VideoCallStatus.pending.value,
          })
          .select(_columns)
          .single();
      return VideoCall.fromJson(result);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to create video call: $e');
    }
  }

  /// Get video call for an appointment.
  Future<VideoCall?> getByAppointment(String appointmentId) async {
    try {
      final data = await supabase
          .from(_tableName)
          .select(_columns)
          .eq('appointment_id', appointmentId)
          .maybeSingle();
      if (data == null) return null;
      return VideoCall.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load video call: $e');
    }
  }

  /// Get video call by room ID.
  Future<VideoCall?> getByRoomId(String roomId) async {
    try {
      final data = await supabase
          .from(_tableName)
          .select(_columns)
          .eq('room_id', roomId)
          .maybeSingle();
      if (data == null) return null;
      return VideoCall.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load video call: $e');
    }
  }

  /// Update video call status.
  Future<void> updateStatus(String callId, VideoCallStatus status) async {
    final updates = <String, dynamic>{
      'status': status.value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (status == VideoCallStatus.inProgress) {
      updates['started_at'] = DateTime.now().toUtc().toIso8601String();
    } else if (status == VideoCallStatus.completed ||
        status == VideoCallStatus.missed) {
      updates['ended_at'] = DateTime.now().toUtc().toIso8601String();
    }

    try {
      await supabase.from(_tableName).update(updates).eq('id', callId);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to update video call: $e');
    }
  }

  /// Mark call as completed with duration.
  Future<void> completeCall(String callId) async {
    try {
      // Fetch the call to calculate duration
      final call = await supabase
          .from(_tableName)
          .select('started_at')
          .eq('id', callId)
          .maybeSingle();

      final now = DateTime.now().toUtc();
      int? duration;
      if (call != null && call['started_at'] != null) {
        final startedAt = DateTime.parse(call['started_at'] as String);
        duration = now.difference(startedAt).inSeconds;
      }

      await supabase.from(_tableName).update({
        'status': VideoCallStatus.completed.value,
        'ended_at': now.toIso8601String(),
        'duration_seconds': ?duration,
        'updated_at': now.toIso8601String(),
      }).eq('id', callId);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to complete video call: $e');
    }
  }

  /// List active (joinable) video calls for the current user.
  Future<List<VideoCall>> listActive() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      // Check as patient first
      final patientCalls = await supabase
          .from(_tableName)
          .select(_columns)
          .eq('patient_id', uid)
          .inFilter('status', ['pending', 'ringing', 'in_progress'])
          .order('created_at', ascending: false);

      // Check as doctor (profile_id → doctors.id)
      final doctorRow = await supabase
          .from(Tables.doctors)
          .select('id')
          .eq('profile_id', uid)
          .maybeSingle();

      List<dynamic> doctorCalls = [];
      if (doctorRow != null) {
        doctorCalls = await supabase
            .from(_tableName)
            .select(_columns)
            .eq('doctor_id', doctorRow['id'])
            .inFilter('status', ['pending', 'ringing', 'in_progress'])
            .order('created_at', ascending: false);
      }

      // Merge and deduplicate
      final allIds = <String>{};
      final merged = <VideoCall>[];
      for (final row in [...patientCalls, ...doctorCalls]) {
        final vc = VideoCall.fromJson(row);
        if (allIds.add(vc.id)) merged.add(vc);
      }
      return merged;
    } catch (e) {
      return [];
    }
  }
}
