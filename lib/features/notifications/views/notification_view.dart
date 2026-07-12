import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../models/app_notification_model.dart';
import '../../../core/widgets/empty_findings_animation_widget.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView>
    with SingleTickerProviderStateMixin {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  late AnimationController _animController;

  NotificationType? _activeFilter;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final userId = SupabaseProvider.id;
      final data = await SupabaseProvider.client
          .from('notifications')
          .select()
          .eq('receiver_id', userId)
          .order('created_at', ascending: false)
          .limit(60);

      if (mounted) {
        setState(() {
          _notifications =
              (data as List)
                  .cast<Map<String, dynamic>>()
                  .map(AppNotification.fromMap)
                  .toList();
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      // If table doesn't exist yet, show empty state
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AppNotification> get _filtered {
    if (_activeFilter == null) return _notifications;
    return _notifications.where((n) => n.type == _activeFilter).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> _markAsRead(String id) async {
    try {
      await SupabaseProvider.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (_) {}

    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      }
    });
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await SupabaseProvider.client.from('notifications').delete().eq('id', id);
    } catch (_) {}
    setState(() => _notifications.removeWhere((n) => n.id == id));
  }

  Future<void> _markAllAsRead() async {
    HapticFeedback.lightImpact();
    final userId = SupabaseProvider.client.auth.currentUser!.id;
    try {
      await SupabaseProvider.client
          .from('notifications')
          .update({'is_read': true})
          .eq('receiver_id', userId)
          .eq('is_read', false);
    } catch (_) {}
    setState(() {
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, primary),
            _buildFilterChips(isDark, primary),
            Expanded(
              child:
                  _isLoading
                      ? _buildShimmer(isDark)
                      : _filtered.isEmpty
                      ? _buildEmptyState(isDark, primary)
                      : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        color: primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 100),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            return _buildSwipeableItem(
                              _filtered[i],
                              isDark,
                              primary,
                              i,
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.07),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: primary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: Icon(Icons.done_all_rounded, size: 16, color: primary),
              label: Text(
                'Mark all read',
                style: TextStyle(
                  color: primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark, Color primary) {
    final filters = [
      (null, 'All', Icons.notifications_rounded),
      (NotificationType.chat, 'Messages', Icons.chat_bubble_outline_rounded),
      (NotificationType.call, 'Calls', Icons.call_rounded),
      (NotificationType.like, 'Likes', Icons.favorite_border_rounded),
      (NotificationType.comment, 'Comments', Icons.comment_outlined),
      (NotificationType.follow, 'Follows', Icons.person_add_outlined),
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: filters.length,
        itemBuilder: (context, i) {
          final (type, label, icon) = filters[i];
          final isActive = _activeFilter == type;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _activeFilter = type);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isActive
                        ? primary
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(20),
                border:
                    isActive
                        ? null
                        : Border.all(
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.shade200,
                          width: 0.8,
                        ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color:
                        isActive
                            ? Colors.white
                            : (isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color:
                          isActive
                              ? Colors.white
                              : (isDark
                                  ? Colors.white60
                                  : Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeableItem(
    AppNotification notif,
    bool isDark,
    Color primary,
    int index,
  ) {
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
            await _markAsRead(notif.id);
          }
          return false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteNotification(notif.id);
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
      child: _buildNotificationItem(notif, isDark, primary, index),
    );
  }

  Widget _buildNotificationItem(
    AppNotification notif,
    bool isDark,
    Color primary,
    int index,
  ) {
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
          if (!notif.isRead) _markAsRead(notif.id);
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

  Widget _buildEmptyState(bool isDark, Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyFindingsThemedAnimation(
            animationPath: AppImages.emptyFindingsLot,
            width: 340,
            height: 280,
          ),
          const SizedBox(height: 20),
          Text(
            _activeFilter == null
                ? 'No notifications yet'
                : 'No ${_activeFilter!.name} notifications',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    final base =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
      itemBuilder:
          (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(radius: 24, backgroundColor: base),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 180,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _handleNotificationTap(AppNotification notif) {
    // Route based on type:
    // switch (notif.type) {
    //   case NotificationType.chat:
    //     Navigator.pushNamed(context, '/chat', arguments: notif.referenceId);
    //   case NotificationType.call:
    //     // nothing (call ended)
    //   ...
    // }
  }
}
