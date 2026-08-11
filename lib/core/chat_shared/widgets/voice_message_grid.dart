import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../features/single_chats/widgets/voice_message_bubble_widget.dart';
import '../../supabase/supabase_provider.dart';
import '../helpers/media_action_helper.dart' hide ShowInChatCallback;
import '../models/shared_media_item.dart';
import '../views/shared_media_view.dart';
import 'sectioned_media_list.dart';
import 'shared_media_action_menu.dart';

class VoiceMessageGrid extends StatelessWidget {
  final List<SharedMediaItem> items;
  final ShowInChatCallback? onShowInChat;
  const VoiceMessageGrid({super.key, required this.items, this.onShowInChat});

  @override
  Widget build(BuildContext context) {
    return SectionedMediaList(
      items: items,
      tileBuilder: (context, item) {
        final isMe = item.senderId == SupabaseProvider.id;

        return GestureDetector(
          onTap:
              () => MediaActionHelper.openFullScreenMedia(context, items, item),
          onLongPressStart:
              (details) => showSharedMediaActionMenu(
                context: context,
                globalPosition: details.globalPosition,
                isMe: isMe,
                onShowInChat:
                    () => MediaActionHelper.handleShowInChat(
                      context,
                      item,
                      onShowInChat,
                    ),
                onConfirmedDelete:
                    () => MediaActionHelper.handleDelete(
                      context,
                      item,
                      forEveryone: isMe,
                    ),
                onOpen:
                    () => MediaActionHelper.openFullScreenMedia(
                      context,
                      items,
                      item,
                    ),
                openLabel: 'Open voice message',
                openIcon: Icons.mic_none_rounded,
              ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                GestureDetector(
                  onTap:
                      () => MediaActionHelper.openFullScreenMedia(
                        context,
                        items,
                        item,
                      ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.12),
                    backgroundImage:
                        (item.senderAvatar != null &&
                                item.senderAvatar!.isNotEmpty)
                            ? CachedNetworkImageProvider(item.senderAvatar!)
                            : null,
                    child:
                        (item.senderAvatar == null ||
                                item.senderAvatar!.isEmpty)
                            ? Text(
                              item.senderName.isNotEmpty
                                  ? item.senderName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 13,
                              ),
                            )
                            : null,
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap:
                            () => MediaActionHelper.openFullScreenMedia(
                              context,
                              items,
                              item,
                            ),
                        child: Text(
                          item.senderName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const Gap(2),
                      VoiceMessageBubbleWidget(
                        voiceUrl: item.voiceUrl ?? '',
                        isMe: false,
                        timestamp: item.createdAt,
                        isUploading: false,
                        initialDurationSeconds: item.durationSeconds,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
