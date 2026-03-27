import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildBotMessage(
                  'Hello! I\'m your medical assistant. To help you best, could you describe what symptoms you\'re experiencing and when they started?',
                  showAvatar: true,
                ),
                Center(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('JUST NOW', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.onSurfaceVariant.withValues(alpha: 0.5))),
                )),
                _buildUserMessage(
                  'I\'ve been having a persistent dull headache for the last two days, mostly around my temples.',
                ),
                Center(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('2 MIN AGO', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.onSurfaceVariant.withValues(alpha: 0.5))),
                )),
                _buildBotMessage(
                  null,
                  showAvatar: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('Tension headache suspected',
                              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Headaches around the temples are often related to stress or eye strain. I have a few follow-up questions to rule out other possibilities:',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      _FollowUpChip(label: 'Blurred vision?', icon: Icons.visibility),
                      const SizedBox(height: 8),
                      _FollowUpChip(label: 'Nausea / Vomiting?', icon: Icons.sick),
                      const SizedBox(height: 8),
                      _FollowUpChip(label: 'Sensitivity to light?', icon: Icons.lightbulb_outline),
                      const SizedBox(height: 8),
                      _FollowUpChip(label: 'None of these', icon: Icons.check_circle_outline),
                    ],
                  ),
                ),
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
            ),
          ),
          _buildInputBar(),
        ],
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

  Widget _buildInputBar() {
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
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
