import 'package:flutter/material.dart';

class CreatePostInputField extends StatelessWidget {
  final TextEditingController _textEditingController;
  final bool _hasText;
  final FocusNode? focusNode;

  const CreatePostInputField({
    super.key,
    required TextEditingController textEditingController,
    required bool hasText,
    this.focusNode,
  }) : _textEditingController = textEditingController,
       _hasText = hasText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textEditingController,
      focusNode: focusNode,
      maxLines: null,
      maxLength: 140,
      style: TextStyle(fontSize: 18),
      decoration: InputDecoration(
        hintText: "What's on your head?",
        hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
          fontSize: 19,
          fontWeight: FontWeight.w400,
        ),
        counterText: _hasText ? null : '',
        counterStyle: TextStyle(
          color: _textEditingController.text.length >= 140 ? Colors.red : null,
          fontWeight:
              _textEditingController.text.length >= 140
                  ? FontWeight.bold
                  : null,
        ),
        border: InputBorder.none,
      ),
    );
  }
}
