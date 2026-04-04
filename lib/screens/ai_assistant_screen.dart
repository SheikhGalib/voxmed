import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../providers/prescription_provider.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _controller = TextEditingController();
  String? _activeConversationId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(aiConversationsProvider);

    // Get the first conversation or use the active one
    final conversations = conversationsAsync.valueOrNull ?? [];
    final conversationId = _activeConversationId ?? (conversations.isNotEmpty ? conversations.first['id'] as String : null);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: Row(
          children: [
            const SizedBox(width: 8),
            Icon(Icons.medical_information_outlined, color: AppColors.primary, size: 24),
          ],
        ),
        title: Text('VoxMed', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.history, color: AppColors.primary, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: conversationId == null
                ? _buildEmptyState()
                : _buildMessages(conversationId),
          ),
          _buildInputBar(conversationId),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildBotMessage(
          'Hello! I\'m your medical assistant. To help you best, could you describe what symptoms you\'re experiencing and when they started?',
          showAvatar: true,
        ),
      ],
    );
  }

  Widget _buildMessages(String conversationId) {
    final messagesAsync = ref.watch(aiMessagesProvider(conversationId));

    return messagesAsync.when(
      data: (messages) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            ...messages.map((msg) {
              final role = msg['role'] as String? ?? 'assistant';
              final content = msg['content'] as String? ?? '';
              final metadata = msg['metadata'] as Map<String, dynamic>?;

              if (role == 'user') {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildUserMessage(content),
                );
              } else {
                // assistant or system
                final followUps = metadata?['follow_ups'] as List?;
                if (followUps != null && followUps.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildBotMessage(
                      null,
                      showAvatar: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(content, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface, height: 1.5)),
                          const SizedBox(height: 14),
                          ...followUps.map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _FollowUpChip(label: f.toString(), icon: Icons.help_outline),
                          )),
                        ],
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildBotMessage(content, showAvatar: true),
                );
              }
            }),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('AI Triage Active', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text('Failed to load messages', style: GoogleFonts.inter(color: AppColors.error))),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.smart_toy, color: AppColors.primary, size: 36),
              const SizedBox(height: 12),
              Text('AI Triage Assistant',
                  style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              const SizedBox(height: 6),
              Text(
                'Tell me about your symptoms. I can help guide you to the right care, but I am not a doctor.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotMessage(String? text, {bool showAvatar = false, Widget? child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar)
            Container(
              margin: const EdgeInsets.only(right: 10, top: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 16),
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
              ),
              child: child ?? Text(text!, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 48),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.tertiaryContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Text(text, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onTertiaryContainer, height: 1.5)),
        ),
      ),
    );
  }

  Widget _buildInputBar(String? conversationId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type your symptoms here...',
                        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                        border: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  const Icon(Icons.mic_none, color: AppColors.onSurfaceVariant, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(conversationId),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String? conversationId) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      String convId;
      if (conversationId == null) {
        // Create a new conversation
        final row = await supabase.from(Tables.aiConversations).insert({
          'patient_id': uid,
          'title': text.length > 50 ? '${text.substring(0, 50)}...' : text,
        }).select('id').single();
        convId = row['id'] as String;
        setState(() => _activeConversationId = convId);
        ref.invalidate(aiConversationsProvider);
      } else {
        convId = conversationId;
      }

      // Insert the user message
      await supabase.from(Tables.aiMessages).insert({
        'conversation_id': convId,
        'role': 'user',
        'content': text,
      });

      _controller.clear();
      ref.invalidate(aiMessagesProvider(convId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

class _FollowUpChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _FollowUpChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurface)),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}
