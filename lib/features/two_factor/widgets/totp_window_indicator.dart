import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';

class TotpWindowIndicator extends StatefulWidget {
  const TotpWindowIndicator({super.key});

  @override
  State<TotpWindowIndicator> createState() => _TotpWindowIndicatorState();
}

class _TotpWindowIndicatorState extends State<TotpWindowIndicator> {
  static const int _period = 30;
  Timer? _timer;

  int get _remaining =>
      _period - (DateTime.now().millisecondsSinceEpoch ~/ 1000 % _period);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = _remaining;
    final urgent = remaining <= 3;
    final activeColor = urgent ? Colors.orangeAccent : AppColors.primaryColor;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activeColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                value: remaining / _period,
                strokeWidth: 2.2,
                color: activeColor,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                urgent
                    ? 'Code about to change, wait for next'
                    : 'Code updates in ${remaining}s',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: urgent ? Colors.orange.shade800 : theme.hintColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
