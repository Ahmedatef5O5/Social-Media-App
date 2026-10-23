import 'package:flutter/widgets.dart';
import '../../../core/localization/l10n_extension.dart';

enum AiReplyLength { standard, short, detailed }

extension AiReplyLengthX on AiReplyLength {
  String get storageValue => name;

  String get wireValue {
    switch (this) {
      case AiReplyLength.standard:
        return 'standard';
      case AiReplyLength.short:
        return 'short';
      case AiReplyLength.detailed:
        return 'detailed';
    }
  }

  String localizedTitle(BuildContext context) {
    switch (this) {
      case AiReplyLength.standard:
        return context.l10n.aiLengthDefaultTitle;
      case AiReplyLength.short:
        return context.l10n.aiLengthShortTitle;
      case AiReplyLength.detailed:
        return context.l10n.aiLengthDetailedTitle;
    }
  }

  String localizedDescription(BuildContext context) {
    switch (this) {
      case AiReplyLength.standard:
        return context.l10n.aiLengthDefaultDesc;
      case AiReplyLength.short:
        return context.l10n.aiLengthShortDesc;
      case AiReplyLength.detailed:
        return context.l10n.aiLengthDetailedDesc;
    }
  }

  String get displayLabel {
    switch (this) {
      case AiReplyLength.standard:
        return 'Default';
      case AiReplyLength.short:
        return 'Short';
      case AiReplyLength.detailed:
        return 'Detailed';
    }
  }

  static AiReplyLength fromStorage(String? value) {
    return AiReplyLength.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AiReplyLength.standard,
    );
  }
}
