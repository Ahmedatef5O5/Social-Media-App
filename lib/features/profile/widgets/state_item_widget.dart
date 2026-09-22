import 'package:flutter/material.dart';
import '../utils/profile_ui_tokens.dart';

class StatItemWidget extends StatelessWidget {
  final String label;
  final String value;
  const StatItemWidget({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileUiTokens.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.1,
            color: tokens.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: tokens.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
