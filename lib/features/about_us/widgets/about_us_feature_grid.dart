import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class AboutUsFeatureGrid extends StatelessWidget {
  final bool isDark;
  final Color primary;

  const AboutUsFeatureGrid({
    super.key,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final features = [
      (
        Icons.chat_bubble_rounded,
        'Real-time Chats',
        'Instant messaging with read receipts',
      ),
      (Icons.call_rounded, 'HD Voice & Video', 'Crystal clear calls anytime'),
      (Icons.people_alt_rounded, 'Group Chats', 'Connect with communities'),
      (Icons.auto_stories_rounded, 'Stories', 'Share your daily moments'),
      (
        Icons.notifications_active_rounded,
        'Smart Alerts',
        'Never miss what matters',
      ),
      (Icons.shield_rounded, 'Privacy First', 'Your data stays yours'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: height * 0.148,
      ),
      itemCount: features.length,
      itemBuilder: (context, i) {
        final (icon, title, desc) = features[i];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + i * 60),
          curve: Curves.easeOut,
          builder:
              (context, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - v)),
                  child: child,
                ),
              ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.grey.shade200,
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: primary, size: 18),
                ),
                const Gap(10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                const Gap(3),
                Expanded(
                  child: Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
