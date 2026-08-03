import 'package:flutter/material.dart';

class StarredMessagesRow extends StatelessWidget {
  final Color primary;
  final VoidCallback onTap;

  const StarredMessagesRow({
    super.key,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.star_border_rounded, color: primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Starred Messages',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
