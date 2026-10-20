import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/chat_shared/widgets/reply_preview_thumbnail.dart';
import '../models/groupe_message_model.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class GroupReplyBubblePreview extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;
  final String currentUserId;

  const GroupReplyBubblePreview({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
  });

  static const double _thumbnailSize = 40;

  @override
  Widget build(BuildContext context) {
    final hasText =
        message.replyToText != null && message.replyToText!.isNotEmpty;

    final hasThumbnail =
        message.replyToMediaUrl != null &&
        (message.replyToMessageType == 'image' ||
            message.replyToMessageType == 'video' ||
            message.replyToMessageType == 'gif' ||
            message.replyToMessageType == 'sticker');

    if (!hasText && !hasThumbnail && message.replyToMessageType == null) {
      return const SizedBox.shrink();
    }

    final senderName =
        message.replyToSenderId == currentUserId
            ? context.l10n.you
            : (message.replyToSenderName ?? context.l10n.unknown);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      child: IntrinsicHeight(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: isMe ? Colors.white60 : Theme.of(context).primaryColor,
              ),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isMe
                            ? Colors.white.withValues(alpha: 0.2)
                            : Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.08),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              senderName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color:
                                    isMe
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _previewText(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isMe ? Colors.white70 : AppColors.greyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasThumbnail) ...[
                        const SizedBox(width: 8),
                        _buildThumbnail(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _previewText() {
    switch (message.replyToMessageType) {
      case 'image':
        return AppL10n.current.photo2;
      case 'video':
        return AppL10n.current.video2;
      case 'gif':
        return AppL10n.current.gif;
      case 'sticker':
        return AppL10n.current.sticker2;
      case 'voice':
        return AppL10n.current.voiceMessage;
      default:
        final t = message.replyToText ?? '';
        return t.length > 60 ? '${t.substring(0, 60)}...' : t;
    }
  }

  Widget _buildThumbnail() {
    return ReplyPreviewThumbnail(
      messageType: message.replyToMessageType!,
      mediaUrl: message.replyToMediaUrl,
      size: _thumbnailSize,
    );
  }
}
