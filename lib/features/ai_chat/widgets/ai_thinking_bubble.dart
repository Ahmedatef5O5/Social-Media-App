import 'package:flutter/material.dart';
import '../../ai_assistant/widgets/animated_ai_stars_icon.dart';
import '../../single_chats/widgets/typing_indicator_widget.dart';
import '../models/ai_model_option.dart';
import '../models/ai_reply_phase.dart';

class AiThinkingBubble extends StatelessWidget {
  final AiReplyPhase phase;
  final AiModelOption model;

  const AiThinkingBubble({super.key, required this.phase, required this.model});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder:
          (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 8),
              child: child,
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Avatar(color: model.accentColor),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedAiStarsIcon(size: 16, color: model.accentColor),
                  const SizedBox(width: 8),
                  _ShimmerPhaseLabel(phase: phase, color: model.accentColor),
                  const SizedBox(width: 8),
                  TypingIndicatorWidget(
                    color: model.accentColor,
                    dotSize: 4.5,
                    spacing: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final Color color;
  const _Avatar({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Icon(Icons.auto_awesome_rounded, size: 13, color: color),
    );
  }
}

class _ShimmerPhaseLabel extends StatefulWidget {
  final AiReplyPhase phase;
  final Color color;
  const _ShimmerPhaseLabel({required this.phase, required this.color});

  @override
  State<_ShimmerPhaseLabel> createState() => _ShimmerPhaseLabelState();
}

class _ShimmerPhaseLabelState extends State<_ShimmerPhaseLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder:
          (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
      child: AnimatedBuilder(
        key: ValueKey(widget.phase),
        animation: _shimmerController,
        builder: (context, _) {
          final t = _shimmerController.value;
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.55),
                  widget.color,
                  Colors.white.withValues(alpha: 0.55),
                ],
                stops: const [0.35, 0.5, 0.65],
                begin: Alignment(-1 - t * 2, 0),
                end: Alignment(1 - t * 2, 0),
              ).createShader(bounds);
            },
            child: Text(
              widget.phase.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                letterSpacing: -0.1,
              ),
            ),
          );
        },
      ),
    );
  }
}
