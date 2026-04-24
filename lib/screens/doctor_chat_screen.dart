import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../repositories/collaboration_repository.dart';
import '../providers/doctor_provider.dart';
import '../providers/patient_provider.dart';
import '../core/config/supabase_config.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _collabRepoForChatProvider = Provider((_) => CollaborationRepository());

final chatSessionProvider =
    FutureProvider.family<String, ({String myDoctorId, String otherDoctorId})>((ref, p) async {
  return ref.read(_collabRepoForChatProvider).getOrCreateChatSession(p.myDoctorId, p.otherDoctorId);
});

/// StreamProvider that uses Supabase Realtime .stream() — messages arrive
/// automatically as other doctors send them (no manual refresh needed).
final chatMessagesStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, sessionId) {
  return supabase
      .from(Tables.consultationMessages)
      .stream(primaryKey: ['id'])
      .eq('session_id', sessionId)
      .order('created_at', ascending: true)
      .map((rows) => List<Map<String, dynamic>>.from(rows));
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class DoctorChatScreen extends ConsumerStatefulWidget {
  final String otherDoctorId;
  final String otherDoctorName;
  final String otherDoctorSpecialty;

  const DoctorChatScreen({
    super.key,
    required this.otherDoctorId,
    required this.otherDoctorName,
    required this.otherDoctorSpecialty,
  });

  @override
  ConsumerState<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends ConsumerState<DoctorChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(currentDoctorProvider);

    return doctorAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text(e.toString()))),
      data: (myDoctor) {
        if (myDoctor == null) return const Scaffold(body: Center(child: Text('Not authenticated')));

        final sessionAsync = ref.watch(chatSessionProvider(
            (myDoctorId: myDoctor.id, otherDoctorId: widget.otherDoctorId)));

        return Scaffold(
          backgroundColor: const Color(0xFFF5F9FF),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
              onPressed: () => context.pop(),
            ),
            titleSpacing: 0,
            title: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: DoctorColors.primaryContainer,
                child: Text(
                  widget.otherDoctorName.isNotEmpty ? widget.otherDoctorName[0].toUpperCase() : 'D',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: DoctorColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.otherDoctorName, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                if (widget.otherDoctorSpecialty.isNotEmpty)
                  Text(widget.otherDoctorSpecialty, style: GoogleFonts.inter(fontSize: 11, color: DoctorColors.primary)),
              ])),
            ]),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.onSurface),
                onSelected: (v) {
                  if (v == 'share_patient') _showSharePatientSheet(context, myDoctor.id, sessionAsync.valueOrNull);
                  if (v == 'transfer_patient') _showTransferDialog(context);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'share_patient', child: Text('Share Patient Profile')),
                  const PopupMenuItem(value: 'transfer_patient', child: Text('Transfer Patient')),
                ],
              ),
            ],
          ),
          body: sessionAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off, size: 48, color: AppColors.onSurfaceVariant),
                  const SizedBox(height: 14),
                  Text('Could not open chat', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  const SizedBox(height: 8),
                  Text('This feature requires the consultation_sessions table to allow null patient_id. See docs/doctor_collaboration.md for the required DB migration.',
                      textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: DoctorColors.primary),
                    onPressed: () => ref.refresh(chatSessionProvider((myDoctorId: myDoctor.id, otherDoctorId: widget.otherDoctorId))),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ]),
              ),
            ),
            data: (sessionId) => _buildChatBody(context, myDoctor.id, sessionId),
          ),
        );
      },
    );
  }

  Widget _buildChatBody(BuildContext context, String myDoctorId, String sessionId) {
    final messagesAsync = ref.watch(chatMessagesStreamProvider(sessionId));

    return Column(children: [
      Expanded(
        child: messagesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text('Failed to load messages', style: GoogleFonts.inter(color: AppColors.error))),
          data: (messages) {
            if (messages.isEmpty) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFFBBDEFB)),
                  const SizedBox(height: 14),
                  Text('Start a conversation', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text('Messages are end-to-end within your organisation', style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                ]),
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollCtrl.hasClients) {
                _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
              }
            });
            return ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: messages.length,
              itemBuilder: (ctx, i) {
                final msg = messages[i];
                final isMe = msg['sender_id'] == myDoctorId;
                final type = msg['message_type'] as String? ?? 'text';
                final content = msg['content'] as String? ?? '';
                final createdAt = DateTime.tryParse(msg['created_at'] ?? '');
                final timeStr = createdAt != null ? DateFormat('h:mm a').format(createdAt.toLocal()) : '';

                if (type == 'patient_share') {
                  // Content is "patient:<patientId>:<patientName>"
                  final parts = content.split(':');
                  final patientId = parts.length > 1 ? parts[1] : '';
                  final patientName = parts.length > 2 ? parts.sublist(2).join(':') : 'Patient';
                  return _PatientShareBubble(
                    patientId: patientId, patientName: patientName, isMe: isMe, time: timeStr,
                  );
                }

                return _MessageBubble(content: content, isMe: isMe, time: timeStr);
              },
            );
          },
        ),
      ),
      _buildInputBar(myDoctorId, sessionId),
    ]);
  }

  Widget _buildInputBar(String myDoctorId, String sessionId) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.viewInsetsOf(context).bottom + 12),
      color: Colors.white,
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.person_pin_outlined, color: DoctorColors.primary),
          tooltip: 'Share Patient',
          onPressed: () => _showSharePatientSheet(context, myDoctorId, sessionId),
        ),
        Expanded(
          child: TextField(
            controller: _textCtrl,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: 'Type a message...',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
              filled: true,
              fillColor: DoctorColors.lightBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendMessage(myDoctorId, sessionId),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _sending ? null : () => _sendMessage(myDoctorId, sessionId),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: DoctorColors.primary, shape: BoxShape.circle),
            child: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
          ),
        ),
      ]),
    );
  }

  Future<void> _sendMessage(String myDoctorId, String sessionId) async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    setState(() => _sending = true);
    try {
      await ref.read(_collabRepoForChatProvider).sendMessage(
          sessionId: sessionId, senderDoctorId: myDoctorId, content: text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSharePatientSheet(BuildContext context, String myDoctorId, String? sessionId) {
    if (sessionId == null) return;
    final patientsAsync = ref.read(doctorPatientsProvider(myDoctorId));
    final patients = patientsAsync.valueOrNull ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SharePatientSheet(
        patients: patients,
        onShare: (patientId, patientName) async {
          Navigator.of(context).pop();
          try {
            final content = 'patient:$patientId:$patientName';
            await ref.read(_collabRepoForChatProvider).sendMessage(
                sessionId: sessionId, senderDoctorId: myDoctorId, content: content, messageType: 'patient_share');
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to share: $e'), backgroundColor: AppColors.error),
              );
            }
          }
        },
      ),
    );
  }

  void _showTransferDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Transfer Patient', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        content: Text(
          'To transfer a patient to ${widget.otherDoctorName}, share their profile first, then use the patient detail screen to update the assigned doctor.\n\nThis requires DB-level patient transfer support.',
          style: GoogleFonts.inter(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final String time;
  const _MessageBubble({required this.content, required this.isMe, required this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? DoctorColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(content, style: GoogleFonts.inter(fontSize: 14, color: isMe ? Colors.white : AppColors.onSurface, height: 1.4)),
          const SizedBox(height: 4),
          Text(time, style: GoogleFonts.inter(fontSize: 10, color: isMe ? Colors.white70 : AppColors.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

// ─── Patient Share Bubble ─────────────────────────────────────────────────────

class _PatientShareBubble extends StatelessWidget {
  final String patientId;
  final String patientName;
  final bool isMe;
  final String time;
  const _PatientShareBubble({required this.patientId, required this.patientName, required this.isMe, required this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => context.push('${AppRoutes.patientDetail}?patientId=$patientId'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DoctorColors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DoctorColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.person_pin_outlined, size: 18, color: DoctorColors.primary),
              const SizedBox(width: 8),
              Text('Patient Shared', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: DoctorColors.primary)),
            ]),
            const SizedBox(height: 8),
            Text(patientName, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: Text('Tap to view health card', style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant))),
              const Icon(Icons.open_in_new, size: 14, color: DoctorColors.primary),
            ]),
            const SizedBox(height: 4),
            Text(time, style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

// ─── Share Patient Sheet ──────────────────────────────────────────────────────

class _SharePatientSheet extends StatelessWidget {
  final List<Map<String, dynamic>> patients;
  final void Function(String patientId, String patientName) onShare;
  const _SharePatientSheet({required this.patients, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text('Share Patient Profile', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
        ),
        if (patients.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No patients to share.', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: patients.length,
              itemBuilder: (ctx, i) {
                final p = patients[i];
                final profile = p['profiles'] as Map<String, dynamic>?;
                final name = profile?['full_name'] as String? ?? 'Patient';
                final patientId = p['patient_id'] as String? ?? '';
                return ListTile(
                  leading: CircleAvatar(backgroundColor: DoctorColors.primaryContainer,
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(color: DoctorColors.primary, fontWeight: FontWeight.w700))),
                  title: Text(name, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
                  trailing: TextButton(
                    onPressed: () => onShare(patientId, name),
                    child: Text('Share', style: GoogleFonts.inter(color: DoctorColors.primary, fontWeight: FontWeight.w700)),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ]),
    );
  }
}
