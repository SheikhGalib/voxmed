import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/theme/app_colors.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../providers/prescription_provider.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  String? _activeConversationId;

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _voiceMode = true;
  bool _speechReady = false;
  bool _isListening = false;
  bool _isSending = false;
  String? _lastSpokenAssistantMessageId;
  bool _isSpeaking = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final bool _isDoctor;

  static const String _patientInitialPrompt =
      'Hello! I\'m your medical assistant. To help you best, could you describe what symptoms you\'re experiencing and when they started?';

  static const String _doctorInitialPrompt =
      'Hello, Doctor! I\'m your clinical copilot. I can help with patient insights, clinical decision support, documentation, and workflow productivity. How can I assist you today?';

  String get _initialPrompt =>
      _isDoctor ? _doctorInitialPrompt : _patientInitialPrompt;

  @override
  void initState() {
    super.initState();
    final role = supabase.auth.currentUser?.userMetadata?['role'] as String?;
    _isDoctor = role == UserRole.doctor.value;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initVoice();
  }

  Future<void> _initVoice() async {
    try {
      final available = await _speech.initialize();
      if (mounted) {
        setState(() => _speechReady = available);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _speechReady = false);
      }
    }

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(0.85);
      // Attempt to select a male English voice
      final voicesRaw = await _tts.getVoices;
      if (voicesRaw is List) {
        final maleVoice = voicesRaw.whereType<Map>().where((v) {
          final name = (v['name']?.toString() ?? '').toLowerCase();
          final locale = (v['locale']?.toString() ?? '').toLowerCase();
          return locale.contains('en') &&
              (name.contains('male') ||
                  name.contains('deep') ||
                  name.contains('david') ||
                  name.contains('james'));
        }).firstOrNull;
        if (maleVoice != null) {
          await _tts.setVoice({
            'name': maleVoice['name']?.toString() ?? '',
            'locale': maleVoice['locale']?.toString() ?? '',
          });
        }
      }
      _tts.setStartHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = true;
            _pulseController.repeat(reverse: true);
          });
        }
      });
      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            if (!_isListening) _pulseController.stop();
          });
        }
      });
      _tts.setCancelHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            if (!_isListening) _pulseController.stop();
          });
        }
      });
    } catch (_) {
      // Non-critical; TTS availability varies by device.
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_voiceMode) {
        _speak(_initialPrompt);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    _tts.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(trimmed);
    } catch (_) {
      // Non-critical; device may not support TTS.
    }
  }

  Future<void> _toggleVoiceMode() async {
    if (!mounted) return;
    final next = !_voiceMode;
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
    setState(() => _voiceMode = next);
  }

  Future<void> _toggleListening(String? conversationId) async {
    if (!mounted) return;
    if (_isSending) return;

    if (!_speechReady) {
      await _initVoice();
    }

    if (!_speechReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice input not available on this device.'),
          ),
        );
      }
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        if (!_isSpeaking) _pulseController.stop();
      });
      if (_controller.text.trim().isNotEmpty) {
        await _sendMessage(conversationId);
      }
      return;
    }

    _controller.clear();
    setState(() {
      _isListening = true;
      _pulseController.repeat(reverse: true);
    });

    // Prevent TTS output from being captured by speech recognition.
    await _tts.stop();

    await _speech.listen(
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      onResult: (result) async {
        if (!mounted) return;
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });

        if (result.finalResult) {
          await _speech.stop();
          if (!mounted) return;
          setState(() {
            _isListening = false;
            if (!_isSpeaking) _pulseController.stop();
          });
          if (_controller.text.trim().isNotEmpty) {
            await _sendMessage(conversationId);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(aiConversationsProvider);

    // Get the first conversation or use the active one
    final conversations = conversationsAsync.valueOrNull ?? [];
    final conversationId =
        _activeConversationId ??
        (conversations.isNotEmpty ? conversations.first['id'] as String : null);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              Icons.medical_information_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ],
        ),
        title: Text(
          'VoxMed',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: _toggleVoiceMode,
              borderRadius: BorderRadius.circular(10),
              child: Icon(
                _voiceMode ? Icons.chat_bubble_outline : Icons.mic_none,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: _isSending ? null : _startNewChat,
              borderRadius: BorderRadius.circular(10),
              child: const Icon(
                Icons.add_comment_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: _openHistorySheet,
              borderRadius: BorderRadius.circular(10),
              child: const Icon(
                Icons.history,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: _voiceMode
          ? _buildVoiceModeBody(conversationId)
          : Column(
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

  Widget _buildVoiceModeBody(String? conversationId) {
    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Animated pulsing circle with panda avatar
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final isActive = _isListening || _isSpeaking;
                  final scale = isActive ? _pulseAnimation.value : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (isActive)
                            BoxShadow(
                              color:
                                  (_isListening
                                          ? AppColors.secondary
                                          : AppColors.primary)
                                      .withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 8,
                            ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: isActive
                                ? (_isListening
                                      ? AppColors.secondary
                                      : AppColors.primary)
                                : AppColors.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                            width: isActive ? 3 : 1.5,
                          ),
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: _PandaMedicalAvatar(size: 140),
                ),
              ),
              const SizedBox(height: 24),
              // Status text
              Text(
                _isListening
                    ? 'Listening…'
                    : _isSpeaking
                    ? (_isDoctor
                          ? 'VoxMed Copilot is speaking…'
                          : 'Dr. Panda is speaking…')
                    : _isSending
                    ? 'Thinking…'
                    : 'Tap the mic to speak',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _isListening
                      ? AppColors.secondary
                      : _isSpeaking
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              // Transcript area (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Live listening preview
                      if (_isListening && _controller.text.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _controller.text,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.onSurface,
                              height: 1.5,
                            ),
                          ),
                        ),
                      // Initial prompt when no conversation
                      if (conversationId == null && !_isListening)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          child: Text(
                            _initialPrompt,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      // Conversation transcript
                      if (conversationId != null)
                        _buildVoiceTranscript(conversationId),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildVoiceMicBar(conversationId),
      ],
    );
  }

  Widget _buildVoiceTranscript(String conversationId) {
    final messagesAsync = ref.watch(aiMessagesProvider(conversationId));
    return messagesAsync.when(
      data: (messages) {
        // Auto-speak latest assistant message
        final assistant = messages
            .where((m) => (m['role'] as String?) != 'user')
            .toList();
        if (assistant.isNotEmpty) {
          final last = assistant.last;
          final id = last['id'] as String?;
          final content = last['content'] as String? ?? '';
          if (id != null &&
              id != _lastSpokenAssistantMessageId &&
              content.trim().isNotEmpty) {
            _lastSpokenAssistantMessageId = id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || !_voiceMode) return;
              _speak(content);
            });
          }
        }

        if (messages.isEmpty) return const SizedBox.shrink();

        // Show last 3 messages
        final recent = messages.length > 3
            ? messages.sublist(messages.length - 3)
            : messages;
        return Column(
          children: recent.map((msg) {
            final role = msg['role'] as String? ?? 'assistant';
            final content = msg['content'] as String? ?? '';
            final isUser = role == 'user';
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.tertiaryContainer.withValues(alpha: 0.5)
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? 'You' : (_isDoctor ? 'Copilot' : 'Dr. Panda'),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isUser
                          ? AppColors.onTertiaryContainer
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildVoiceMicBar(String? conversationId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isSending ? null : () => _toggleListening(conversationId),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isSending
                    ? AppColors.onSurfaceVariant
                    : (_isListening ? AppColors.secondary : AppColors.primary),
                boxShadow: [
                  BoxShadow(
                    color:
                        (_isListening ? AppColors.secondary : AppColors.primary)
                            .withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isSending
                    ? Icons.hourglass_top
                    : (_isListening ? Icons.stop : Icons.mic),
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isListening ? 'Tap to stop' : 'Tap to speak',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
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
        _buildBotMessage(_initialPrompt, showAvatar: true),
      ],
    );
  }

  Widget _buildMessages(String conversationId) {
    final messagesAsync = ref.watch(aiMessagesProvider(conversationId));

    return messagesAsync.when(
      data: (messages) {
        if (_voiceMode) {
          final assistant = messages
              .where((m) => (m['role'] as String?) != 'user')
              .toList();
          if (assistant.isNotEmpty) {
            final last = assistant.last;
            final id = last['id'] as String?;
            final content = last['content'] as String? ?? '';
            if (id != null &&
                id != _lastSpokenAssistantMessageId &&
                content.trim().isNotEmpty) {
              _lastSpokenAssistantMessageId = id;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (!_voiceMode) return;
                _speak(content);
              });
            }
          }
        }

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
                          Text(
                            content,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.onSurface,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...followUps.map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _FollowUpChip(
                                label: f.toString(),
                                icon: Icons.help_outline,
                              ),
                            ),
                          ),
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
            if (_isSending)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBotMessage(
                  null,
                  showAvatar: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Thinking...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isDoctor ? 'Clinical Copilot Active' : 'AI Triage Active',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Text(
          'Failed to load messages',
          style: GoogleFonts.inter(color: AppColors.error),
        ),
      ),
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
              Text(
                _isDoctor ? 'Clinical Copilot' : 'AI Triage Assistant',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isDoctor
                    ? 'Your AI-powered assistant for clinical insights, documentation, and workflow support.'
                    : 'Tell me about your symptoms. I can help guide you to the right care, but I am not a doctor.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotMessage(
    String? text, {
    bool showAvatar = false,
    Widget? child,
  }) {
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
              child: const Icon(
                Icons.smart_toy,
                color: AppColors.primary,
                size: 16,
              ),
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
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.1),
                ),
              ),
              child:
                  child ??
                  Text(
                    text!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurface,
                      height: 1.5,
                    ),
                  ),
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
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onTertiaryContainer,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(String? conversationId) {
    if (_voiceMode) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(
            top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.15),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isListening ? Icons.graphic_eq : Icons.mic_none,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _controller.text.isEmpty
                            ? (_isListening
                                  ? 'Listening…'
                                  : (_isSending
                                        ? 'Sending your message...'
                                        : 'Tap the mic and speak…'))
                            : _controller.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _controller.text.isEmpty
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isSending ? null : () => _toggleListening(conversationId),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSending
                      ? AppColors.onSurfaceVariant
                      : (_isListening
                            ? AppColors.secondary
                            : AppColors.primary),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _isSending
                      ? Icons.hourglass_top
                      : (_isListening ? Icons.stop : Icons.mic),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
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
                      enabled: !_isSending,
                      decoration: InputDecoration(
                        hintText: 'Type your symptoms here...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _toggleVoiceMode,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.mic_none,
                        color: AppColors.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isSending ? null : () => _sendMessage(conversationId),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isSending
                    ? AppColors.onSurfaceVariant
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _isSending ? Icons.hourglass_top : Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String? conversationId) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final aiRepo = ref.read(aiRepositoryProvider);
      final result = await aiRepo.sendMessage(
        conversationId: conversationId,
        message: text,
      );

      if (!mounted) return;
      setState(() {
        _activeConversationId = result.conversationId;
        // Let auto-read logic speak the fresh assistant message once.
        _lastSpokenAssistantMessageId = null;
      });
      _controller.clear();

      ref.invalidate(aiConversationsProvider);
      ref.invalidate(aiMessagesProvider(result.conversationId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _startNewChat() async {
    if (!mounted) return;
    if (_isListening) {
      await _speech.stop();
    }
    await _tts.stop();
    setState(() {
      _activeConversationId = null;
      _isListening = false;
      _lastSpokenAssistantMessageId = null;
      _controller.clear();
    });
  }

  Future<void> _deleteConversation(String conversationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete chat session?'),
          content: const Text(
            'This will permanently remove this conversation and all related messages.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final aiRepo = ref.read(aiRepositoryProvider);
      await aiRepo.deleteConversation(conversationId);

      if (!mounted) return;
      if (_activeConversationId == conversationId) {
        setState(() => _activeConversationId = null);
      }
      ref.invalidate(aiConversationsProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chat session deleted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete chat session: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatConversationTime(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed == null) return '';
    return DateFormat('MMM d, h:mm a').format(parsed);
  }

  Future<void> _openHistorySheet() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final conversationsAsync = ref.watch(aiConversationsProvider);

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: conversationsAsync.when(
                  data: (sessions) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Row(
                            children: [
                              Text(
                                'Chat History',
                                style: GoogleFonts.manrope(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _startNewChat();
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('New Chat'),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: sessions.isEmpty
                              ? Center(
                                  child: Text(
                                    'No chat sessions yet. Start a new conversation.',
                                    style: GoogleFonts.inter(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  itemCount: sessions.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 4),
                                  itemBuilder: (context, index) {
                                    final session = sessions[index];
                                    final id = session['id'] as String? ?? '';
                                    final title = (session['title'] as String?)
                                        ?.trim();
                                    final updatedAt = _formatConversationTime(
                                      session['updated_at'] as String?,
                                    );
                                    final isActive =
                                        id.isNotEmpty &&
                                        id == _activeConversationId;

                                    return ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      tileColor: isActive
                                          ? AppColors.primaryContainer
                                                .withValues(alpha: 0.35)
                                          : Colors.transparent,
                                      title: Text(
                                        (title == null || title.isEmpty)
                                            ? 'Untitled chat'
                                            : title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      subtitle: Text(
                                        updatedAt.isEmpty
                                            ? 'No timestamp'
                                            : updatedAt,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                      onTap: id.isEmpty
                                          ? null
                                          : () {
                                              setState(
                                                () =>
                                                    _activeConversationId = id,
                                              );
                                              Navigator.of(context).pop();
                                            },
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.error,
                                        ),
                                        onPressed: id.isEmpty
                                            ? null
                                            : () async {
                                                Navigator.of(context).pop();
                                                await _deleteConversation(id);
                                              },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Text(
                      'Failed to load chat sessions',
                      style: GoogleFonts.inter(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PandaMedicalAvatar extends StatelessWidget {
  final double size;
  const _PandaMedicalAvatar({this.size = 120});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: const _PandaPainter());
  }
}

class _PandaPainter extends CustomPainter {
  const _PandaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final darkPaint = Paint()..color = const Color(0xFF2D2D2D);
    final whitePaint = Paint()..color = Colors.white;

    // Ears
    canvas.drawCircle(
      Offset(cx - r * 0.58, cy - r * 0.52),
      r * 0.28,
      darkPaint,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.58, cy - r * 0.52),
      r * 0.28,
      darkPaint,
    );
    // Inner ears
    canvas.drawCircle(
      Offset(cx - r * 0.58, cy - r * 0.52),
      r * 0.15,
      Paint()..color = const Color(0xFF555555),
    );
    canvas.drawCircle(
      Offset(cx + r * 0.58, cy - r * 0.52),
      r * 0.15,
      Paint()..color = const Color(0xFF555555),
    );

    // Face
    canvas.drawCircle(Offset(cx, cy), r * 0.7, whitePaint);
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.7,
      Paint()
        ..color = const Color(0xFFE8E8E8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Eye patches
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - r * 0.24, cy - r * 0.1),
        width: r * 0.36,
        height: r * 0.28,
      ),
      darkPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + r * 0.24, cy - r * 0.1),
        width: r * 0.36,
        height: r * 0.28,
      ),
      darkPaint,
    );

    // Eyes
    canvas.drawCircle(Offset(cx - r * 0.22, cy - r * 0.1), r * 0.1, whitePaint);
    canvas.drawCircle(Offset(cx + r * 0.22, cy - r * 0.1), r * 0.1, whitePaint);
    // Pupils
    canvas.drawCircle(Offset(cx - r * 0.19, cy - r * 0.1), r * 0.05, darkPaint);
    canvas.drawCircle(Offset(cx + r * 0.19, cy - r * 0.1), r * 0.05, darkPaint);
    // Eye highlights
    canvas.drawCircle(
      Offset(cx - r * 0.21, cy - r * 0.13),
      r * 0.025,
      whitePaint,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.21, cy - r * 0.13),
      r * 0.025,
      whitePaint,
    );

    // Blush
    final blushPaint = Paint()
      ..color = const Color(0xFFFFCDD2).withValues(alpha: 0.6);
    canvas.drawCircle(
      Offset(cx - r * 0.38, cy + r * 0.05),
      r * 0.08,
      blushPaint,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.38, cy + r * 0.05),
      r * 0.08,
      blushPaint,
    );

    // Nose
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.1),
        width: r * 0.14,
        height: r * 0.1,
      ),
      darkPaint,
    );
    // Nose highlight
    canvas.drawCircle(
      Offset(cx - r * 0.02, cy + r * 0.08),
      r * 0.02,
      Paint()..color = const Color(0xFF555555),
    );

    // Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final mouth = Path()
      ..moveTo(cx - r * 0.06, cy + r * 0.18)
      ..quadraticBezierTo(cx, cy + r * 0.24, cx + r * 0.06, cy + r * 0.18);
    canvas.drawPath(mouth, mouthPaint);

    // Stethoscope tube
    final stethPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final stethTube = Path()
      ..moveTo(cx - r * 0.32, cy + r * 0.35)
      ..quadraticBezierTo(
        cx - r * 0.35,
        cy + r * 0.55,
        cx - r * 0.1,
        cy + r * 0.65,
      )
      ..quadraticBezierTo(
        cx + r * 0.05,
        cy + r * 0.72,
        cx + r * 0.1,
        cy + r * 0.65,
      )
      ..quadraticBezierTo(
        cx + r * 0.35,
        cy + r * 0.55,
        cx + r * 0.32,
        cy + r * 0.35,
      );
    canvas.drawPath(stethTube, stethPaint);

    // Earpieces
    canvas.drawCircle(
      Offset(cx - r * 0.32, cy + r * 0.35),
      r * 0.035,
      Paint()..color = const Color(0xFF4CAF50),
    );
    canvas.drawCircle(
      Offset(cx + r * 0.32, cy + r * 0.35),
      r * 0.035,
      Paint()..color = const Color(0xFF4CAF50),
    );

    // Chest piece
    canvas.drawCircle(
      Offset(cx, cy + r * 0.72),
      r * 0.07,
      Paint()..color = const Color(0xFF4CAF50),
    );
    canvas.drawCircle(
      Offset(cx, cy + r * 0.72),
      r * 0.04,
      Paint()..color = const Color(0xFF66BB6A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
