import 'package:flutter/material.dart';
import 'active_call_header_content.dart';

class CallHeaderTitleAndDuration extends StatelessWidget {
  const CallHeaderTitleAndDuration({
    super.key,
    required this.widget,
    required String durationText,
  }) : _durationText = durationText;

  final ActiveCallHeaderContent widget;
  final String _durationText;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 1),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 3.5,
              height: 3.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.shade400,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _durationText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
