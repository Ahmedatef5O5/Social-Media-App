import 'package:flutter/material.dart';

@immutable
class AiModelDisplay {
  final String label;
  final String providerLabel;
  final Color accentColor;
  final IconData icon;

  const AiModelDisplay({
    required this.label,
    required this.providerLabel,
    required this.accentColor,
    required this.icon,
  });

  String get fullLabel =>
      providerLabel == 'OpenRouter' ? '$label (via OpenRouter)' : label;

  static const _geminiColor = Color(0xFF4285F4);
  static const _groqColor = Color(0xFF7C5CFC);
  static const _openrouterColor = Color(0xFFDA7756);
  static const _unknownColor = Color(0xFF9AA0A6);

  factory AiModelDisplay.fromRaw(String provider, String model) {
    final providerLabel = switch (provider) {
      'gemini' => 'Gemini',
      'groq' => 'Groq',
      'openrouter' => 'OpenRouter',
      _ => provider.isEmpty ? 'Syncra' : provider,
    };
    final color = switch (provider) {
      'gemini' => _geminiColor,
      'groq' => _groqColor,
      'openrouter' => _openrouterColor,
      _ => _unknownColor,
    };
    final icon = switch (provider) {
      'gemini' => Icons.auto_awesome_rounded,
      'groq' => Icons.hub_rounded,
      'openrouter' => Icons.alt_route_rounded,
      _ => Icons.smart_toy_rounded,
    };

    final prettyModel = _prettify(model);

    return AiModelDisplay(
      label: prettyModel.isEmpty ? providerLabel : prettyModel,
      providerLabel: providerLabel,
      accentColor: color,
      icon: icon,
    );
  }

  static String _prettify(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return '';

    final slash = s.lastIndexOf('/');
    if (slash != -1) s = s.substring(slash + 1);
    final colon = s.indexOf(':');
    if (colon != -1) s = s.substring(0, colon);

    final parts = s.split(RegExp(r'[-_]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';

    return parts
        .map((p) {
          if (RegExp(r'^[0-9]').hasMatch(p)) {
            return p.replaceAllMapped(
              RegExp(r'^([0-9.]+)([a-zA-Z]*)$'),
              (m) => '${m[1]}${(m[2] ?? '').toUpperCase()}',
            );
          }
          return p[0].toUpperCase() + p.substring(1);
        })
        .join(' ');
  }
}
