import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AiFab extends StatefulWidget {
  final VoidCallback? onPressed;

  /// When true, the mascot will wave and show a short greeting bubble
  /// the first time this FAB sees [showGreeting] enabled.
  final bool showGreeting;
  final String greetingText;

  /// Emoji mascot shown in the FAB (can be replaced with an asset later).
  final String mascotEmoji;

  const AiFab({
    super.key,
    this.onPressed,
    this.showGreeting = false,
    this.greetingText = 'Hi',
    this.mascotEmoji = '🐼',
  });

  @override
  State<AiFab> createState() => _AiFabState();
}

class _AiFabState extends State<AiFab> with SingleTickerProviderStateMixin {
  static const _fabSize = 60.0;
  static const _bubbleMaxWidth = 120.0;

  late final AnimationController _waveController;
  late final Animation<double> _waveAngle;

  bool _greetingVisible = false;
  bool _greetingHasRun = false;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _waveAngle = Tween<double>(begin: -0.14, end: 0.14).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRunGreeting();
    });
  }

  @override
  void didUpdateWidget(covariant AiFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showGreeting != widget.showGreeting) {
      _maybeRunGreeting();
    }
  }

  void _maybeRunGreeting() {
    if (!mounted) return;
    if (!widget.showGreeting) return;
    if (_greetingHasRun) return;

    _greetingHasRun = true;
    setState(() => _greetingVisible = true);

    _waveController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      _waveController.stop();
      _waveController.reset();
      setState(() => _greetingVisible = false);
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          top: -58,
          left: -(_bubbleMaxWidth - _fabSize) / 2,
          right: -(_bubbleMaxWidth - _fabSize) / 2,
          child: IgnorePointer(
            child: _GreetingBubble(
              visible: _greetingVisible,
              text: widget.greetingText,
            ),
          ),
        ),
        _buildFabButton(),
      ],
    );
  }

  Widget _buildFabButton() {
    final mascot = Text(
      widget.mascotEmoji,
      style: const TextStyle(fontSize: 28, height: 1.0),
    );

    return Container(
      width: _fabSize,
      height: _fabSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDim],
        ),
        borderRadius: BorderRadius.circular(_fabSize / 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDim.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(_fabSize / 2),
          child: Center(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _greetingVisible ? _waveAngle.value : 0,
                  alignment: Alignment.bottomCenter,
                  child: child,
                );
              },
              child: mascot,
            ),
          ),
        ),
      ),
    );
  }
}

class _GreetingBubble extends StatelessWidget {
  final bool visible;
  final String text;

  const _GreetingBubble({required this.visible, required this.text});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.15),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -6,
                  child: Transform.rotate(
                    angle: 0.785398, // 45 degrees
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
