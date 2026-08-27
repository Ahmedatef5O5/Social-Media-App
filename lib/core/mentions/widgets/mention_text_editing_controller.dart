import 'package:flutter/material.dart';
import '../../design/tokens/typography.dart';
import '../models/mention_ref.dart';

import '../../helpers/emoji_helper.dart';

class _ActiveMention {
  final String userId;
  final String name;
  int start;
  int end;

  _ActiveMention({
    required this.userId,
    required this.name,
    required this.start,
    required this.end,
  });
}

class MentionTextEditingController extends TextEditingController {
  MentionTextEditingController({
    this.mentionStyle = const TextStyle(
      color: Colors.blue,
      fontWeight: FontWeight.w700,
      fontFamilyFallback: AppTypography.fontFallback,
    ),
  });

  final TextStyle mentionStyle;
  final List<_ActiveMention> _mentions = [];

  void insertMention({
    required String userId,
    required String name,
    required int replaceStart,
    required int replaceEnd,
  }) {
    final mentionCore = EmojiHelper.normalize(name);
    final insertedText = '$mentionCore ';
    final newText = text.replaceRange(replaceStart, replaceEnd, insertedText);
    final delta = insertedText.length - (replaceEnd - replaceStart);

    for (final m in _mentions) {
      if (m.start >= replaceEnd) {
        m.start += delta;
        m.end += delta;
      }
    }

    _mentions.add(
      _ActiveMention(
        userId: userId,
        name: name,
        start: replaceStart,
        end: replaceStart + mentionCore.length,
      ),
    );

    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: replaceStart + insertedText.length,
      ),
    );
  }

  void setMentions(List<MentionRef> refs) {
    _mentions
      ..clear()
      ..addAll(
        refs
            .where((r) {
              return r.startIndex >= 0 &&
                  r.endIndex <= text.length &&
                  r.startIndex < r.endIndex;
            })
            .map(
              (r) => _ActiveMention(
                userId: r.mentionedUserId,
                name: text.substring(r.startIndex, r.endIndex),
                start: r.startIndex,
                end: r.endIndex,
              ),
            ),
      );
    notifyListeners();
  }

  List<MentionRef> get validMentions {
    _mentions.removeWhere((m) {
      if (m.start < 0 || m.end > text.length || m.start >= m.end) return true;
      return text.substring(m.start, m.end) != m.name;
    });
    return _mentions
        .map(
          (m) => MentionRef(
            mentionedUserId: m.userId,
            startIndex: m.start,
            endIndex: m.end,
          ),
        )
        .toList();
  }

  void clearMentions() => _mentions.clear();

  @override
  set value(TextEditingValue newValue) {
    final normalized = EmojiHelper.normalize(newValue.text);
    if (normalized != newValue.text) {
      int countAddedBefore(int offset) {
        if (offset < 0 || offset > newValue.text.length) return 0;
        final String before = newValue.text.substring(0, offset);
        final String normalizedBefore = EmojiHelper.normalize(before);
        return normalizedBefore.length - before.length;
      }

      int newBase = newValue.selection.baseOffset;
      int newExtent = newValue.selection.extentOffset;

      if (newValue.selection.isValid) {
        newBase += countAddedBefore(newBase);
        newExtent += countAddedBefore(newExtent);
      }

      super.value = newValue.copyWith(
        text: normalized,
        selection: newValue.selection.copyWith(
          baseOffset: newBase,
          extentOffset: newExtent,
        ),
      );
    } else {
      super.value = newValue;
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final effectiveStyle = (style ?? const TextStyle()).copyWith(
      fontFamily: null,
      fontFamilyFallback: AppTypography.fontFallback,
    );

    final mentions = validMentions;
    if (mentions.isEmpty) {
      return TextSpan(text: text, style: effectiveStyle);
    }

    final sorted = List<MentionRef>.from(mentions)
      ..sort((a, b) => a.startIndex.compareTo(b.startIndex));

    final spans = <TextSpan>[];
    int cursor = 0;
    final highlightStyle = effectiveStyle.merge(mentionStyle).copyWith(
      fontFamily: null,
      fontFamilyFallback: AppTypography.fontFallback,
    );

    for (final m in sorted) {
      if (m.startIndex > cursor) {
        spans.add(
          TextSpan(
            text: text.substring(cursor, m.startIndex),
            style: effectiveStyle,
          ),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(m.startIndex, m.endIndex),
          style: highlightStyle,
        ),
      );
      cursor = m.endIndex;
    }
    if (cursor < text.length) {
      spans.add(
        TextSpan(text: text.substring(cursor), style: effectiveStyle),
      );
    }

    return TextSpan(style: effectiveStyle, children: spans);
  }
}
