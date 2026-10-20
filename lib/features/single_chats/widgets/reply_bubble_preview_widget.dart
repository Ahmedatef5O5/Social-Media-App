import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/chat_shared/widgets/reply_preview_thumbnail.dart';
import '../models/message_model.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class ReplyBubblePreview extends StatelessWidget {
  final MessageModel message;
  final String? replyText;
  final String? replyType;
  final bool isMe;
  final String currentUserId;
  final String receiverName;

  const ReplyBubblePreview({
    super.key,
    required this.replyText,
    required this.replyType,
    required this.isMe,
    required this.message,
    required this.currentUserId,
    required this.receiverName,
  });

  static const double _thumbnailSize = 40;

  String _fallbackLabel() {
    switch (replyType) {
      case 'image':
        return AppL10n.current.photo2;
      case 'video':
        return AppL10n.current.video2;
      case 'voice':
        return AppL10n.current.voiceMessage;
      case 'file':
        return '📄 ${message.fileName ?? AppL10n.current.file}';
      case 'gif':
        return AppL10n.current.gif;
      case 'sticker':
        return AppL10n.current.sticker2;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String senderName =
        message.replyToSenderId == currentUserId
            ? context.l10n.you
            : receiverName;

    final String displayText =
        (replyText != null && replyText!.isNotEmpty)
            ? replyText!
            : _fallbackLabel();

    if (displayText.isEmpty && message.replyToMediaUrl == null) {
      return const SizedBox.shrink();
    }

    final bool hasThumbnail =
        message.replyToMediaUrl != null &&
        (replyType == 'image' ||
            replyType == 'video' ||
            replyType == 'gif' ||
            replyType == 'sticker');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      child: IntrinsicHeight(
        child: ClipRRect(
          borderRadius: BorderRadiusDirectional.all(Radius.circular(8)),
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
                              displayText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isMe
                                        ? Color.alphaBlend(
                                          Colors.white70,
                                          Theme.of(context).primaryColor,
                                        )
                                        : AppColors.greyColor,
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

  Widget _buildThumbnail() {
    return ReplyPreviewThumbnail(
      messageType: replyType!,
      mediaUrl: message.replyToMediaUrl,
      size: _thumbnailSize,
    );
  }
}
