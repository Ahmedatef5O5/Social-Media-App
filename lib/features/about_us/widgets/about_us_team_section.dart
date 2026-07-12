import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';

class AboutUsTeamSection extends StatelessWidget {
  final bool isDark;
  final Color primary;

  const AboutUsTeamSection({
    super.key,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final heroTag = 'profile_image_ahmed';
    final team = [
      _TeamMember(
        name: 'Ahmed Atef',
        role: 'Flutter Developer',
        image: AppImages.devPersonnalImg,
        color: Colors.purple.withValues(alpha: 0.85),
      ),
    ];

    return Column(
      children:
          team.asMap().entries.map((entry) {
            final i = entry.key;
            final member = entry.value;
            final isLast = i == team.length - 1;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + i * 80),
              curve: Curves.easeOut,
              builder:
                  (context, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - v)),
                      child: child,
                    ),
                  ),
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.grey.shade200,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.fullScreenImageViewRoute,
                          arguments: {
                            'url': member.image,
                            'tag': heroTag,
                            'isAsset': true,
                          },
                        );
                      },
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Hero(
                          tag: heroTag,
                          child: ClipOval(
                            child: Image.asset(
                              member.image,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Gap(3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: member.color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: member.color.withValues(alpha: 0.4),
                                width: .8,
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF7C3AED),
                                  const Color(0xFFEC4899),
                                ],
                              ),
                            ),
                            child: Text(
                              member.role,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: member.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _TeamMember {
  final String name, role;
  final String image;
  final Color color;
  const _TeamMember({
    required this.name,
    required this.role,
    required this.image,
    required this.color,
  });
}
