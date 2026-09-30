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

  bool _isInsertingMention = false;

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
        name: mentionCore,
        start: replaceStart,
        end: replaceStart + mentionCore.length,
      ),
    );

    _isInsertingMention = true;
    try {
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: replaceStart + insertedText.length,
        ),
      );
    } finally {
      _isInsertingMention = false;
    }
  }

  void setMentions(List<MentionRef> refs) {
    final cleanRefs = MentionRef.keepLatestBatch(refs);
    _mentions
      ..clear()
      ..addAll(
        cleanRefs
            .where((r) {
              return r.startIndex >= 0 &&
                  r.endIndex <= text.length &&
                  r.startIndex < r.endIndex;
            })
            .map(
              (r) => _ActiveMention(
                userId: r.mentionedUserId,
                name: EmojiHelper.normalize(
                  text.substring(r.startIndex, r.endIndex),
                ),
                start: r.startIndex,
                end: r.endIndex,
              ),
            ),
      );
    notifyListeners();
  }

  void _reconcileMentions(String oldText, String newText) {
    if (_mentions.isEmpty || oldText == newText) return;

    int prefixLen = 0;
    final int minLen =
        oldText.length < newText.length ? oldText.length : newText.length;
    while (prefixLen < minLen &&
        oldText.codeUnitAt(prefixLen) == newText.codeUnitAt(prefixLen)) {
      prefixLen++;
    }

    int suffixLen = 0;
    while (suffixLen < (oldText.length - prefixLen) &&
        suffixLen < (newText.length - prefixLen) &&
        oldText.codeUnitAt(oldText.length - 1 - suffixLen) ==
            newText.codeUnitAt(newText.length - 1 - suffixLen)) {
      suffixLen++;
    }

    final int editStart = prefixLen;
    final int oldEditEnd = oldText.length - suffixLen;
    final int delta = newText.length - oldText.length;

    for (final m in _mentions) {
      if (m.end <= editStart) {
        continue;
      } else if (m.start >= oldEditEnd) {
        m.start += delta;
        m.end += delta;
      } else {
        m.start += delta;
        m.end = m.start + m.name.length;
      }
    }

    _reanchorAndPrune(newText);
  }

  void _reanchorAndPrune(String currentText) {
    if (_mentions.isEmpty) return;

    bool isExactMatch(_ActiveMention m) {
      return m.start >= 0 &&
          m.end <= currentText.length &&
          m.start < m.end &&
          currentText.substring(m.start, m.end) == m.name;
    }

    bool overlapsClaimed(int start, int end, _ActiveMention self) {
      for (final other in _mentions) {
        if (identical(other, self)) continue;
        if (!isExactMatch(other)) continue;
        if (start < other.end && end > other.start) return true;
      }
      return false;
    }

    final toRemove = <_ActiveMention>[];

    for (final m in _mentions) {
      if (isExactMatch(m) && !overlapsClaimed(m.start, m.end, m)) {
        continue;
      }

      if (m.name.isEmpty) {
        toRemove.add(m);
        continue;
      }

      int? bestStart;
      int bestDistance = 1 << 30;
      int searchFrom = 0;

      while (searchFrom <= currentText.length - m.name.length) {
        final idx = currentText.indexOf(m.name, searchFrom);
        if (idx == -1) break;
        final candidateEnd = idx + m.name.length;
        if (!overlapsClaimed(idx, candidateEnd, m)) {
          final dist = (idx - m.start).abs();
          if (dist < bestDistance) {
            bestDistance = dist;
            bestStart = idx;
          }
        }
        searchFrom = idx + 1;
      }

      if (bestStart != null) {
        m.start = bestStart;
        m.end = bestStart + m.name.length;
      } else {
        toRemove.add(m);
      }
    }

    if (toRemove.isNotEmpty) {
      _mentions.removeWhere(toRemove.contains);
    }
  }

  List<MentionRef> _activeRefsForRawText() {
    _reanchorAndPrune(text);
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

  List<MentionRef> get validMentions {
    _reanchorAndPrune(text);
    final int leadingTrim = text.length - text.trimLeft().length;
    final int trimmedLength = text.trim().length;

    return _mentions
        .map(
          (m) => MentionRef(
            mentionedUserId: m.userId,
            startIndex: m.start - leadingTrim,
            endIndex: m.end - leadingTrim,
          ),
        )
        .where(
          (ref) =>
              ref.startIndex >= 0 &&
              ref.endIndex <= trimmedLength &&
              ref.startIndex < ref.endIndex,
        )
        .toList();
  }

  void clearMentions() => _mentions.clear();

  @override
  set value(TextEditingValue newValue) {
    final String oldText = super.value.text;
    final normalized = EmojiHelper.normalize(newValue.text);

    if (!_isInsertingMention && oldText != normalized) {
      _reconcileMentions(oldText, normalized);
    }

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

    final mentions = _activeRefsForRawText();
    if (mentions.isEmpty) {
      return TextSpan(text: text, style: effectiveStyle);
    }

    final sorted = List<MentionRef>.from(mentions)
      ..sort((a, b) => a.startIndex.compareTo(b.startIndex));

    final spans = <TextSpan>[];
    int cursor = 0;
    final highlightStyle = effectiveStyle
        .merge(mentionStyle)
        .copyWith(
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
      spans.add(TextSpan(text: text.substring(cursor), style: effectiveStyle));
    }

    return TextSpan(style: effectiveStyle, children: spans);
  }
}
