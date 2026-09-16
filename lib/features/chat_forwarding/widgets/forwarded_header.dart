import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/widgets/app_avatar.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../ai_chat/helpers/ai_model_iconography.dart';
import '../../single_chats/models/chat_user_model.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../models/forwardable_message.dart';

class ForwardedHeader extends StatefulWidget {
  final String originalSenderId;
  final String name;
  final String? avatarUrl;
  final bool onColoredBubble;

  const ForwardedHeader({
    super.key,
    required this.originalSenderId,
    required this.name,
    this.avatarUrl,
    required this.onColoredBubble,
  });

  @override
  State<ForwardedHeader> createState() => _ForwardedHeaderState();
}

class _ForwardedHeaderState extends State<ForwardedHeader> {
  late TapGestureRecognizer _nameTapRecognizer;
  TapGestureRecognizer? _aiNameTapRecognizer;
  bool get _isAi => widget.originalSenderId == ForwardableMessage.aiSenderId;
  @override
  void initState() {
    super.initState();
    _nameTapRecognizer = TapGestureRecognizer()..onTap = _onNameTap;
    _aiNameTapRecognizer = TapGestureRecognizer()..onTap = _openAiChat;
  }

  @override
  void dispose() {
    _nameTapRecognizer.dispose();
    _aiNameTapRecognizer?.dispose();
    super.dispose();
  }

  void _openAiChat() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.aiChatViewRoute);
  }

  void _onAvatarTap() {
    if (_isAi) return; // no profile to show for Syncra

    final currentUserId = SupabaseProvider.id;
    final isOriginalSenderMe = widget.originalSenderId == currentUserId;

    if (isOriginalSenderMe) {
      _openMyAvatar();
    } else {
      _showUserPreview();
    }
  }

  void _onNameTap() {
    if (_isAi) return; // no profile to show for Syncra

    final currentUserId = SupabaseProvider.id;
    final isOriginalSenderMe = widget.originalSenderId == currentUserId;

    if (isOriginalSenderMe) {
      try {
        final navController = context.read<HomeCubit>().navController;
        if (navController != null) {
          navController.jumpToTab(3);
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }
      } catch (e) {
        debugPrint('[ForwardedHeader] failed to navigate to original chat: $e');
      }
    }

    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.profileViewRoute, arguments: widget.originalSenderId);
  }

  void _openMyAvatar() {
    final url =
        widget.avatarUrl?.isNotEmpty == true
            ? widget.avatarUrl!
            : AppImages.defaultUserImg;

    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.fullScreenImageViewRoute,
      arguments: {
        'url': url,
        'tag': widget.originalSenderId,
        'isAsset': widget.avatarUrl == null || widget.avatarUrl!.isEmpty,
      },
    );
  }

  void _showUserPreview() {
    final user = ChatUserModel(
      id: widget.originalSenderId,
      name: widget.name,
      imageUrl: widget.avatarUrl,
    );

    showDialog(
      context: context,
      builder: (_) => UserPreviewDialog(user: user, showContactOptions: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bubbleIsDark =
        ThemeData.estimateBrightnessForColor(theme.primaryColor) ==
        Brightness.dark;

    final labelColor =
        widget.onColoredBubble
            ? (bubbleIsDark
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.black.withValues(alpha: 0.75))
            : theme.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 1),
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: TextStyle(fontSize: 12.5, color: labelColor),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.shortcut_rounded,
                  size: 14,
                  color: labelColor,
                ),
              ),
            ),
            const TextSpan(
              text: 'Forwarded from ',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child:
                    _isAi
                        ? GestureDetector(
                          onTap: _openAiChat,
                          behavior: HitTestBehavior.opaque,
                          child: _AiAvatar(modelName: widget.name),
                        )
                        : AppAvatar(
                          imageUrl: widget.avatarUrl,
                          size: 15,
                          onTap: _onAvatarTap,
                        ),
              ),
            ),
            TextSpan(
              text: widget.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
              recognizer: _isAi ? _aiNameTapRecognizer : _nameTapRecognizer,
            ),
          ],
        ),
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  final String? modelName;
  const _AiAvatar({this.modelName});

  @override
  Widget build(BuildContext context) {
    final nameLower = (modelName ?? '').toLowerCase();
    final brand =
        nameLower.contains('llama') || nameLower.contains('groq')
            ? AiModelBrand.groq
            : (nameLower.contains('openrouter')
                ? AiModelBrand.openRouter
                : AiModelBrand.gemini);

    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.32),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: AiModelIconography.buildBrandIcon(
          brand,
          size: 13.5,
          useOriginalColors: true,
        ),
      ),
    );
  }
}
