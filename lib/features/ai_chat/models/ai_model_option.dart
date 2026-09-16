import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../helpers/ai_model_iconography.dart';

enum AiModelProvider { gemini, llama, openrouter }

class AiModelOption {
  final AiModelProvider provider;
  final String name;
  final String tagline;
  final FaIconData icon;
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

  static final List<AiModelOption> all = [
    AiModelOption(
      provider: AiModelProvider.gemini,
      name: 'Gemini',
      tagline: 'Fast, and great with images',
      icon: AiModelIconography.geminiFallbackIcon,
      accentColor: AiModelIconography.geminiColor,
    ),
    const AiModelOption(
      provider: AiModelProvider.llama,
      name: 'Llama',
      tagline: 'Open-weight and efficient',
      icon: AiModelIconography.groqIcon,
      accentColor: AiModelIconography.groqColor,
    ),
    const AiModelOption(
      provider: AiModelProvider.openrouter,
      name: 'OpenRouter',
      tagline: 'Auto-picks a free model for you',
      icon: AiModelIconography.openRouterIcon,
      accentColor: AiModelIconography.openRouterColor,
    ),
  ];

  static AiModelOption get defaultModel => all.first;
}
