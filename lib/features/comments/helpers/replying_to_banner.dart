import 'package:flutter/material.dart';

import '../../../core/themes/app_colors.dart';

class ReplyingToBanner extends StatelessWidget {
  final String authorName;
  final VoidCallback onCancel;

  const ReplyingToBanner({
    super.key,
    required this.authorName,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply_rounded,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Replying to ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey7,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '@$authorName',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Icon(Icons.close_rounded, size: 18, color: AppColors.grey6),
          ),
        ],
      ),
    );
  }
}
