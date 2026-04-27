import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../widgets/voxmed_app_bar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VoxmedAppBar(
        title: 'Notifications',
        showBackButton: true,
        showAvatar: false,
        actions: [
          notifAsync.maybeWhen(
            data: (list) {
              final hasUnread = list.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).markAllAsRead(),
                child: Text(
                  'Mark all read',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load notifications',
              style: GoogleFonts.manrope(color: AppColors.onSurfaceVariant)),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 56, color: AppColors.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "You're all caught up!",
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.outlineVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.surfaceContainerHigh,
              ),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _NotificationListTile(
                  notification: n,
                  onTap: () {
                    if (!n.isRead) {
                      ref
                          .read(notificationsProvider.notifier)
                          .markAsRead(n.id);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationListTile extends StatelessWidget {
  const _NotificationListTile({
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isRead
            ? Colors.transparent
            : AppColors.primaryContainer.withOpacity(0.15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg(notification.type),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconFor(notification.type),
                  size: 22, color: _iconColor(notification.type)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(notification.createdAt),
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppColors.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                  if (notification.body != null &&
                      notification.body!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      notification.body!,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (!notification.isRead)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 8),
                child: Container(
                  width: 8,
                  height: 8,
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
