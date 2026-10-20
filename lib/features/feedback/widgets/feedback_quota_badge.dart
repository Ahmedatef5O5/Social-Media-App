import 'dart:async';
import 'package:flutter/material.dart';
import '../models/feedback_models.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class FeedbackQuotaBadge extends StatefulWidget {
  final FeedbackQuota quota;
  final VoidCallback onExpired;

  const FeedbackQuotaBadge({
    super.key,
    required this.quota,
    required this.onExpired,
  });

  @override
  State<FeedbackQuotaBadge> createState() => _FeedbackQuotaBadgeState();
}

class _FeedbackQuotaBadgeState extends State<FeedbackQuotaBadge> {
  Timer? _timer;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant FeedbackQuotaBadge old) {
    super.didUpdateWidget(old);
    if (old.quota.resetsAt != widget.quota.resetsAt ||
        old.quota.used != widget.quota.used) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    final resets = widget.quota.resetsAt;
    if (!widget.quota.isExhausted || resets == null) {
      _left = Duration.zero;
      return;
    }
    _tick(resets);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick(resets));
  }

  void _tick(DateTime resets) {
    final left = resets.difference(DateTime.now());
    if (left <= Duration.zero) {
      _timer?.cancel();
      if (mounted) setState(() => _left = Duration.zero);
      widget.onExpired();
      return;
    }
    if (mounted) setState(() => _left = left);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quota;
    final exhausted = q.isExhausted;
    final color =
        exhausted ? const Color(0xFFE5484D) : Theme.of(context).primaryColor;
    final text =
        exhausted
            ? context.l10n.dailyLimitReachedNext(_fmt(_left))
            : context.l10n.ofFeedbacksLeftToday(q.remaining, q.limit);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            exhausted ? Icons.timer_outlined : Icons.bolt_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
