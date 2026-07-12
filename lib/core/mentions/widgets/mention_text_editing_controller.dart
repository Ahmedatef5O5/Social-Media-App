import 'package:flutter/material.dart';
import '../models/mention_ref.dart';

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
    final mentionCore = name;
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
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final mentions = validMentions;
    if (mentions.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    final sorted = List<MentionRef>.from(mentions)
      ..sort((a, b) => a.startIndex.compareTo(b.startIndex));

    final spans = <TextSpan>[];
    int cursor = 0;
    final highlightStyle = (style ?? const TextStyle()).merge(mentionStyle);

    for (final m in sorted) {
      if (m.startIndex > cursor) {
        spans.add(
          TextSpan(text: text.substring(cursor, m.startIndex), style: style),
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
      spans.add(TextSpan(text: text.substring(cursor), style: style));
    }

    return TextSpan(style: style, children: spans);
  }
}
