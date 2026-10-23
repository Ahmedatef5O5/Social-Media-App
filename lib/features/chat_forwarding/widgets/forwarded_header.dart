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
import 'package:social_media_app/core/localization/l10n_extension.dart';

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
  bool get _isAi => widget.originalSenderId == ForwardableMessage.aiSenderId;

  void _openAiChat() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.aiChatViewRoute);
  }

  void _onAvatarTap() {
    if (_isAi) return;

    final currentUserId = SupabaseProvider.id;
    final isOriginalSenderMe = widget.originalSenderId == currentUserId;

    if (isOriginalSenderMe) {
      _openMyAvatar();
    } else {
      _showUserPreview();
    }
  }

  void _onNameTap() {
    if (_isAi) return;

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
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final bubbleIsDark =
        ThemeData.estimateBrightnessForColor(theme.primaryColor) ==
        Brightness.dark;

    final labelColor =
        widget.onColoredBubble
            ? (bubbleIsDark
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.black.withValues(alpha: 0.75))
            : theme.primaryColor;

    final avatarWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child:
          _isAi
              ? GestureDetector(
                onTap: _openAiChat,
                behavior: HitTestBehavior.opaque,
                child: _AiAvatar(
                  modelName: widget.name,
                  onColoredBubble: widget.onColoredBubble,
                ),
              )
              : AppAvatar(
                imageUrl: widget.avatarUrl,
                size: 15,
                onTap: _onAvatarTap,
              ),
    );

    final iconWidget = Padding(
      padding: EdgeInsets.only(left: isRtl ? 4 : 0, right: isRtl ? 0 : 4),
      child: Transform.flip(
        flipX: isRtl,
        child: Icon(Icons.shortcut_rounded, size: 14, color: labelColor),
      ),
    );

    final nameWidget = GestureDetector(
      onTap: _isAi ? _openAiChat : _onNameTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Text(
          widget.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            color: labelColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    final textWidget = Text(
      context.l10n.forwardedFrom,
      style: TextStyle(
        fontSize: 12.5,
        color: labelColor,
        fontWeight: FontWeight.w500,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children:
            isRtl
                ? [
                  iconWidget,
                  textWidget,
                  const SizedBox(width: 4),
                  nameWidget,
                  const SizedBox(width: 4),
                  avatarWidget,
                ]
                : [
                  iconWidget,
                  textWidget,
                  avatarWidget,
                  const SizedBox(width: 4),
                  nameWidget,
                ],
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  final String? modelName;
  final bool onColoredBubble;

  const _AiAvatar({this.modelName, this.onColoredBubble = false});

  @override
  Widget build(BuildContext context) {
    final nameLower = (modelName ?? '').toLowerCase();
    final brand =
        nameLower.contains('llama') || nameLower.contains('groq')
            ? AiModelBrand.groq
            : (nameLower.contains('openrouter')
                ? AiModelBrand.openRouter
                : AiModelBrand.gemini);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color:
              onColoredBubble
                  ? Colors.white.withValues(alpha: 0.65)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.08)),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: onColoredBubble ? 0.16 : 0.06,
            ),
            blurRadius: 2.5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: AiModelIconography.buildBrandIcon(
          brand,
          size: 13,
          useOriginalColors: true,
        ),
      ),
    );
  }
}
