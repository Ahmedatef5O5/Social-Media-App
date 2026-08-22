import '../models/ai_chat_language.dart';
import '../models/ai_chat_tone.dart';
import '../../../core/helpers/chat_helper.dart';

class AiChatStyleHint {
  final AiChatLanguage language;
  final AiChatTone tone;

  const AiChatStyleHint({required this.language, required this.tone});
}

class AiChatStyleHeuristic {
  AiChatStyleHeuristic._();

  static final RegExp _emojiPattern = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{1F1E6}-\u{1F1FF}]',
    unicode: true,
  );

  static const int _maxSampledMessages = 5;
  static const double _emojiDensityThreshold = 0.04;
  static const int _casualWordThreshold = 4;
  static const int _formalWordThreshold = 18;

  static AiChatStyleHint infer(List<String> recentUserTexts) {
    final sample = recentUserTexts
        .where((t) => t.trim().isNotEmpty)
        .toList(growable: false);
    final sampled =
        sample.length > _maxSampledMessages
            ? sample.sublist(sample.length - _maxSampledMessages)
            : sample;

    if (sampled.isEmpty) {
      return const AiChatStyleHint(
        language: AiChatLanguage.auto,
        tone: AiChatTone.standard,
      );
    }

    return AiChatStyleHint(
      language: _inferLanguage(sampled),
      tone: _inferTone(sampled),
    );
  }

  static AiChatLanguage _inferLanguage(List<String> texts) {
    final arabicCount = texts.where(ChatHelper.isArabic).length;
    final ratio = arabicCount / texts.length;
    if (ratio >= 0.6) return AiChatLanguage.arabic;
    if (ratio <= 0.4) return AiChatLanguage.english;
    return AiChatLanguage.auto;
  }

  static AiChatTone _inferTone(List<String> texts) {
    final combined = texts.join(' ');
    final totalChars = combined.runes.length;
    final emojiCount = _emojiPattern.allMatches(combined).length;
    final emojiDensity = totalChars == 0 ? 0.0 : emojiCount / totalChars;

    final totalWords = texts.fold<int>(
      0,
      (sum, t) => sum + t.trim().split(RegExp(r'\s+')).length,
    );
    final avgWordsPerMessage = totalWords / texts.length;

    if (emojiDensity >= _emojiDensityThreshold) return AiChatTone.enthusiastic;
    if (avgWordsPerMessage <= _casualWordThreshold) return AiChatTone.casual;
    if (avgWordsPerMessage >= _formalWordThreshold) return AiChatTone.formal;
    return AiChatTone.standard;
  }
}
