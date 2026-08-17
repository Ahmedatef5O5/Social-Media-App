import 'package:flutter/material.dart';

enum AiModelProvider { gemini, llama, openrouter }

class AiModelOption {
  final AiModelProvider provider;
  final String name;
  final String tagline;
  final IconData icon;
  final Color accentColor;

  const AiModelOption({
    required this.provider,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.accentColor,
  });
}

class AiModelCatalog {
  const AiModelCatalog._();

  static const List<AiModelOption> all = [
    AiModelOption(
      provider: AiModelProvider.gemini,
      name: 'Gemini',
      tagline: 'Fast, and great with images',
      icon: Icons.auto_awesome_rounded,
      accentColor: Color(0xFF4285F4),
    ),
    AiModelOption(
      provider: AiModelProvider.llama,
      name: 'Llama',
      tagline: 'Open-weight and efficient',
      icon: Icons.hub_rounded,
      accentColor: Color(0xFF7C5CFC),
    ),
    AiModelOption(
      provider: AiModelProvider.openrouter,
      name: 'OpenRouter',
      tagline: 'Auto-picks a free model for you',
      icon: Icons.alt_route_rounded,
      accentColor: Color(0xFFDA7756),
    ),
  ];

  static AiModelOption get defaultModel => all.first;
}
