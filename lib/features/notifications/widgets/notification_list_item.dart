import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import '../../../core/chat_shared/helpers/message_reaction_preview_helper.dart';
import '../../../core/helpers/bidi_text_helper.dart';
import '../../../core/helpers/content_deep_link_navigator.dart';
import '../../../core/services/active_screen_tracker.dart';
import '../../../core/toast/app_toast.dart';
import '../../group_chats/cubits/group_list_cubit/group_list_cubit.dart';
import '../../group_chats/helpers/group_navigation.dart';
import '../../group_chats/models/group_model.dart';
import '../../group_chats/services/group_chat_services.dart';
import '../../posts/views/post_details_view.dart';
import '../../single_chats/cubits/chats_cubit/chats_cubit.dart';
import '../../single_chats/models/chat_user_model.dart';
import '../models/app_notification_model.dart';

class NotificationListItem extends StatelessWidget {
  final AppNotification notification;
  final bool isDark;
  final Color primary;
  final int index;
  final ValueChanged<String> onMarkAsRead;
  final ValueChanged<String> onDelete;
  final ValueChanged<AppNotification> onAcceptFriendRequest;
  final ValueChanged<AppNotification> onRejectFriendRequest;
  final ValueChanged<AppNotification> onFollowBack;
  final bool isFollowingBack;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.isDark,
    required this.primary,
    required this.index,
    required this.onMarkAsRead,
    required this.onDelete,
    required this.onAcceptFriendRequest,
    required this.onRejectFriendRequest,
    required this.onFollowBack,
    required this.isFollowingBack,
  });

  @override
  Widget build(BuildContext context) {
    final notif = notification;

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete
          HapticFeedback.mediumImpact();
          return true;
        } else {
          // Mark as read
          if (!notif.isRead) {
            HapticFeedback.lightImpact();
            onMarkAsRead(notif.id);
          }
          return false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete(notif.id);
        }
      },
      // ── Left swipe → Delete (red) ──
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.green.shade900.withValues(alpha: 0.5)
                  : Colors.green.shade50,
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Row(
          children: [
            Icon(
              Icons.done_all_rounded,
              color: Colors.green.shade500,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Mark read',
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.red.shade900.withValues(alpha: 0.4)
                  : Colors.red.shade50,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.red.shade500,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.delete_outline_rounded,
              color: Colors.red.shade500,
              size: 22,
            ),
          ],
        ),
      ),
      child: _buildNotificationItem(context, notif),
    );
  }

  Widget _buildNotificationItem(BuildContext context, AppNotification notif) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(notif.id),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + (index * 40).clamp(0, 300)),
      curve: Curves.easeOut,
      builder:
          (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - value)),
              child: child,
            ),
          ),
      child: InkWell(
        onTap: () {
          if (!notif.isRead) onMarkAsRead(notif.id);
          _handleNotificationTap(context, notif);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                notif.isRead
                    ? Colors.transparent
                    : (isDark
                        ? primary.withValues(alpha: 0.06)
                        : primary.withValues(alpha: 0.04)),
            border: Border(
              left:
                  notif.isRead
                      ? BorderSide.none
                      : BorderSide(color: primary, width: 3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotifAvatar(notif, primary, isDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  notif.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(notif.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark ? Colors.white30 : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    Builder(
                      builder: (context) {
                        String text = notif.displaySubtitle;
                        final textStyle = TextStyle(
                          fontSize: 13,
                          color:
                              isDark
                                  ? (notif.isRead
                                      ? Colors.white38
                                      : Colors.white60)
                                  : (notif.isRead
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade700),
                          height: 1.35,
                        );

                        if (text.contains('📄 ')) {
                          final parts = text.split('📄 ');
                          final prefix = parts[0];
                          final fileInfo = parts.sublist(1).join('📄 ');

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (prefix.isNotEmpty)
                                Text(
                                  prefix,
                                  style: textStyle,
                                  textDirection: TextDirection.ltr,
                                ),
                              Flexible(
                                child:
                                    MessageReactionPreviewHelper.buildDirectionalFilePreview(
                                      fileName: fileInfo,
                                      style: textStyle.copyWith(
                                        fontFamily: null,
                                      ),
                                      defaultIconColor:
                                          isDark
                                              ? Colors.white60
                                              : Colors.grey.shade600,
                                      iconSize: 13,
                                      keepCaption: true,
                                    ),
                              ),
                            ],
                          );
                        }
                        return Text(
                          text,
                          textDirection: BidiTextHelper.detectDirection(text),
                          style: textStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),

                    if (notif.type == NotificationType.friendRequest) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                side: BorderSide(
                                  color:
                                      isDark
                                          ? Colors.white24
                                          : Colors.grey.shade300,
                                ),
                              ),
                              onPressed: () => onRejectFriendRequest(notif),
                              child: const Text(
                                'Reject',
                                style: TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () => onAcceptFriendRequest(notif),
                              child: const Text(
                                'Accept',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (notif.type == NotificationType.follow) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isFollowingBack
                                      ? Colors.grey.shade300
                                      : primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            onPressed:
                                isFollowingBack
                                    ? null
                                    : () => onFollowBack(notif),
                            child: Text(
                              isFollowingBack ? 'Following' : 'Follow Back',
                              style: TextStyle(
                                fontSize: 12.5,
                                color:
                                    isFollowingBack
                                        ? Colors.black54
                                        : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!notif.isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifAvatar(AppNotification notif, Color primary, bool isDark) {
    final imageUrl = notif.senderImageUrl ?? '';
    final bool hasImage = imageUrl.isNotEmpty && imageUrl.startsWith('http');

    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: primary.withValues(alpha: 0.1),
          backgroundImage:
              hasImage
                  ? CachedNetworkImageProvider(imageUrl)
                  : const AssetImage(AppImages.defaultUserImg) as ImageProvider,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: _colorForType(notif.type, isDark),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                width: 1.5,
              ),
            ),
            child: Icon(
              _iconForType(notif.type),
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.chat:
        return Icons.chat_bubble_rounded;
      case NotificationType.call:
        return Icons.call_rounded;
      case NotificationType.groupMessage:
        return Icons.group_rounded;
      case NotificationType.like:
        return Icons.favorite_rounded;
      case NotificationType.comment:
        return Icons.comment_rounded;
      case NotificationType.follow:
        return Icons.person_add_rounded;
      case NotificationType.friendRequest:
        return Icons.person_add_alt_1_rounded;
      case NotificationType.friendAccept:
        return Icons.how_to_reg_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(NotificationType type, bool isDark) {
    switch (type) {
      case NotificationType.chat:
        return Colors.blue;
      case NotificationType.call:
        return Colors.green;
      case NotificationType.groupMessage:
        return Colors.purple;
      case NotificationType.like:
        return Colors.red;
      case NotificationType.comment:
        return Colors.orange;
      case NotificationType.follow:
        return Colors.teal;
      case NotificationType.friendRequest:
        return Colors.indigo;
      case NotificationType.friendAccept:
        return Colors.green;
      case NotificationType.general:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    AppNotification notif,
  ) async {
    switch (notif.type) {
      case NotificationType.like:
        final postId = notif.referenceId;
        if (postId != null && postId.isNotEmpty) {
          final isCommentReaction =
              notif.rawType == 'comment_react' ||
              notif.body.toLowerCase().contains('comment');
          await ContentDeepLinkNavigator.openPost(
            postId,
            isCommentReaction
                ? PostDetailsActiveMode.comments
                : PostDetailsActiveMode.reactions,
            false,
          );
          return;
        }
        _openSenderProfile(context, notif.senderId);
        return;

      case NotificationType.comment:
        final postId = notif.referenceId;
        if (postId != null && postId.isNotEmpty) {
          await ContentDeepLinkNavigator.openPost(
            postId,
            PostDetailsActiveMode.comments,
            false,
          );
          return;
        }
        _openSenderProfile(context, notif.senderId);
        return;

      case NotificationType.groupMessage:
        final groupId = notif.referenceId;
        if (groupId != null && groupId.isNotEmpty) {
          await _openGroupChatFromNotification(context, groupId);
          return;
        }
        _openSenderProfile(context, notif.senderId);
        return;

      case NotificationType.chat:
        _openSingleChatFromNotification(context, notif);
        return;

      case NotificationType.call:
        final refId = notif.referenceId;
        if (refId != null && refId.isNotEmpty) {
          final groupMatch = _findCachedGroup(context, refId);
          if (groupMatch != null) {
            await _openGroupChatFromNotification(context, refId);
            return;
          }
        }
        _openSingleChatFromNotification(context, notif);
        return;

      case NotificationType.follow:
      case NotificationType.friendRequest:
      case NotificationType.friendAccept:
      case NotificationType.general:
        if (notif.rawType == 'share' || notif.rawType == 'post_reshare') {
          final postId = notif.referenceId;
          if (postId != null && postId.isNotEmpty) {
            await ContentDeepLinkNavigator.openPost(
              postId,
              PostDetailsActiveMode.comments,
              false,
            );
            return;
          }
        }
        _openSenderProfile(context, notif.senderId);
        return;
    }
  }

  void _openSenderProfile(BuildContext context, String? senderId) {
    if (senderId == null || senderId.isEmpty) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.profileViewRoute, arguments: senderId);
  }

  void _openSingleChatFromNotification(
    BuildContext context,
    AppNotification notif,
  ) {
    final peerId = notif.senderId;
    if (peerId == null || peerId.isEmpty) return;

    if (ActiveScreenTracker.isViewingChatWith(peerId)) return;

    ChatUserModel? resolvedUser;
    try {
      final chatsCubit = context.read<ChatsCubit>();
      for (final chat in chatsCubit.cachedChats) {
        if (chat.id == peerId) {
          resolvedUser = chat.copyWith(
            name: notif.title.isNotEmpty ? notif.title : chat.name,
            imageUrl: notif.senderImageUrl ?? chat.imageUrl,
          );
          break;
        }
      }
    } catch (_) {}

    resolvedUser ??= ChatUserModel(
      id: peerId,
      name: notif.title.isNotEmpty ? notif.title : 'Unknown',
      imageUrl: notif.senderImageUrl,
    );

    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.chatDetailsViewRoute, arguments: resolvedUser);
  }

  GroupModel? _findCachedGroup(BuildContext context, String groupId) {
    try {
      final groupListCubit = context.read<GroupListCubit>();
      for (final g in groupListCubit.cachedGroupsChats) {
        if (g.id == groupId && g.isMember) {
          return g;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _openGroupChatFromNotification(
    BuildContext context,
    String groupId,
  ) async {
    if (ActiveScreenTracker.isViewingGroup(groupId)) return;

    GroupModel? group = _findCachedGroup(context, groupId);
    final nav = Navigator.of(context, rootNavigator: true);

    if (group == null) {
      try {
        final groups = await GroupChatServices().getMyGroups();
        for (final g in groups) {
          if (g.id == groupId && g.isMember) {
            group = g;
            break;
          }
        }
      } catch (e) {
        debugPrint('Error fetching group from notification: $e');
        AppToast.error('Failed to open group chat');
        return;
      }
    }

    if (group == null) {
      AppToast.warning('This group is no longer available');
      return;
    }

    final targetGroup = group;
    openGroupChat(
      targetGroup.id,
      () => nav.pushNamed(AppRoutes.groupChatRoute, arguments: targetGroup),
    );
  }
}
