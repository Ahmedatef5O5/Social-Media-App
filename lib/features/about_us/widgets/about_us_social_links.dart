import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsSocialLinks extends StatelessWidget {
  final bool isDark;
  final Color primary;

  const AboutUsSocialLinks({
    super.key,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final links = [
      _SocialLink(
        icon: Icons.language,
        label: 'Website',
        value: 'www.social-media-app.com',
        url: 'https://github.com/Ahmedatef5O5/Social-Media-App',
        color: Colors.blue,
      ),
      _SocialLink(
        icon: Icons.email,
        label: 'Email',
        value: 'ahmedateif0@gmail.com',
        url:
            'mailto:ahmedateif0@gmail.com'
            '?subject=Contact%20from%20Social%20App'
            '&body=Hello%20Ahmed,',
        color: Colors.green,
      ),
      _SocialLink(
        icon: Icons.code,
        label: 'GitHub',
        value: 'github.com/Ahmedatef5O5',
        url: 'https://github.com/Ahmedatef5O5',
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
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
        children:
            links.asMap().entries.map((entry) {
              final i = entry.key;
              final link = entry.value;
              final isLast = i == links.length - 1;
              return Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      HapticFeedback.selectionClick();

                      if (link.label == 'Email') {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'ahmedateif0@gmail.com',
                          queryParameters: {
                            'subject': 'Contact from Social App',
                            'body': 'Hello Ahmed,',
                          },
                        );

                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );

                        return;
                      }

                      final uri = Uri.parse(link.url);
                      if (await canLaunchUrl(uri)) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: link.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(link.icon, color: link.color, size: 18),
                          ),
                          const Gap(14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  link.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  link.value,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isDark
                                            ? Colors.white38
                                            : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 15,
                            color:
                                isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 68,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.grey.shade200,
                    ),
                ],
              );
            }).toList(),
      ),
    );
  }
}

class _SocialLink {
  final IconData icon;
  final String label, value, url;
  final Color color;
  const _SocialLink({
    required this.icon,
    required this.label,
    required this.value,
    required this.url,
    required this.color,
  });
}
