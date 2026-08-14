import 'package:flutter/material.dart';
import '../helpers/bidi_text_helper.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final direction = BidiTextHelper.detectDirection(controller.text);
        return TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          minLines: minLines,
          maxLines: maxLines,
          style: style,
          cursorColor: cursorColor,
          textInputAction: textInputAction,
          textDirection: direction,
          textAlign: BidiTextHelper.alignFor(direction),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: decoration,
        );
      },
    );
  }
}
