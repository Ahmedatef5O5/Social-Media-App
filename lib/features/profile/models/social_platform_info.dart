import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialPlatformInfo {
  final String key;
  final String label;
  final FaIconData? icon;
  final String? monogram;
  final Color brandColor;
  final Color? monochromeGlyphColor;
  final String hint;
  final String Function(String rawValue) normalizeToUrl;

  const SocialPlatformInfo({
    required this.key,
    required this.label,
    this.icon,
    this.monogram,
    required this.brandColor,
    this.monochromeGlyphColor,
    required this.hint,
    required this.normalizeToUrl,
  });

  Widget buildGlyph({double size = 18, bool onBrandBackground = true}) {
    final color =
        monochromeGlyphColor ?? (onBrandBackground ? Colors.white : brandColor);
    if (icon != null) {
      return FaIcon(icon, size: size, color: color);
    }
    final fallback =
        label.length >= 2 ? label.substring(0, 2) : label.substring(0, 1);
    return Text(
      (monogram ?? fallback).toUpperCase(),
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: size * 0.6,
        height: 1,
      ),
    );
  }

  static String _cleanHandle(String raw) {
    final trimmed = raw.trim();
    return trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
  }

  static String _urlOrBuild(String raw, String Function(String) build) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return build(_cleanHandle(trimmed));
  }

  static final List<SocialPlatformInfo> all = [
    SocialPlatformInfo(
      key: 'whatsapp',
      label: 'WhatsApp',
      icon: FontAwesomeIcons.whatsapp,
      brandColor: const Color(0xFF25D366),
      hint: 'Phone number, e.g. +201234567890',
      normalizeToUrl:
          (raw) => _urlOrBuild(raw, (v) {
            final digitsOnly = v.replaceAll(RegExp(r'[^0-9]'), '');
            return 'https://wa.me/$digitsOnly';
          }),
    ),
    SocialPlatformInfo(
      key: 'facebook',
      label: 'Facebook',
      icon: FontAwesomeIcons.facebook,
      brandColor: const Color(0xFF1877F2),
      hint: 'Username or profile URL',
      normalizeToUrl:
          (raw) => _urlOrBuild(raw, (v) => 'https://facebook.com/$v'),
    ),
    SocialPlatformInfo(
      key: 'linkedin',
      label: 'LinkedIn',
      icon: FontAwesomeIcons.linkedin,
      brandColor: const Color(0xFF0A66C2),
      hint: 'Username or profile URL',
      normalizeToUrl:
          (raw) => _urlOrBuild(raw, (v) => 'https://linkedin.com/in/$v'),
    ),
    SocialPlatformInfo(
      key: 'github',
      label: 'GitHub',
      icon: FontAwesomeIcons.github,
      brandColor: const Color(0xFF181717),
      hint: 'Username or profile URL',
      normalizeToUrl: (raw) => _urlOrBuild(raw, (v) => 'https://github.com/$v'),
    ),
    SocialPlatformInfo(
      key: 'twitter',
      label: 'X (Twitter)',
      icon: FontAwesomeIcons.xTwitter,
      brandColor: const Color(0xFF000000),
      hint: 'Username or profile URL',
      normalizeToUrl: (raw) => _urlOrBuild(raw, (v) => 'https://x.com/$v'),
    ),
    SocialPlatformInfo(
      key: 'instagram',
      label: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      brandColor: const Color(0xFFE4405F),
      hint: 'Username or profile URL',
      normalizeToUrl:
          (raw) => _urlOrBuild(raw, (v) => 'https://instagram.com/$v'),
    ),
    SocialPlatformInfo(
      key: 'youtube',
      label: 'YouTube',
      icon: FontAwesomeIcons.youtube,
      brandColor: const Color(0xFFFF0000),
      hint: 'Channel handle or URL',
      normalizeToUrl:
          (raw) => _urlOrBuild(raw, (v) => 'https://youtube.com/@$v'),
    ),
    SocialPlatformInfo(
      key: 'tiktok',
      label: 'TikTok',
      icon: FontAwesomeIcons.tiktok,
      brandColor: const Color(0xFF000000),
      hint: 'Username or profile URL',
      normalizeToUrl:
          (raw) => _urlOrBuild(raw, (v) => 'https://tiktok.com/@$v'),
    ),

    // ── Newly added platforms ──
    SocialPlatformInfo(
      key: 'discord',
      label: 'Discord',
      icon: FontAwesomeIcons.discord,
      brandColor: const Color(0xFF5865F2),
      hint: 'Server invite, e.g. discord.gg/yourserver',
      normalizeToUrl: (raw) => _urlOrBuild(raw, (v) => 'https://discord.gg/$v'),
    ),
    SocialPlatformInfo(
      key: 'stackoverflow',
      label: 'Stack Overflow',
      icon: FontAwesomeIcons.stackOverflow,
      brandColor: const Color(0xFFF58025),
      hint: 'Full profile URL (stackoverflow.com/users/…)',
      normalizeToUrl:
          (raw) =>
              _urlOrBuild(raw, (v) => 'https://stackoverflow.com/users/$v'),
    ),
    SocialPlatformInfo(
      key: 'snapchat',
      label: 'Snapchat',
      icon: FontAwesomeIcons.snapchat,
      brandColor: const Color(0xFFFFFC00),
      monochromeGlyphColor: Colors.black,
      hint: 'Username',
      normalizeToUrl:
          (raw) => _urlOrBuild(raw, (v) => 'https://snapchat.com/add/$v'),
    ),
    SocialPlatformInfo(
      key: 'telegram',
      label: 'Telegram',
      icon: FontAwesomeIcons.telegram,
      brandColor: const Color(0xFF26A5E4),
      hint: 'Username or t.me link',
      normalizeToUrl: (raw) => _urlOrBuild(raw, (v) => 'https://t.me/$v'),
    ),
    SocialPlatformInfo(
      key: 'reddit',
      label: 'Reddit',
      icon: FontAwesomeIcons.reddit,
      brandColor: const Color(0xFFFF4500),
      hint: 'Username or profile URL',
      normalizeToUrl:
          (raw) => _urlOrBuild(raw, (v) => 'https://reddit.com/user/$v'),
    ),
  ];

  static SocialPlatformInfo? byKey(String key) {
    for (final p in all) {
      if (p.key == key) return p;
    }
    return null;
  }
}
