import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class AboutUsMissionCard extends StatelessWidget {
  final bool isDark;
  final Color primary;

  const AboutUsMissionCard({
    super.key,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.08),
            primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primary.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: primary,
                  size: 18,
                ),
              ),
              const Gap(10),
              Text(
                'Our Mission',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const Gap(14),
          Text(
            'We believe meaningful connections change lives. Our platform is built to bring people closer — through conversations, shared moments, and real-time experiences that matter.',
            style: TextStyle(
              fontSize: 14.5,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black54,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
