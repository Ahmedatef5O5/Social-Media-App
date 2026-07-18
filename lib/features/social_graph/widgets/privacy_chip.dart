import 'package:flutter/material.dart';
import '../models/content_privacy.dart';

class PrivacyChip extends StatelessWidget {
  final ContentPrivacy privacy;
  final VoidCallback onTap;

  const PrivacyChip({super.key, required this.privacy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(privacy.icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              privacy.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
