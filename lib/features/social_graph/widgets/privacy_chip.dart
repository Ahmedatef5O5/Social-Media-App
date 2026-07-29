import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/content_privacy.dart';

class PrivacyChip extends StatelessWidget {
  final ContentPrivacy privacy;
  final VoidCallback onTap;

  const PrivacyChip({super.key, required this.privacy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onTap,
                splashColor: Colors.white.withValues(alpha: 0.2),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        privacy.icon,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        privacy.label,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 2.5),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
