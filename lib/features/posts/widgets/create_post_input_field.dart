import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/design/tokens/typography.dart';
import 'package:social_media_app/core/mentions/mentions.dart';
import '../../ai_assistant/entities/ai_action_type.dart';
import '../../ai_assistant/entities/ai_request_context.dart';
import '../../ai_assistant/widgets/ai_action_icon.dart';
import '../models/post_theme_model.dart';
import 'themed_post_canvas.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class CreatePostInputField extends StatelessWidget {
  final MentionTextEditingController _textEditingController;
  final bool _hasText;
  final FocusNode focusNode;
  final bool hasMediaAttached;
  final AiTargetMediaType targetMediaType;
  final Future<Uint8List?> Function()? imageBytesProvider;
  final List<String>? restrictSuggestionsToUserIds;
  final PostBackgroundThemeModel? theme;

  const CreatePostInputField({
    super.key,
    required MentionTextEditingController textEditingController,
    required bool hasText,
    required this.focusNode,
    this.hasMediaAttached = false,
    this.targetMediaType = AiTargetMediaType.none,
    this.imageBytesProvider,
    this.restrictSuggestionsToUserIds,
    this.theme,
  }) : _textEditingController = textEditingController,
       _hasText = hasText;

  @override
  Widget build(BuildContext context) {
    final atLimit = _textEditingController.text.length >= 1850;
    final theme = Theme.of(context);
    final postTheme = this.theme;

    final TextStyle textStyle =
        postTheme == null
            ? (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
              fontSize: 18,
              textBaseline: TextBaseline.alphabetic,
              fontFamily: null,
              fontFamilyFallback: AppTypography.fontFallback,
            )
            : ThemedPostCanvas.textStyleFor(
              postTheme,
              fontSize: ThemedPostCanvas.fontSizeFor(
                _textEditingController.text,
              ),
              base: const TextStyle(
                fontFamily: null,
                fontFamilyFallback: AppTypography.fontFallback,
              ),
            );

    return MentionAwareTextField(
      controller: _textEditingController,
      focusNode: focusNode,
      enabled: true,
      restrictSuggestionsToUserIds: restrictSuggestionsToUserIds,
      hintText: context.l10n.whatsOnYourHead,
      textAlign: postTheme == null ? TextAlign.start : TextAlign.center,
      style: textStyle,
      hintStyle:
          postTheme == null
              ? theme.textTheme.titleSmall!.copyWith(
                color: theme.textTheme.titleSmall!.color?.withValues(
                  alpha: 0.35,
                ),
                fontSize: 19,
                fontWeight: FontWeight.w400,
              )
              : textStyle.copyWith(
                color: postTheme.textColor.withValues(alpha: 0.6),
                shadows: null,
              ),
      minLines: 1,
      maxLines: null,
      maxLength: 2000,
      counterText: _hasText ? null : '',
      counterStyle: TextStyle(
        color:
            atLimit
                ? (postTheme == null ? Colors.red : Colors.amberAccent)
                : postTheme?.textColor.withValues(alpha: 0.7),
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
