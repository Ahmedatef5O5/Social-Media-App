import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../single_chats/models/chat_user_model.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';

class ForwardedHeader extends StatefulWidget {
  final String originalSenderId;
  final String name;
  final String? avatarUrl;
  final bool isMe;

  const ForwardedHeader({
    super.key,
    required this.originalSenderId,
    required this.name,
    this.avatarUrl,
    required this.isMe,
  });

  @override
  State<ForwardedHeader> createState() => _ForwardedHeaderState();
}

class _ForwardedHeaderState extends State<ForwardedHeader> {
  late TapGestureRecognizer _nameTapRecognizer;

  @override
  void initState() {
    super.initState();
    _nameTapRecognizer = TapGestureRecognizer()..onTap = _onNameTap;
  }

  @override
  void dispose() {
    _nameTapRecognizer.dispose();
    super.dispose();
  }

  void _onAvatarTap() {
    final currentUserId = SupabaseProvider.id;
    final isOriginalSenderMe = widget.originalSenderId == currentUserId;

    if (isOriginalSenderMe) {
      _openMyAvatar();
    } else {
      _showUserPreview();
    }
  }

  void _onNameTap() {
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
      } catch (_) {}
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
    final labelColor =
        widget.isMe
            ? Colors.white.withValues(alpha: 0.9)
            : Theme.of(context).primaryColor;
    final hasAvatar = widget.avatarUrl?.isNotEmpty == true;
    final ImageProvider avatarImageProvider =
        hasAvatar
            ? NetworkImage(widget.avatarUrl!) as ImageProvider
            : const AssetImage(AppImages.defaultUserImg);

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
              child: GestureDetector(
                onTap: _onAvatarTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: CircleAvatar(
                    radius: 7.5,
                    backgroundImage: avatarImageProvider,
                  ),
                ),
              ),
            ),
            TextSpan(
              text: widget.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
              recognizer: _nameTapRecognizer,
            ),
          ],
        ),
      ),
    );
  }
}
