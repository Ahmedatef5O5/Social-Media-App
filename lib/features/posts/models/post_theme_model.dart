import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/l10n/generated/app_localizations.dart';

/// Curated vector icons that users can optionally scatter on a themed canvas.
/// Stored as compact `'icon:<key>'` tokens alongside plain emoji strings.
class PostThemePresetIcon {
  final String key;
  final IconData icon;

  const PostThemePresetIcon({required this.key, required this.icon});

  String get token => 'icon:$key';
}

abstract final class PostThemePresetIcons {
  static const String prefix = 'icon:';

  static const List<PostThemePresetIcon> all = [
    PostThemePresetIcon(key: 'sparkles', icon: Icons.auto_awesome_rounded),
    PostThemePresetIcon(key: 'heart', icon: Icons.favorite_rounded),
    PostThemePresetIcon(
      key: 'flame',
      icon: Icons.local_fire_department_rounded,
    ),
    PostThemePresetIcon(key: 'star', icon: Icons.star_rounded),
    PostThemePresetIcon(key: 'bolt', icon: Icons.bolt_rounded),
    PostThemePresetIcon(key: 'music', icon: Icons.music_note_rounded),
    PostThemePresetIcon(key: 'moon', icon: Icons.nightlight_round),
    PostThemePresetIcon(key: 'coffee', icon: Icons.local_cafe_rounded),
    PostThemePresetIcon(key: 'leaf', icon: Icons.spa_rounded),
    PostThemePresetIcon(key: 'gem', icon: Icons.diamond_rounded),
    PostThemePresetIcon(key: 'crown', icon: Icons.workspace_premium_rounded),
    PostThemePresetIcon(key: 'cloud', icon: Icons.wb_cloudy_rounded),
  ];

  static const List<String> quickEmojis = [
    '✨',
    '🔥',
    '❤️',
    '🌸',
    '🌊',
    '⭐',
    '🦋',
    '🌙',
    '☕',
    '💎',
    '🎉',
    '🌿',
  ];

  static bool isIconToken(String token) => token.startsWith(prefix);

  static IconData? resolveIcon(String token) {
    if (!isIconToken(token)) return null;
    final key = token.substring(prefix.length);
    for (final item in all) {
      if (item.key == key) return item.icon;
    }
    return null;
  }
}

/// Parsed representation of `posts.background_theme`.
///
/// Format:
/// - Plain gradient (default): `'sunset_blaze'`
/// - With user-selected motifs: `'sunset_blaze|s=482910|m=icon:sparkles,🔥'`
@immutable
class PostThemeSelection {
  static const int maxMotifs = 3;

  final PostBackgroundThemeModel theme;

  /// Optional user-chosen emojis or `'icon:<key>'` tokens (0..3 items).
  /// Empty means rely purely on the background gradient with zero icons.
  final List<String> motifs;

  /// Deterministic scatter seed for this post.
  final int seed;

  const PostThemeSelection({
    required this.theme,
    this.motifs = const [],
    this.seed = 0,
  });

  bool get hasMotifs => motifs.isNotEmpty;

  static int generateSeed() => 100000 + math.Random().nextInt(899999);

  PostThemeSelection copyWith({
    PostBackgroundThemeModel? theme,
    List<String>? motifs,
    int? seed,
  }) {
    return PostThemeSelection(
      theme: theme ?? this.theme,
      motifs: motifs ?? this.motifs,
      seed: seed ?? this.seed,
    );
  }

  /// Mixes [seed] with [postKey] (e.g. `post.id`) via FNV-1a so every post
  /// gets a unique count and layout without flickering on scroll/rebuild.
  int effectiveSeedForPost(String postKey) {
    int hash = 0x811c9dc5 ^ seed;
    for (final unit in postKey.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  String encode() {
    final cleaned =
        motifs
            .map(_sanitizeToken)
            .where((t) => t.isNotEmpty)
            .take(maxMotifs)
            .toList();
    if (cleaned.isEmpty) return theme.id;
    final effectiveSeed = seed <= 0 ? generateSeed() : seed;
    return '${theme.id}|s=$effectiveSeed|m=${cleaned.join(',')}';
  }

  static String? normalizeEncoded(String? raw) => parse(raw)?.encode();

  static PostThemeSelection? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parts = raw.split('|');
    final theme = PostBackgroundThemeModel.byId(parts.first.trim());
    if (theme == null) return null;

    int parsedSeed = 0;
    final parsedMotifs = <String>[];

    for (int i = 1; i < parts.length; i++) {
      final segment = parts[i].trim();
      if (segment.startsWith('s=')) {
        parsedSeed = int.tryParse(segment.substring(2)) ?? 0;
      } else if (segment.startsWith('m=')) {
        final rawItems = segment.substring(2).split(',');
        for (final item in rawItems) {
          final clean = _sanitizeToken(item);
          if (clean.isEmpty) continue;
          if (PostThemePresetIcons.isIconToken(clean) &&
              PostThemePresetIcons.resolveIcon(clean) == null) {
            continue;
          }
          if (!parsedMotifs.contains(clean)) {
            parsedMotifs.add(clean);
            if (parsedMotifs.length >= maxMotifs) break;
          }
        }
      }
    }

    return PostThemeSelection(
      theme: theme,
      motifs: List.unmodifiable(parsedMotifs),
      seed: parsedSeed,
    );
  }

  static String _sanitizeToken(String raw) =>
      raw.replaceAll(RegExp(r'[|,=\s]'), '').trim();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostThemeSelection &&
          other.theme == theme &&
          other.seed == seed &&
          listEquals(other.motifs, motifs));

  @override
  int get hashCode => Object.hash(theme, seed, Object.hashAll(motifs));
}

/// A Facebook-style colored background for text-only posts.
@immutable
class PostBackgroundThemeModel {
  final String id;

  /// Key of the localized name, resolved by [localizedName].
  final String nameKey;
  final Gradient gradient;

  /// High-contrast color for the post text.
  final Color textColor;

  /// Distinctive color used for @mentions drawn on top of this theme.
  final Color mentionColor;

  /// Distinctive color used for clickable URLs drawn on top of this theme.
  final Color linkColor;

  /// Harmonized tint color used to adapt background emojis/icons to this theme.
  final Color motifTintColor;

  /// Solid accent used for thumbnails and as a loading fallback.
  final Color previewColor;

  const PostBackgroundThemeModel({
    required this.id,
    required this.nameKey,
    required this.gradient,
    required this.textColor,
    required this.mentionColor,
    required this.linkColor,
    required this.motifTintColor,
    required this.previewColor,
  });

  /// True when the text is light (i.e. the theme background is dark).
  bool get isLightText => textColor.computeLuminance() > 0.5;

  /// Localized display name.
  String localizedName(AppLocalizations l10n) {
    switch (nameKey) {
      case 'themeSunsetBlaze':
        return l10n.themeSunsetBlaze;
      case 'themeNeonCyberpunk':
        return l10n.themeNeonCyberpunk;
      case 'themeEmeraldForest':
        return l10n.themeEmeraldForest;
      case 'themeOceanBreeze':
        return l10n.themeOceanBreeze;
      case 'themeRoyalAmethyst':
        return l10n.themeRoyalAmethyst;
      case 'themeSweetRomance':
        return l10n.themeSweetRomance;
      case 'themeGoldenHour':
        return l10n.themeGoldenHour;
      case 'themeHighVoltage':
        return l10n.themeHighVoltage;
      case 'themeWarmMocha':
        return l10n.themeWarmMocha;
      case 'themeAuroraBorealis':
        return l10n.themeAuroraBorealis;
      case 'themeCherryBlossom':
        return l10n.themeCherryBlossom;
      case 'themeMinimalistOnyx':
        return l10n.themeMinimalistOnyx;
      case 'themeSolidRed':
        return l10n.themeSolidRed;
      case 'themeSolidBlue':
        return l10n.themeSolidBlue;
      case 'themeSolidGreen':
        return l10n.themeSolidGreen;
      case 'themeSolidOrange':
        return l10n.themeSolidOrange;
      case 'themeSolidPurple':
        return l10n.themeSolidPurple;
      case 'themeSolidYellow':
        return l10n.themeSolidYellow;
      case 'themeSolidSlate':
        return l10n.themeSolidSlate;
      case 'themeSolidPink':
        return l10n.themeSolidPink;
      case 'themeSolidTeal':
        return l10n.themeSolidTeal;
      case 'themeSolidAmber':
        return l10n.themeSolidAmber;
      case 'themeSolidBrown':
        return l10n.themeSolidBrown;
      case 'themeSolidNavy':
        return l10n.themeSolidNavy;
    }
    return id;
  }

  static const PostBackgroundThemeModel sunsetBlaze = PostBackgroundThemeModel(
    id: 'sunset_blaze',
    nameKey: 'themeSunsetBlaze',
    gradient: LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFFFF8A00), Color(0xFFE5258A), Color(0xFF8E1B6B)],
    ),
    textColor: Colors.white,
    mentionColor: Color(0xFFFFE08A),
    linkColor: Color(0xFFB3F0FF),
    motifTintColor: Color(0xFFFFC4DC),
    previewColor: Color(0xFFE5258A),
  );

  static const PostBackgroundThemeModel neonCyberpunk =
      PostBackgroundThemeModel(
        id: 'neon_cyberpunk',
        nameKey: 'themeNeonCyberpunk',
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0B3D), Color(0xFF5B2A9D), Color(0xFF00C2D1)],
        ),
        textColor: Colors.white,
        mentionColor: Color(0xFF7DF9FF),
        linkColor: Color(0xFFFFB5E8),
        motifTintColor: Color(0xFFB8A4FF),
        previewColor: Color(0xFF5B2A9D),
      );

  static const PostBackgroundThemeModel emeraldForest =
      PostBackgroundThemeModel(
        id: 'emerald_forest',
        nameKey: 'themeEmeraldForest',
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B8F5B), Color(0xFF0A6F6A)],
        ),
        textColor: Colors.white,
        mentionColor: Color(0xFFC8FFB0),
        linkColor: Color(0xFFFFE699),
        motifTintColor: Color(0xFF9BF6D8),
        previewColor: Color(0xFF0B8F5B),
      );

  static const PostBackgroundThemeModel oceanBreeze = PostBackgroundThemeModel(
    id: 'ocean_breeze',
    nameKey: 'themeOceanBreeze',
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF38A9F5), Color(0xFF1B4FC4)],
    ),
    textColor: Colors.white,
    mentionColor: Color(0xFFFFF2A6),
    linkColor: Color(0xFFB8F8FF),
    motifTintColor: Color(0xFFB6E3FF),
    previewColor: Color(0xFF2A7DE1),
  );

  static const PostBackgroundThemeModel royalAmethyst =
      PostBackgroundThemeModel(
        id: 'royal_amethyst',
        nameKey: 'themeRoyalAmethyst',
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5E1E9E), Color(0xFF8E3FC4), Color(0xFFD9A526)],
        ),
        textColor: Colors.white,
        mentionColor: Color(0xFFFFE27A),
        linkColor: Color(0xFFC4F1FF),
        motifTintColor: Color(0xFFE7C6FF),
        previewColor: Color(0xFF8E3FC4),
      );

  static const PostBackgroundThemeModel sweetRomance = PostBackgroundThemeModel(
    id: 'sweet_romance',
    nameKey: 'themeSweetRomance',
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF6FA5), Color(0xFFC2185B)],
    ),
    textColor: Colors.white,
    mentionColor: Color(0xFFFFF0B8),
    linkColor: Color(0xFFC9F2FF),
    motifTintColor: Color(0xFFFFCADB),
    previewColor: Color(0xFFE2407E),
  );

  static const PostBackgroundThemeModel goldenHour = PostBackgroundThemeModel(
    id: 'golden_hour',
    nameKey: 'themeGoldenHour',
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFD27A), Color(0xFFFF8A65)],
    ),
    textColor: Color(0xDD000000),
    mentionColor: Color(0xFF8A2A00),
    linkColor: Color(0xFF0B4F8A),
    motifTintColor: Color(0xFF6E2600),
    previewColor: Color(0xFFFFAE6E),
  );

  static const PostBackgroundThemeModel highVoltage = PostBackgroundThemeModel(
    id: 'high_voltage',
    nameKey: 'themeHighVoltage',
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFB300), Color(0xFF5B4A1E), Color(0xFF1F2933)],
    ),
    textColor: Colors.white,
    mentionColor: Color(0xFFFFD54F),
    linkColor: Color(0xFF8BE9FD),
    motifTintColor: Color(0xFFFFE082),
    previewColor: Color(0xFF5B4A1E),
  );

  static const PostBackgroundThemeModel warmMocha = PostBackgroundThemeModel(
    id: 'warm_mocha',
    nameKey: 'themeWarmMocha',
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3B1F14), Color(0xFF7B4A2D), Color(0xFFB9803F)],
    ),
    textColor: Colors.white,
    mentionColor: Color(0xFFFFD9A0),
    linkColor: Color(0xFFAEE4FF),
    motifTintColor: Color(0xFFF5CBA7),
    previewColor: Color(0xFF7B4A2D),
  );

  static const PostBackgroundThemeModel auroraBorealis =
      PostBackgroundThemeModel(
        id: 'aurora_borealis',
        nameKey: 'themeAuroraBorealis',
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF14B8A6), Color(0xFF3B5BDB), Color(0xFF312E81)],
        ),
        textColor: Colors.white,
        mentionColor: Color(0xFFB8FFF0),
        linkColor: Color(0xFFFFE09E),
        motifTintColor: Color(0xFFA5F3FC),
        previewColor: Color(0xFF3B5BDB),
      );

  static const PostBackgroundThemeModel cherryBlossom =
      PostBackgroundThemeModel(
        id: 'cherry_blossom',
        nameKey: 'themeCherryBlossom',
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFC9DE), Color(0xFFF576A8)],
        ),
        textColor: Color(0xDD000000),
        mentionColor: Color(0xFF8A0F4A),
        linkColor: Color(0xFF0D47A1),
        motifTintColor: Color(0xFF7B1145),
        previewColor: Color(0xFFF8A1C4),
      );

  static const PostBackgroundThemeModel minimalistOnyx =
      PostBackgroundThemeModel(
        id: 'minimalist_onyx',
        nameKey: 'themeMinimalistOnyx',
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2F36), Color(0xFF14171C)],
        ),
        textColor: Colors.white,
        mentionColor: Color(0xFF9CC9FF),
        linkColor: Color(0xFFFFD580),
        motifTintColor: Color(0xFFCBD5E1),
        previewColor: Color(0xFF2B2F36),
      );

  static const PostBackgroundThemeModel solidRed = PostBackgroundThemeModel(
    id: 'solid_red',
    nameKey: 'themeSolidRed',
    gradient: LinearGradient(colors: [Color(0xFFE53935), Color(0xFFE53935)]),
    textColor: Colors.white,
    mentionColor: Color(0xFFFFEB3B),
    linkColor: Color(0xFFB3E5FC),
    motifTintColor: Color(0xFFFFCDD2),
    previewColor: Color(0xFFE53935),
  );

  static const PostBackgroundThemeModel solidBlue = PostBackgroundThemeModel(
    id: 'solid_blue',
    nameKey: 'themeSolidBlue',
    gradient: LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1E88E5)]),
    textColor: Colors.white,
    mentionColor: Color(0xFFFFF176),
    linkColor: Color(0xFF80D8FF),
    motifTintColor: Color(0xFFBBDEFB),
    previewColor: Color(0xFF1E88E5),
  );

  static const PostBackgroundThemeModel solidGreen = PostBackgroundThemeModel(
    id: 'solid_green',
    nameKey: 'themeSolidGreen',
    gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF2E7D32)]),
    textColor: Colors.white,
    mentionColor: Color(0xFFC8E6C9),
    linkColor: Color(0xFFFFF59D),
    motifTintColor: Color(0xFFA5D6A7),
    previewColor: Color(0xFF2E7D32),
  );

  static const PostBackgroundThemeModel solidOrange = PostBackgroundThemeModel(
    id: 'solid_orange',
    nameKey: 'themeSolidOrange',
    gradient: LinearGradient(colors: [Color(0xFFFB8C00), Color(0xFFFB8C00)]),
    textColor: Colors.white,
    mentionColor: Color(0xFFFFF9C4),
    linkColor: Color(0xFFE0F7FA),
    motifTintColor: Color(0xFFFFE0B2),
    previewColor: Color(0xFFFB8C00),
  );

  static const PostBackgroundThemeModel solidPurple = PostBackgroundThemeModel(
    id: 'solid_purple',
    nameKey: 'themeSolidPurple',
    gradient: LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF7B1FA2)]),
    textColor: Colors.white,
    mentionColor: Color(0xFFEA80FC),
    linkColor: Color(0xFFB2EBF2),
    motifTintColor: Color(0xFFE1BEE7),
    previewColor: Color(0xFF7B1FA2),
  );

  static const PostBackgroundThemeModel solidYellow = PostBackgroundThemeModel(
    id: 'solid_yellow',
    nameKey: 'themeSolidYellow',
    gradient: LinearGradient(colors: [Color(0xFFFBC02D), Color(0xFFFBC02D)]),
    textColor: Color(0xDD000000),
    mentionColor: Color(0xFFB71C1C),
    linkColor: Color(0xFF0D47A1),
    motifTintColor: Color(0xFF5D4037),
    previewColor: Color(0xFFFBC02D),
  );

  static const PostBackgroundThemeModel solidSlate = PostBackgroundThemeModel(
    id: 'solid_slate',
    nameKey: 'themeSolidSlate',
    gradient: LinearGradient(colors: [Color(0xFF455A64), Color(0xFF455A64)]),
    textColor: Colors.white,
    mentionColor: Color(0xFF80DEEA),
    linkColor: Color(0xFFFFE082),
    motifTintColor: Color(0xFFCFD8DC),
    previewColor: Color(0xFF455A64),
  );

  static const PostBackgroundThemeModel solidPink = PostBackgroundThemeModel(
    id: 'solid_pink',
    nameKey: 'themeSolidPink',
    gradient: LinearGradient(colors: [Color(0xFFD81B60), Color(0xFFD81B60)]),
    textColor: Colors.white,
    mentionColor: Color(0xFFFFF59D),
    linkColor: Color(0xFFB2EBF2),
    motifTintColor: Color(0xFFF8BBD0),
    previewColor: Color(0xFFD81B60),
  );

  static const PostBackgroundThemeModel solidTeal = PostBackgroundThemeModel(
    id: 'solid_teal',
    nameKey: 'themeSolidTeal',
    gradient: LinearGradient(colors: [Color(0xFF00897B), Color(0xFF00897B)]),
    textColor: Colors.white,
    mentionColor: Color(0xFFFFE082),
    linkColor: Color(0xFFE0F7FA),
    motifTintColor: Color(0xFFB2DFDB),
    previewColor: Color(0xFF00897B),
  );

  static const PostBackgroundThemeModel solidAmber = PostBackgroundThemeModel(
    id: 'solid_amber',
    nameKey: 'themeSolidAmber',
    gradient: LinearGradient(colors: [Color(0xFFFFB300), Color(0xFFFFB300)]),
    textColor: Color(0xDD000000),
    mentionColor: Color(0xFF880E4F),
    linkColor: Color(0xFF0D47A1),
    motifTintColor: Color(0xFF4E342E),
    previewColor: Color(0xFFFFB300),
  );

  static const PostBackgroundThemeModel solidBrown = PostBackgroundThemeModel(
    id: 'solid_brown',
    nameKey: 'themeSolidBrown',
    gradient: LinearGradient(colors: [Color(0xFF4E342E), Color(0xFF4E342E)]),
    textColor: Colors.white,
    mentionColor: Color(0xFFFFE082),
    linkColor: Color(0xFFB3E5FC),
    motifTintColor: Color(0xFFD7CCC8),
    previewColor: Color(0xFF4E342E),
  );

  static const PostBackgroundThemeModel solidNavy = PostBackgroundThemeModel(
    id: 'solid_navy',
    nameKey: 'themeSolidNavy',
    gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF1A237E)]),
    textColor: Colors.white,
    mentionColor: Color(0xFF80D8FF),
    linkColor: Color(0xFFFFD54F),
    motifTintColor: Color(0xFFC5CAE9),
    previewColor: Color(0xFF1A237E),
  );

  /// The 12 vibrant gradient themes.
  static const List<PostBackgroundThemeModel> gradients = [
    sunsetBlaze,
    neonCyberpunk,
    emeraldForest,
    oceanBreeze,
    royalAmethyst,
    sweetRomance,
    goldenHour,
    highVoltage,
    warmMocha,
    auroraBorealis,
    cherryBlossom,
    minimalistOnyx,
  ];

  /// The 12 classic solid single-color themes.
  static const List<PostBackgroundThemeModel> solids = [
    solidRed,
    solidBlue,
    solidGreen,
    solidOrange,
    solidPurple,
    solidYellow,
    solidSlate,
    solidPink,
    solidTeal,
    solidAmber,
    solidBrown,
    solidNavy,
  ];

  /// All themes in display order (gradients first, followed by solid colors).
  static const List<PostBackgroundThemeModel> all = [...gradients, ...solids];

  /// Resolves either a bare theme id (`'sunset_blaze'`) or a full encoded
  /// selection string (`'sunset_blaze|s=123|m=🔥'`).
  static PostBackgroundThemeModel? byId(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final baseId = raw.split('|').first.trim();
    if (baseId.isEmpty) return null;
    for (final theme in all) {
      if (theme.id == baseId) return theme;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostBackgroundThemeModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
