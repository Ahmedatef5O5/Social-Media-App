import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import '../../../core/chat_shared/cubits/conversation_selection_cubit/conversation_selection_cubit.dart';
import '../../../core/chat_shared/helpers/message_reaction_preview_helper.dart';
import '../../../core/chat_shared/models/conversation_ref.dart';
import '../../../core/chat_shared/widgets/recording_indicator_widget.dart';
import '../../../core/design/tokens/typography.dart';
import '../../../core/helpers/bidi_text_helper.dart';
import '../../../core/helpers/emoji_helper.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/animated_activity_text.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../models/chat_user_model.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';

class ChatItemTile extends StatelessWidget {
  final ChatUserModel user;
  final bool isPinned;
  final bool isFavorite;
  final bool isMuted;
  final bool enableHero;

  const ChatItemTile({
    super.key,
    required this.user,
    this.isPinned = false,
    this.isFavorite = false,
    this.isMuted = false,
    this.enableHero = true,
  });

  bool get _isSystemEventPreview =>
      user.lastMessageType == 'block_event' ||
      user.lastMessageType == 'unblock_event' ||
      user.lastMessageType == 'message_react';

  @override
  Widget build(BuildContext context) {
    final ref = ConversationRef(type: ConversationType.single, id: user.id);

    return BlocBuilder<ConversationSelectionCubit, ConversationSelectionState>(
      builder: (context, selection) {
        final isSelecting = selection.isSelecting;
        final isSelected = selection.isSelected(ref);
        final primary = Theme.of(context).primaryColor;

        return Material(
          color:
              isSelected ? primary.withValues(alpha: 0.08) : Colors.transparent,
          child: InkWell(
            onLongPress:
                () => context.read<ConversationSelectionCubit>().toggle(ref),
            onTap: () {
              if (isSelecting) {
                context.read<ConversationSelectionCubit>().toggle(ref);
                return;
              }
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed(AppRoutes.chatDetailsViewRoute, arguments: user);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildUserAvatar(context, isSelecting, isSelected, primary),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: _buildUserName(context)),
                            const Gap(8),
                            if (user.lastMessageTime != null)
                              _buildTimeText(context, primary),
                          ],
                        ),
                        const Gap(4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _buildLastMessage(context)),
                            const Gap(8),
                            _buildIconsSection(context, primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeText(BuildContext context, Color primary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnread = user.unreadCount > 0;
    return Text(
      FormattedDate.getChatTime(user.lastMessageTime!, isChatList: true),
      style: TextStyle(
        color: isUnread ? primary : (isDark ? Colors.white38 : Colors.black38),
        fontSize: 11,
        fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
      ),
    );
  }

  Widget _buildIconsSection(BuildContext context, Color primary) {
    final hasStatusRow =
        isFavorite || isPinned || isMuted || user.unreadCount > 0;

    if (!hasStatusRow) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isFavorite) ...[
          Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade600),
          const Gap(4),
        ],
        if (isPinned) ...[
          const Icon(Icons.push_pin_rounded, size: 15, color: Colors.grey),
          const Gap(4),
        ],
        if (isMuted) ...[
          const FaIcon(
            FontAwesomeIcons.bellSlash,
            size: 12,
            color: Colors.grey,
          ),
          if (user.unreadCount > 0) const Gap(4),
        ],
        if (user.unreadCount > 0)
          Container(
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                user.unreadCount > 99 ? '99+' : '${user.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _extractCleanFileName(String? raw) {
    if (raw == null ||
        raw.trim().isEmpty ||
        raw.trim().toLowerCase() == 'file') {
      return AppL10n.current.file;
    }
    String clean = raw.trim();
    if (clean.startsWith('📄 ')) {
      clean = clean.substring(3).trim();
    }
    if (clean.contains(' • ')) {
      clean = clean.split(' • ').first.trim();
    }
    return clean;
  }

  String _getNormalMessageText() {
    switch (user.lastMessageType) {
      case 'image':
        return AppL10n.current.photo2;
      case 'video':
        return AppL10n.current.video2;
      case 'voice':
        return AppL10n.current.voiceMessage;
      case 'gif':
        return AppL10n.current.gif;
      case 'sticker':
        return AppL10n.current.sticker2;
      case 'file':
      case 'document':
        final fileName = _extractCleanFileName(user.lastMessage);
        return '📄 $fileName';
      case 'block_event':
        return user.lastMessageIsMe
            ? AppL10n.current.youBlocked2(user.name)
            : AppL10n.current.blockedYou2(user.name);
      case 'unblock_event':
        return user.lastMessageIsMe
            ? AppL10n.current.youUnblocked2(user.name)
            : AppL10n.current.unblockedYou2(user.name);
      default:
        return (user.lastMessage == null || user.lastMessage!.isEmpty)
            ? AppL10n.current.noMessagesYet2
            : user.lastMessage!;
    }
  }

  Widget _buildMessagePreview(BuildContext context) {
    final bool isUnread = user.unreadCount > 0;
    final textStyle =
        (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
          fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
          fontSize: 13,
          fontFamily: null,
          fontFamilyFallback: AppTypography.fontFallback,
          color:
              isUnread
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.grey.shade600,
        );

    if (user.lastMessageType == 'call') {
      Map<String, dynamic> callData = {};
      try {
        if (user.lastMessage != null) {
          callData = jsonDecode(user.lastMessage!) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('[ChatItemTile] failed to decode last message payload: $e');
      }

      final status = callData['status'] as String? ?? 'ended';
      final callType = callData['call_type'] as String? ?? 'audio';

      final bool isAudio = callType == 'audio';
      final bool isMissed = status == 'rejected' || status == 'missed';

      final IconData icon =
          isMissed
              ? (isAudio ? Icons.call_missed : Icons.missed_video_call)
              : (isAudio ? Icons.call : Icons.videocam);

      final Color iconColor =
          isMissed ? Colors.redAccent : Colors.grey.shade600;
      final String label =
          isMissed
              ? (isAudio
                  ? context.l10n.missedVoiceCall
                  : context.l10n.missedVideoCall)
              : (isAudio ? context.l10n.voiceCall : context.l10n.videoCall);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const Gap(4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle.copyWith(
                color: isMissed ? Colors.redAccent : textStyle.color,
              ),
            ),
          ),
        ],
      );
    }

    if (user.lastMessageType == 'file' || user.lastMessageType == 'document') {
      return Align(
        alignment: Alignment.centerLeft,
        child: MessageReactionPreviewHelper.buildDirectionalFilePreview(
          fileName: user.lastMessage ?? context.l10n.file,
          style: textStyle,
          defaultIconColor: Colors.grey.shade600,
          iconSize: 14,
        ),
      );
    }

    final effectiveStyle = textStyle.copyWith(
      fontFamily: null,
      fontFamilyFallback: AppTypography.fontFallback,
    );

    if (user.lastMessageType == 'message_react') {
      return MessageReactionPreviewHelper.buildReactionPreviewWidget(
        rawPreview: EmojiHelper.normalize(_getNormalMessageText()),
        style: effectiveStyle,
        defaultIconColor: Colors.grey.shade600,
        iconSize: 13,
      );
    }

    final normalText = EmojiHelper.normalize(_getNormalMessageText());
    final direction = BidiTextHelper.detectDirection(normalText);

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Text(
      normalText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: isRtl ? TextDirection.rtl : direction,
      textAlign: isRtl ? TextAlign.right : TextAlign.left,
      style: effectiveStyle,
    );
  }

  Widget _buildLastMessage(BuildContext context) {
    if (user.isRecording) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const RecordingIndicatorWidget(size: 14),
          const SizedBox(width: 6),
          AnimatedActivityText(
            text: context.l10n.recordingAudio2,
            style: TextStyle(color: Colors.red.shade600, fontSize: 14),
          ),
        ],
      );
    }
    if (user.isTyping == true) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedActivityText(
            text: context.l10n.typing,
            forceAnimate: true,
            style: const TextStyle(color: Colors.green, fontSize: 14),
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (user.lastMessageIsMe && !_isSystemEventPreview) ...[
            Icon(
              user.lastMessageIsRead ? Icons.done_all : Icons.done,
              size: 16,
              color: user.lastMessageIsRead ? Colors.blue : Colors.grey,
            ),
            const Gap(4),
          ],
          Expanded(child: _buildMessagePreview(context)),
        ],
      );
    }
  }

  // ==================== AFTER ====================
  Text _buildUserName(BuildContext context) {
    final isDeletedAccount =
        user.isDeleted || user.name.trim().toLowerCase() == 'deleted account';
    final displayName =
        isDeletedAccount ? context.l10n.deletedAccount : user.name;

    return Text(
      displayName,
      style: Theme.of(context).textTheme.titleSmall!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildUserAvatar(
    BuildContext context,
    bool isSelecting,
    bool isSelected,
    Color primary,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PresenceAvatarWidget(
          userId: user.id,
          avatarSize: 52,
          showDot: true,
          showBorder: true,

          child: AppAvatar(
            imageUrl: user.imageUrl,
            size: 52,
            heroTag: enableHero ? user.id : null,
            onTap:
                isSelecting
                    ? null
                    : () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => UserPreviewDialog(
                              user: user,
                              showContactOptions: true,
                            ),
                      );
                    },
          ),
        ),
        if (isSelecting)
          Positioned(
            right: -2,
            bottom: -2,
            child: _ChatSelectionBadge(
              isSelected: isSelected,
              primary: primary,
            ),
          ),
      ],
    );
  }
}

class _ChatSelectionBadge extends StatelessWidget {
  final bool isSelected;
  final Color primary;
  const _ChatSelectionBadge({required this.isSelected, required this.primary});

  @override
  Widget build(BuildContext context) {
    final ringColor = Theme.of(context).scaffoldBackgroundColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child:
            isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                : null,
      ),
    );
  }
}
