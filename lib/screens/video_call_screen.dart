import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../core/config/supabase_config.dart';
import '../core/config/zego_config.dart';
import '../core/theme/app_colors.dart';
import '../models/video_call.dart';
import '../providers/video_call_provider.dart';

/// Video call screen — wraps the ZEGOCLOUD Prebuilt Call UIKit.
///
/// Pass the [roomId] (ZEGOCLOUD call ID) and optionally the [videoCallId]
/// (Supabase video_calls row id) so we can update status on join/end.
class VideoCallScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String? videoCallId;

  const VideoCallScreen({
    super.key,
    required this.roomId,
    this.videoCallId,
  });

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  @override
  void initState() {
    super.initState();
    _markInProgress();
  }

  Future<void> _markInProgress() async {
    if (widget.videoCallId != null) {
      try {
        final repo = ref.read(videoCallRepositoryProvider);
        await repo.updateStatus(
          widget.videoCallId!,
          VideoCallStatus.inProgress,
        );
      } catch (_) {}
    }
  }

  Future<void> _markCompleted() async {
    if (widget.videoCallId != null) {
      try {
        final repo = ref.read(videoCallRepositoryProvider);
        await repo.completeCall(widget.videoCallId!);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video Call')),
        body: const Center(child: Text('Not authenticated')),
      );
    }

    if (!ZegoConfig.isConfigured) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            'Video Call',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.videocam_off,
                    size: 56,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Video Calling Not Configured',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please configure ZEGO_APP_ID and ZEGO_APP_SIGN in your .env file to enable video calling.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Room: ${widget.roomId}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final userId = user.id;
    final userName =
        user.userMetadata?['full_name'] as String? ?? user.email ?? 'User';

    return ZegoUIKitPrebuiltCall(
      appID: ZegoConfig.appID,
      appSign: ZegoConfig.appSign,
      userID: userId,
      userName: userName,
      callID: widget.roomId,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        ..duration = ZegoCallDurationConfig(
          isVisible: true,
        )
        ..topMenuBar = ZegoCallTopMenuBarConfig(
          isVisible: true,
          buttons: [
            ZegoCallMenuBarButtonName.minimizingButton,
            ZegoCallMenuBarButtonName.showMemberListButton,
          ],
        ),
      events: ZegoUIKitPrebuiltCallEvents(
        onHangUpConfirmation: (
          ZegoCallHangUpConfirmationEvent event,
          Future<bool> Function() defaultAction,
        ) async {
          return await showDialog<bool>(
                context: event.context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  title: Text(
                    'End Consultation?',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  content: const Text(
                    'Are you sure you want to end this video call?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('End Call'),
                    ),
                  ],
                ),
              ) ??
              false;
        },
        onCallEnd: (ZegoCallEndEvent event, VoidCallback defaultAction) {
          _markCompleted();
          // Invalidate providers so UI reflects updated status
          ref.invalidate(activeVideoCallsProvider);
          defaultAction.call();
        },
      ),
    );
  }
}
