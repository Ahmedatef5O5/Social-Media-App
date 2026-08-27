import 'package:flutter/material.dart';
import 'package:social_media_app/core/mentions/mentions.dart';
import '../../../core/design/tokens/typography.dart';
import '../../../core/themes/app_colors.dart';
import '../../ai_assistant/entities/ai_action_type.dart';
import '../../ai_assistant/entities/ai_request_context.dart';
import '../../ai_assistant/widgets/ai_action_icon.dart';

class StoryTextEditor extends StatelessWidget {
  final MentionTextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;

  const StoryTextEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hasText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SingleChildScrollView(
                child: MentionAwareTextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: true,
                  hintText: 'Write your thought with others',
                  textAlign: TextAlign.center,
                  minLines: 1,
                  maxLines: null,
                  maxLength: 280,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 32,
                    fontFamilyFallback: AppTypography.emojiFontFallback,
                  ),
                  hintStyle: const TextStyle(
                    color: AppColors.white70,
                    fontSize: 32,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  counterText: hasText ? null : '',
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: AiActionIcon(
                  controller: controller,
                  surface: AiSurfaceType.story,
                  generationAction: AiActionType.autocompleteCaption,
                  actionContext: AiActionContext.storyCreation,
                  hasMediaAttached: false,
                  targetMediaType: AiTargetMediaType.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
