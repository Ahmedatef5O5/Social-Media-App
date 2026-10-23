import 'package:flutter/widgets.dart';
import '../../../core/localization/l10n_extension.dart';

enum AiReplyTone { standard, formal, enthusiastic, casual, encouraging }

extension AiReplyToneX on AiReplyTone {
  String get storageValue => name;

  String get wireValue {
    switch (this) {
      case AiReplyTone.standard:
        return 'standard';
      case AiReplyTone.formal:
        return 'formal';
      case AiReplyTone.enthusiastic:
        return 'enthusiastic';
      case AiReplyTone.casual:
        return 'casual';
      case AiReplyTone.encouraging:
        return 'encouraging';
    }
  }

  String localizedTitle(BuildContext context) {
    switch (this) {
      case AiReplyTone.standard:
        return context.l10n.aiToneDefaultTitle;
      case AiReplyTone.formal:
        return context.l10n.aiToneFormalTitle;
      case AiReplyTone.enthusiastic:
        return context.l10n.aiToneEnthusiasticTitle;
      case AiReplyTone.casual:
        return context.l10n.aiToneCasualTitle;
      case AiReplyTone.encouraging:
        return context.l10n.aiToneEncouragingTitle;
    }
  }

  String localizedDescription(BuildContext context) {
    switch (this) {
      case AiReplyTone.standard:
        return context.l10n.aiToneDefaultDesc;
      case AiReplyTone.formal:
        return context.l10n.aiToneFormalDesc;
      case AiReplyTone.enthusiastic:
        return context.l10n.aiToneEnthusiasticDesc;
      case AiReplyTone.casual:
        return context.l10n.aiToneCasualDesc;
      case AiReplyTone.encouraging:
        return context.l10n.aiToneEncouragingDesc;
    }
  }

  String get displayLabel {
    switch (this) {
      case AiReplyTone.standard:
        return 'Default';
      case AiReplyTone.formal:
        return 'Formal';
      case AiReplyTone.enthusiastic:
        return 'Enthusiastic';
      case AiReplyTone.casual:
        return 'Casual';
      case AiReplyTone.encouraging:
        return 'Encouraging';
    }
  }

  static AiReplyTone fromStorage(String? value) {
    return AiReplyTone.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AiReplyTone.standard,
    );
  }
}
