import 'package:flutter/material.dart';

enum AiActiveProvider { gemini, groq, openRouter, unknown }

extension AiActiveProviderX on AiActiveProvider {
  String get displayName {
    switch (this) {
      case AiActiveProvider.gemini:
        return 'Gemini';
      case AiActiveProvider.groq:
        return 'Groq';
      case AiActiveProvider.openRouter:
        return 'OpenRouter';
      case AiActiveProvider.unknown:
        return 'AI Assistant';
    }
  }

  IconData get icon {
    switch (this) {
      case AiActiveProvider.gemini:
        return Icons.auto_awesome_rounded;
      case AiActiveProvider.groq:
        return Icons.bolt_rounded;
      case AiActiveProvider.openRouter:
        return Icons.hub_rounded;
      case AiActiveProvider.unknown:
        return Icons.smart_toy_outlined;
    }
  }

  String get wireValue {
    switch (this) {
      case AiActiveProvider.gemini:
        return 'gemini';
      case AiActiveProvider.groq:
        return 'groq';
      case AiActiveProvider.openRouter:
        return 'openrouter';
      case AiActiveProvider.unknown:
        return 'unknown';
    }
  }

  static AiActiveProvider fromWireValue(String? value) {
    switch (value) {
      case 'gemini':
        return AiActiveProvider.gemini;
      case 'groq':
        return AiActiveProvider.groq;
      case 'openrouter':
        return AiActiveProvider.openRouter;
      default:
        return AiActiveProvider.unknown;
    }
  }

  bool get supportsVision {
    switch (this) {
      case AiActiveProvider.gemini:
      case AiActiveProvider.openRouter:
      case AiActiveProvider.unknown:
        return true;
      case AiActiveProvider.groq:
        return false;
    }
  }
}
