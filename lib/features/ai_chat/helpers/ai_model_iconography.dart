import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/gemini_sparkle_icon.dart';

enum AiModelBrand { gemini, groq, openRouter, unknown }

class AiModelIconography {
  const AiModelIconography._();

  static const Color geminiColor = Color(0xFF4285F4);
  static const Color groqColor = Color(0xFF7C5CFC);
  static const Color openRouterColor = Color(0xFFDA7756);
  static const Color unknownColor = Color(0xFF9AA0A6);

  // Gemini is drawn dynamically with GeminiSparkleIcon, robot for fallback
  static const FaIconData geminiFallbackIcon = FontAwesomeIcons.robot;
  // Official Meta brand icon for Llama
  static const FaIconData groqIcon = FontAwesomeIcons.meta;
  static const FaIconData openRouterIcon = FontAwesomeIcons.shuffle;
  static const FaIconData unknownIcon = FontAwesomeIcons.robot;

  static AiModelBrand brandFromWire(String? provider) => switch (provider
      ?.toLowerCase()) {
    'gemini' => AiModelBrand.gemini,
    'groq' || 'llama' => AiModelBrand.groq,
    'openrouter' => AiModelBrand.openRouter,
    _ => AiModelBrand.unknown,
  };

  static FaIconData iconFor(AiModelBrand brand) => switch (brand) {
    AiModelBrand.gemini => geminiFallbackIcon,
    AiModelBrand.groq => groqIcon,
    AiModelBrand.openRouter => openRouterIcon,
    AiModelBrand.unknown => unknownIcon,
  };

  static Color colorFor(AiModelBrand brand) => switch (brand) {
    AiModelBrand.gemini => geminiColor,
    AiModelBrand.groq => groqColor,
    AiModelBrand.openRouter => openRouterColor,
    AiModelBrand.unknown => unknownColor,
  };

  /// Builds the real brand icon with proper centering.
  /// For Gemini, renders the real 4-pointed gradient sparkle.
  /// For Meta/Llama, renders the official Meta logo.
  static Widget buildBrandIcon(
    AiModelBrand brand, {
    double size = 18,
    Color? color,
    bool useOriginalColors = false,
  }) {
    if (brand == AiModelBrand.gemini) {
      return GeminiSparkleIcon(
        size: size,
        color: useOriginalColors ? null : (color ?? geminiColor),
      );
    }

    final iconData = iconFor(brand);
    final iconColor = color ?? colorFor(brand);
    return Center(child: FaIcon(iconData, size: size, color: iconColor));
  }
}
