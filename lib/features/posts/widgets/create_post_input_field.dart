import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/mentions/mentions.dart';
import '../../ai_assistant/entities/ai_action_type.dart';
import '../../ai_assistant/entities/ai_request_context.dart';
import '../../ai_assistant/widgets/ai_action_icon.dart';

class CreatePostInputField extends StatelessWidget {
  final MentionTextEditingController _textEditingController;
  final bool _hasText;
  final FocusNode focusNode;
  final bool hasMediaAttached;
  final AiTargetMediaType targetMediaType;
  final Future<Uint8List?> Function()? imageBytesProvider;

  const CreatePostInputField({
    super.key,
    required MentionTextEditingController textEditingController,
    required bool hasText,
    required this.focusNode,
    this.hasMediaAttached = false,
    this.targetMediaType = AiTargetMediaType.none,
    this.imageBytesProvider,
  }) : _textEditingController = textEditingController,
       _hasText = hasText;

  @override
  Widget build(BuildContext context) {
    final atLimit = _textEditingController.text.length >= 140;

    return MentionAwareTextField(
      controller: _textEditingController,
      focusNode: focusNode,
      enabled: true,
      hintText: "What's on your head?",
      style: const TextStyle(fontSize: 18),
      hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
        color: Theme.of(
          context,
        ).textTheme.titleSmall!.color?.withValues(alpha: 0.35),
        fontSize: 19,
        fontWeight: FontWeight.w400,
      ),
      minLines: 1,
      maxLines: null,
      maxLength: 250,
      counterText: _hasText ? null : '',
      counterStyle: TextStyle(
        color: atLimit ? Colors.red : null,
        fontWeight: atLimit ? FontWeight.bold : null,
      ),
      filled: false,
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      trailingIcon: AiActionIcon(
        controller: _textEditingController,
        surface: AiSurfaceType.post,
        generationAction: AiActionType.autocompleteCaption,
        actionContext: AiActionContext.postCreation,
        hasMediaAttached: hasMediaAttached,
        targetMediaType: targetMediaType,
        imageBytesProvider: imageBytesProvider,
      ),
    );
  }
}
