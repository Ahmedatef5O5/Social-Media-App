import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_notification_model.dart';

class NotificationsFilterChips extends StatefulWidget {
  final bool isDark;
  final Color primary;
  final NotificationType? activeFilter;
  final ValueChanged<NotificationType?> onFilterSelected;

  const NotificationsFilterChips({
    super.key,
    required this.isDark,
    required this.primary,
    required this.activeFilter,
    required this.onFilterSelected,
  });

  @override
  State<NotificationsFilterChips> createState() =>
      _NotificationsFilterChipsState();
}

class _NotificationsFilterChipsState extends State<NotificationsFilterChips> {
  final List<(NotificationType?, String, IconData)> _filters = [
    (null, 'All', Icons.notifications_rounded),
    (NotificationType.chat, 'Messages', Icons.chat_bubble_outline_rounded),
    (NotificationType.call, 'Calls', Icons.call_rounded),
    (NotificationType.like, 'Likes', Icons.favorite_border_rounded),
    (NotificationType.comment, 'Comments', Icons.comment_outlined),
    (NotificationType.follow, 'Follows', Icons.person_add_outlined),
    (
      NotificationType.friendRequest,
      'Friend Requests',
      Icons.person_add_alt_1_rounded,
    ),
  ];

  late List<GlobalKey> _keys;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _keys = List.generate(_filters.length, (_) => GlobalKey());
    _scrollToActiveFilter();
  }

  @override
  void didUpdateWidget(covariant NotificationsFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeFilter != widget.activeFilter) {
      _scrollToActiveFilter();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveFilter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = _filters.indexWhere((f) => f.$1 == widget.activeFilter);
      if (index != -1 && _keys[index].currentContext != null) {
        Scrollable.ensureVisible(
          _keys[index].currentContext!,
          alignment: 0.5,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final (type, label, icon) = _filters[i];
          final isActive = widget.activeFilter == type;
          return GestureDetector(
            key: _keys[i],
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onFilterSelected(type);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isActive
                        ? widget.primary
                        : (widget.isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(20),
                border:
                    isActive
                        ? null
                        : Border.all(
                          color:
                              widget.isDark
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
                            : (widget.isDark
                                ? Colors.white54
                                : Colors.grey.shade600),
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
                              : (widget.isDark
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
}
