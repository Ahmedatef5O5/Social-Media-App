import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class FeedbackStarRatingBar extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final double size;
  final bool readOnly;

  const FeedbackStarRatingBar({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 38,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFFB400);
    final empty =
        Theme.of(context).brightness == Brightness.dark
            ? Colors.white24
            : Colors.black26;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = (value ?? 0) >= star;
        return Semantics(
          button: !readOnly,
          label: context.l10n.starsCount(star),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap:
                readOnly
                    ? null
                    : () {
                      HapticFeedback.selectionClick();
                      onChanged(value == star ? null : star);
                    },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  key: ValueKey('$star-$filled'),
                  size: size,
                  color: filled ? amber : empty,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
