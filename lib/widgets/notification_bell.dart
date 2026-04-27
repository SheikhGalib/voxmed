import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';

/// Bell icon with unread badge. Tapping shows a floating panel
/// anchored just below the icon with the 3 most-recent notifications
/// and a "See All" button.
class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _toggleOverlay() {
    if (_overlay != null) {
      _removeOverlay();
      return;
    }

    final notifications = ref.read(notificationsProvider).valueOrNull ?? [];
    final top3 = notifications.take(3).toList();

    _overlay = OverlayEntry(
      builder: (context) => _NotificationPanel(
        layerLink: _layerLink,
        notifications: top3,
        onClose: _removeOverlay,
        onMarkRead: (id) => ref.read(notificationsProvider.notifier).markAsRead(id),
        onSeeAll: () {
          _removeOverlay();
          context.push(AppRoutes.notifications);
        },
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadNotificationCountProvider);

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleOverlay,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_outlined,
                color: AppColors.onSurface,
                size: 26,
              ),
              if (unread > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Floating Panel ───────────────────────────────────────────────────────────

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel({
    required this.layerLink,
    required this.notifications,
    required this.onClose,
    required this.onMarkRead,
    required this.onSeeAll,
  });

  final LayerLink layerLink;
  final List<NotificationModel> notifications;
  final VoidCallback onClose;
  final void Function(String id) onMarkRead;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Invisible full-screen tap-to-dismiss layer
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        // The panel itself, anchored below the bell
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: const Offset(-240, 48),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
                    child: Row(
                      children: [
                        Text(
                          'Notifications',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onClose,
                          child: Icon(Icons.close, size: 18, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.surfaceContainerHigh),

                  // Notification items
                  if (notifications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Center(
                        child: Text(
                          'No notifications yet',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ...notifications.map((n) => _NotificationTile(
                          notification: n,
                          onTap: () => onMarkRead(n.id),
                        )),

                  // See All
                  const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                  InkWell(
                    onTap: onSeeAll,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'See all notifications',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Single Tile ──────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isRead ? Colors.transparent : AppColors.primaryContainer.withOpacity(0.18),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _iconBg(notification.type),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconFor(notification.type), size: 18, color: _iconColor(notification.type)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.manrope(
                      fontSize: 12.5,
                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.body != null && notification.body!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notification.body!,
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: GoogleFonts.manrope(
                      fontSize: 10.5,
                      color: AppColors.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentReminder:
      case NotificationType.appointmentRescheduled:
      case NotificationType.appointmentCompleted:
        return Icons.calendar_today_outlined;
      case NotificationType.appointmentCancelled:
        return Icons.cancel_outlined;
      case NotificationType.medicationReminder:
        return Icons.medication_outlined;
      case NotificationType.renewalRequest:
      case NotificationType.renewalApproved:
      case NotificationType.renewalRejected:
      case NotificationType.renewalFollowUp:
        return Icons.autorenew_outlined;
      case NotificationType.newLabResult:
        return Icons.science_outlined;
      case NotificationType.consultationInvite:
        return Icons.video_call_outlined;
      case NotificationType.aiTriageResult:
        return Icons.smart_toy_outlined;
      case NotificationType.doctorAbsence:
        return Icons.person_off_outlined;
      case NotificationType.general:
        return Icons.notifications_outlined;
    }
  }

  Color _iconBg(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentCancelled:
      case NotificationType.renewalRejected:
        return AppColors.errorContainer.withOpacity(0.35);
      case NotificationType.renewalApproved:
      case NotificationType.newLabResult:
        return AppColors.primaryContainer.withOpacity(0.5);
      case NotificationType.medicationReminder:
        return AppColors.secondaryContainer.withOpacity(0.5);
      default:
        return AppColors.surfaceContainerHigh;
    }
  }

  Color _iconColor(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentCancelled:
      case NotificationType.renewalRejected:
        return AppColors.error;
      case NotificationType.renewalApproved:
      case NotificationType.newLabResult:
        return AppColors.primary;
      case NotificationType.medicationReminder:
        return AppColors.secondary;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
