import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/group_chats/helpers/group_preview_dialog.dart';
import '../../../core/chat_shared/cubits/conversation_selection_cubit/conversation_selection_cubit.dart';
import '../../../core/chat_shared/models/conversation_ref.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../helpers/last_message_group_preview.dart';
import '../models/group_model.dart';
import 'presence_animated_subtitle.dart';

class GroupTileItem extends StatelessWidget {
  final GroupModel group;
  final bool isPinned;
  final bool isFavorite;
  const GroupTileItem({
    super.key,
    required this.group,
    required this.isPinned,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseProvider.id;
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAvatar = group.avatarUrl != null && group.avatarUrl!.isNotEmpty;
    final highlightUnreadMessage =
        group.unreadCount > 0 && group.lastMessageSenderId != currentUserId;
    final ref = ConversationRef(type: ConversationType.group, id: group.id);

    return BlocBuilder<ConversationSelectionCubit, ConversationSelectionState>(
      builder: (context, selection) {
        final isSelecting = selection.isSelecting;
        final isSelected = selection.isSelected(ref);

        return Material(
          color:
              isSelected ? primary.withValues(alpha: 0.08) : Colors.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap:
                      (!isSelecting && hasAvatar)
                          ? () => showDialog(
                            context: context,
                            barrierColor: Colors.black54,
                            builder: (_) => GroupPreviewDialog(group: group),
                          )
                          : null,
                  child: ClipOval(
                    child: Container(
                      width: 52,
                      height: 52,
                      color: primary.withValues(alpha: 0.12),
                      child:
                          hasAvatar
                              ? CachedCloudinaryImage(
                                secureUrl: group.avatarUrl!,
                                fit: BoxFit.cover,
                                isAvatar: true,
                              )
                              : Center(
                                child: Text(
                                  group.name.isNotEmpty
                                      ? group.name[0].toUpperCase()
                                      : 'G',
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                    ),
                  ),
                ),
                if (isSelecting)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: _SelectionBadge(
                      isSelected: isSelected,
                      primary: primary,
                    ),
                  ),
              ],
            ),
            title: Text(
              group.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: PresenceAnimatedSubtitle(
                    presence: group.presence,

                    activeStyle: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          highlightUnreadMessage
                              ? FontWeight.w500
                              : FontWeight.w400,
                      color: Colors.green.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    fallback:
                        group.lastMessage != null
                            ? Text(
                              buildGroupLastMessagePreview(
                                group: group,
                                currentUserId: currentUserId,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    highlightUnreadMessage
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onSurface
                                        : Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight:
                                    highlightUnreadMessage
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                              ),
                            )
                            : Text(
                              'Tap to open group chat',
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontSize: 13,
                              ),
                            ),
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (group.lastMessageAt != null)
                  Text(
                    FormattedDate.getMessageTime(group.lastMessageAt!),
                    style: TextStyle(
                      color:
                          group.unreadCount > 0
                              ? primary
                              : (isDark ? Colors.white38 : Colors.black38),
                      fontSize: 11,
                    ),
                  ),
                if (isFavorite ||
                    isPinned ||
                    group.isMuted ||
                    group.unreadCount > 0) ...[
                  const Gap(4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isFavorite) ...[
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber.shade600,
                        ),
                        const Gap(4),
                      ],
                      if (isPinned) ...[
                        Icon(
                          Icons.push_pin_rounded,
                          size: 15,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const Gap(4),
                      ],
                      if (group.isMuted) ...[
                        FaIcon(
                          FontAwesomeIcons.bellSlash,
                          size: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        if (group.unreadCount > 0) const Gap(4),
                      ],
                      if (group.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(5),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: primary,
                            shape:
                                group.unreadCount > 99
                                    ? BoxShape.rectangle
                                    : BoxShape.circle,
                            borderRadius:
                                group.unreadCount > 99
                                    ? BorderRadius.circular(10)
                                    : null,
                          ),
                          child: Text(
                            group.unreadCount > 99
                                ? '99+'
                                : '${group.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
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
              ).pushNamed(AppRoutes.groupChatRoute, arguments: group);
            },
          ),
        );
      },
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  final bool isSelected;
  final Color primary;
  const _SelectionBadge({required this.isSelected, required this.primary});

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
