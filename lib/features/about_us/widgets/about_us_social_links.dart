import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
      // _SocialLink(
      //   icon: Icons.language,
      //   label: 'Website',
      //   value: 'www.social-media-app.com',
      //   url: 'https://github.com/Ahmedatef5O5/Social-Media-App',
      //   color: Colors.blue,
      // ),
      _SocialLink(
        iconBuilder:
            (color, size) =>
                FaIcon(FontAwesomeIcons.briefcase, color: color, size: size),

        label: 'Portfolio',
        value: 'ahmed-portfolio.web.app',
        url: 'https://ahmed-portfolio-cd0a3.web.app',
        color: Colors.blue,
      ),
      _SocialLink(
        iconBuilder:
            (color, size) =>
                FaIcon(FontAwesomeIcons.linkedin, color: color, size: size),

        label: 'LinkedIn',
        value: 'linkedin.com/in/ahmed-ateif-00b77b28a',
        url: 'https://www.linkedin.com/in/ahmed-ateif-00b77b28a/',
        color: const Color(0xFF0A66C2),
      ),
      _SocialLink(
        iconBuilder:
            (color, size) =>
                FaIcon(FontAwesomeIcons.github, color: color, size: size),

        label: 'GitHub',
        value: 'github.com/Ahmedatef5O5',
        url: 'https://github.com/Ahmedatef5O5',
        color: isDark ? Colors.white70 : Colors.black87,
      ),

      _SocialLink(
        iconBuilder:
            (color, size) =>
                FaIcon(FontAwesomeIcons.whatsapp, color: color, size: size),

        label: 'WhatsApp',
        value: 'Contact with me',
        url: 'https://wa.me/201550835238',
        color: const Color(0xFF25D366),
      ),
      _SocialLink(
        iconBuilder:
            (color, size) => FaIcon(
              FontAwesomeIcons.solidEnvelope,
              color: color,
              size: size,
            ),

        label: 'Email',
        value: 'ahmedateif0@gmail.com',
        url:
            'mailto:ahmedateif0@gmail.com'
            '?subject=Contact%20from%20Social%20App'
            '&body=Hello%20Ahmed,',
        color: const Color(0xFFEA4335),
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
                            child: Center(
                              child: link.iconBuilder(link.color, 18),
                            ),
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
  final Widget Function(Color color, double size) iconBuilder;
  final String label, value, url;
  final Color color;

  const _SocialLink({
    required this.iconBuilder,
    required this.label,
    required this.value,
    required this.url,
    required this.color,
  });
}
