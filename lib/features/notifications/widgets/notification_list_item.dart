import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import '../models/app_notification_model.dart';

class NotificationListItem extends StatelessWidget {
  final AppNotification notification;
  final bool isDark;
  final Color primary;
  final int index;
  final ValueChanged<String> onMarkAsRead;
  final ValueChanged<String> onDelete;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.isDark,
    required this.primary,
    required this.index,
    required this.onMarkAsRead,
    required this.onDelete,
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
          _handleNotificationTap(notif);
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
                    Text(
                      notif.body,
                      style: TextStyle(
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
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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

  void _handleNotificationTap(AppNotification notif) {
    // TODO:   Route based on type:
    // switch (notif.type) {
    //   case NotificationType.chat:
    //     Navigator.pushNamed(context, '/chat', arguments: notif.referenceId);
    //   case NotificationType.call:
    //     // nothing (call ended)
    //   ...
    // }
  }
}
