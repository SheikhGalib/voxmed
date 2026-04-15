import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../models/video_call.dart';
import '../repositories/video_call_repository.dart';

/// Provides the VideoCallRepository instance.
final videoCallRepositoryProvider = Provider<VideoCallRepository>((ref) {
  return VideoCallRepository();
});

/// Active (joinable) video calls for the current user.
final activeVideoCallsProvider = FutureProvider<List<VideoCall>>((ref) async {
  final repo = ref.read(videoCallRepositoryProvider);
  return repo.listActive();
});

/// Video call for a specific appointment.
final videoCallByAppointmentProvider =
    FutureProvider.family<VideoCall?, String>((ref, appointmentId) async {
  final repo = ref.read(videoCallRepositoryProvider);
  return repo.getByAppointment(appointmentId);
});

/// Create a video call room when booking a video appointment.
Future<VideoCall?> createVideoCallForAppointment({
  required VideoCallRepository repo,
  required String appointmentId,
  required String patientId,
  required String doctorId,
}) async {
  try {
    return await repo.createVideoCall(
      appointmentId: appointmentId,
      patientId: patientId,
      doctorId: doctorId,
    );
  } catch (_) {
    return null;
  }
}
