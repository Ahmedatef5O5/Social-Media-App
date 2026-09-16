import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../ai_chat/helpers/ai_model_iconography.dart';

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

  FaIconData get icon {
    switch (this) {
      case AiActiveProvider.gemini:
        return AiModelIconography.geminiFallbackIcon;
      case AiActiveProvider.groq:
        return AiModelIconography.groqIcon;
      case AiActiveProvider.openRouter:
        return AiModelIconography.openRouterIcon;
      case AiActiveProvider.unknown:
        return AiModelIconography.unknownIcon;
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
