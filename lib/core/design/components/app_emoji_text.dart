import 'package:flutter/material.dart';
import 'package:social_media_app/core/design/tokens/typography.dart';

class AppEmojiText extends StatelessWidget {
  final String emoji;
  final double fontSize;

  const AppEmojiText(this.emoji, {super.key, this.fontSize = 20.0});

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji,
      style: AppTypography.emojiTextStyle.copyWith(fontSize: fontSize),
    );
  }
}
