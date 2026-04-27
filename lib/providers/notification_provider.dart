import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../models/notification_model.dart';
import '../repositories/notification_service.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

// ─── Notifier ────────────────────────────────────────────────────────────────

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  RealtimeChannel? _channel;

  @override
  Future<List<NotificationModel>> build() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // Subscribe to real-time inserts so new notifications appear instantly
    _channel?.unsubscribe();
    _channel = supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: Tables.notifications,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            // Show OS push notification for the new record
            final record = payload.newRecord;
            final title = record['title'] as String? ?? 'New notification';
            final body = record['body'] as String?;
            NotificationService().showPush(
              title: title,
              body: body ?? '',
            );
            _reload();
          },
        )
        .subscribe();

    ref.onDispose(() => _channel?.unsubscribe());

    return _fetch(userId);
  }

  Future<List<NotificationModel>> _fetch(String userId) async {
    final rows = await supabase
        .from(Tables.notifications)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (rows as List)
        .map((r) => NotificationModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> _reload() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    state = await AsyncValue.guard(() => _fetch(userId));
  }

  Future<void> refresh() => _reload();

  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from(Tables.notifications)
        .update({'is_read': true})
        .eq('id', notificationId);
    await _reload();
  }

  Future<void> markAllAsRead() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase
        .from(Tables.notifications)
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
    await _reload();
  }
}
