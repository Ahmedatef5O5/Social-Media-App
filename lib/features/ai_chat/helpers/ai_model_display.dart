import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'ai_model_iconography.dart';

@immutable
class AiModelDisplay {
  final String label;
  final String providerLabel;
  final Color accentColor;
  final FaIconData icon;

  const AiModelDisplay({
    required this.label,
    required this.providerLabel,
    required this.accentColor,
    required this.icon,
  });

  String get fullLabel =>
      providerLabel == 'OpenRouter' ? '$label (via OpenRouter)' : label;

  factory AiModelDisplay.fromRaw(String provider, String model) {
    final providerLabel = switch (provider) {
      'gemini' => 'Gemini',
      'groq' => 'Groq',
      'openrouter' => 'OpenRouter',
      _ => provider.isEmpty ? 'Syncra' : provider,
    };

    final brand = AiModelIconography.brandFromWire(provider);
    final color = AiModelIconography.colorFor(brand);
    final icon = AiModelIconography.iconFor(brand);

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
