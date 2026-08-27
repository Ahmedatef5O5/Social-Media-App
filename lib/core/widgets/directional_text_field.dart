import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/tokens/typography.dart';
import '../helpers/bidi_text_helper.dart';
import '../helpers/emoji_text_input_formatter.dart';

class DirectionalTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final int? minLines;
  final int? maxLines;
  final TextStyle? style;
  final Color? cursorColor;
  final TextInputAction? textInputAction;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const DirectionalTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.enabled = true,
    this.minLines,
    this.maxLines,
    this.style,
    this.cursorColor,
    this.textInputAction,
    this.decoration,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final direction = BidiTextHelper.detectDirection(controller.text);

        InputDecoration? effectiveDecoration = decoration;
        if (effectiveDecoration != null &&
            effectiveDecoration.border == InputBorder.none) {
          effectiveDecoration = effectiveDecoration.copyWith(
            filled: effectiveDecoration.filled ?? false,
            fillColor: effectiveDecoration.fillColor ?? Colors.transparent,
            enabledBorder:
                effectiveDecoration.enabledBorder ?? InputBorder.none,
            focusedBorder:
                effectiveDecoration.focusedBorder ?? InputBorder.none,
            errorBorder: effectiveDecoration.errorBorder ?? InputBorder.none,
            disabledBorder:
                effectiveDecoration.disabledBorder ?? InputBorder.none,
          );
        }

        final effectiveStyle = (style ??
                Theme.of(context).textTheme.bodyLarge ??
                const TextStyle())
            .copyWith(
              fontFamily: null,
              fontFamilyFallback: AppTypography.fontFallback,
              color:
                  style?.color ??
                  (Theme.of(context).brightness == Brightness.light
                      ? Colors.black87
                      : Colors.white),
              fontWeight: style?.fontWeight ?? FontWeight.w400,
            );

        return TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          minLines: minLines,
          maxLines: maxLines,
          style: effectiveStyle,
          cursorColor: cursorColor,
          textInputAction: textInputAction,
          textDirection: direction,
          textAlign: BidiTextHelper.alignFor(direction),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          inputFormatters: [
            if (inputFormatters != null) ...inputFormatters!,
            EmojiTextInputFormatter(),
          ],
          decoration: effectiveDecoration,
        );
      },
    );
  }
}
