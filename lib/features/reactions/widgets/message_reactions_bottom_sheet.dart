import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../model/live_reaction.dart';
import '../model/reaction_entry.dart';
import '../services/reaction_profile_resolver.dart';

class MessageReactionsBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required String messageId,
    required Map<String, LiveReaction> initialReactions,
    required String currentUserId,
    required Widget Function(
      Widget Function(Map<String, LiveReaction> reactions) contentBuilder,
    )
    reactionsBuilder,
    required ReactionProfileResolver profileResolver,
    required void Function(String currentEmoji) onRemoveReaction,
    required void Function(String userId) onOpenProfile,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return reactionsBuilder(
          (reactions) => _MessageReactionsSheetBody(
            key: ValueKey('reactions_sheet_$messageId'),
            reactions: reactions,
            currentUserId: currentUserId,
            profileResolver: profileResolver,
            onRemoveReaction: onRemoveReaction,
            onOpenProfile: onOpenProfile,
          ),
        );
      },
    );
  }
}

class _MessageReactionsSheetBody extends StatefulWidget {
  final Map<String, LiveReaction> reactions;
  final String currentUserId;
  final ReactionProfileResolver profileResolver;
  final void Function(String currentEmoji) onRemoveReaction;
  final void Function(String userId) onOpenProfile;

  const _MessageReactionsSheetBody({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.profileResolver,
    required this.onRemoveReaction,
    required this.onOpenProfile,
  });

  @override
  State<_MessageReactionsSheetBody> createState() =>
      _MessageReactionsSheetBodyState();
}

class _MessageReactionsSheetBodyState
    extends State<_MessageReactionsSheetBody> {
  final Map<String, ReactionEntry> _profiles = {};
  bool _isResolvingInitial = true;
  String _selectedFilter = 'All';
  final _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _resolveMissingProfiles(widget.reactions.keys.toList());
  }

  @override
  void didUpdateWidget(covariant _MessageReactionsSheetBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newUserIds =
        widget.reactions.keys
            .where((id) => !_profiles.containsKey(id))
            .toList();
    if (newUserIds.isNotEmpty) {
      _resolveMissingProfiles(newUserIds);
    }

    if (_sheetController.isAttached &&
        oldWidget.reactions.length != widget.reactions.length) {
      _sheetController.animateTo(
        _computeTargetSize(widget.reactions.length),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _resolveMissingProfiles(List<String> userIds) async {
    if (userIds.isEmpty) {
      if (mounted) setState(() => _isResolvingInitial = false);
      return;
    }
    try {
      final resolved = await widget.profileResolver.resolve(userIds);
      if (!mounted) return;
      setState(() {
        _profiles.addAll(resolved);
        _isResolvingInitial = false;
      });
    } catch (e) {
      debugPrint('MessageReactionsBottomSheet resolve error: $e');
      if (mounted) setState(() => _isResolvingInitial = false);
    }
  }

  double _computeTargetSize(int itemCount) {
    final screenHeight = MediaQuery.of(context).size.height;
    const headerHeight = 90.0;
    const chipsHeight = 56.0;
    const itemHeight = 72.0;
    final contentHeight =
        headerHeight +
        (itemCount > 0 ? chipsHeight : 0) +
        (itemCount * itemHeight);
    return (contentHeight / screenHeight).clamp(0.28, 0.75);
  }

  List<ReactionEntry> get _entries {
    final list = <ReactionEntry>[];
    widget.reactions.forEach((userId, live) {
      final profile = _profiles[userId];
      if (profile == null) return;
      list.add(
        ReactionEntry(
          userId: userId,
          userName: profile.userName,
          userImageUrl: profile.userImageUrl,
          lastSeen: profile.lastSeen,
          emoji: live.emoji,
          createdAt: live.createdAt,
        ),
      );
    });
    list.sort((a, b) {
      if (a.createdAt == null || b.createdAt == null) {
        return a.userName.toLowerCase().compareTo(b.userName.toLowerCase());
      }
      return b.createdAt!.compareTo(a.createdAt!);
    });
    return list;
  }

  Widget _buildFilterChip(
    String filterKey,
    String displayEmoji,
    int count,
    ThemeData theme,
  ) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? theme.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color:
                isSelected
                    ? theme.primaryColor
                    : Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filterKey == 'All' ? 'All' : '$count',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color:
                    isSelected
                        ? theme.primaryColor
                        : theme.textTheme.bodyMedium?.color,
                fontSize: 12,
              ),
            ),
            if (filterKey != 'All') ...[
              const SizedBox(width: 6),
              DefaultTextStyle(
                style: const TextStyle(fontSize: 14),
                child: Text(displayEmoji),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final emojiCounts = <String, int>{};
    for (final live in widget.reactions.values) {
      emojiCounts[live.emoji] = (emojiCounts[live.emoji] ?? 0) + 1;
    }
    final sortedEmojis =
        emojiCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final allEntries = _entries;
    final displayed =
        _selectedFilter == 'All'
            ? allEntries
            : allEntries.where((r) => r.emoji == _selectedFilter).toList();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: GestureDetector(
        onTap: () {},
        child: DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: _computeTargetSize(widget.reactions.length),
          minChildSize: 0.28,
          maxChildSize: 0.75,
          builder: (context, scrollController) {
            return Material(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Reactions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.reactions.isNotEmpty) ...[
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildFilterChip(
                            'All',
                            'All',
                            widget.reactions.length,
                            theme,
                          ),
                          for (final entry in sortedEmojis)
                            _buildFilterChip(
                              entry.key,
                              entry.key,
                              entry.value,
                              theme,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Expanded(
                    child:
                        _isResolvingInitial
                            ? const CustomLoadingIndicator()
                            : displayed.isEmpty
                            ? const Center(child: Text('No reactions yet.'))
                            : ListView.builder(
                              physics: const ClampingScrollPhysics(),
                              controller: scrollController,
                              padding: const EdgeInsets.only(
                                bottom: 24,
                                top: 8,
                              ),
                              itemCount: displayed.length,
                              itemBuilder: (context, index) {
                                final r = displayed[index];
                                final isMe = r.userId == widget.currentUserId;

                                void handleTap() {
                                  HapticFeedback.lightImpact();
                                  if (isMe) {
                                    widget.onRemoveReaction(r.emoji);
                                    if (widget.reactions.length == 1) {
                                      Navigator.of(context).pop();
                                    }
                                  } else {
                                    widget.onOpenProfile(r.userId);
                                  }
                                }

                                return ListTile(
                                  onTap: handleTap,
                                  leading: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      AppAvatar(
                                        imageUrl: r.userImageUrl,
                                        size: 44,
                                      ),
                                      Positioned(
                                        bottom: -4,
                                        right: -4,
                                        child: Container(
                                          padding: const EdgeInsets.all(1.2),
                                          decoration: BoxDecoration(
                                            color:
                                                theme.scaffoldBackgroundColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            r.emoji,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    isMe ? 'You' : r.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle:
                                      isMe
                                          ? Text(
                                            'Tap to remove',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(color: Colors.grey),
                                          )
                                          : null,
                                  trailing:
                                      r.createdAt != null
                                          ? Text(
                                            FormattedDate.getFormattedDate(
                                              r.createdAt!,
                                              isShort: true,
                                            ),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(color: Colors.grey),
                                          )
                                          : null,
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
