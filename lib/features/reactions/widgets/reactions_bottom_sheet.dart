import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../../single_chats/models/chat_user_model.dart';
import '../model/reaction_entry.dart';

class ReactionsBottomSheet extends StatefulWidget {
  final Future<List<ReactionEntry>> Function() fetchReactions;

  const ReactionsBottomSheet({super.key, required this.fetchReactions});

  @override
  State<ReactionsBottomSheet> createState() => _ReactionsBottomSheetState();
}

class _ReactionsBottomSheetState extends State<ReactionsBottomSheet> {
  bool _isLoading = true;
  List<ReactionEntry> _reactions = [];
  String _selectedFilter = 'All';

  final _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await widget.fetchReactions();
    if (!mounted) return;
    setState(() {
      _reactions = data;
      _isLoading = false;
    });

    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        _computeTargetSize(data.length),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
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

    final fraction = contentHeight / screenHeight;
    return fraction.clamp(0.28, 0.75);
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
              const Gap(6),
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
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final navController = context.read<HomeCubit>().navController;

    final emojiCounts = <String, int>{};
    for (var r in _reactions) {
      emojiCounts[r.emoji] = (emojiCounts[r.emoji] ?? 0) + 1;
    }
    final sortedEmojis =
        emojiCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final displayed =
        _selectedFilter == 'All'
            ? _reactions
            : _reactions.where((r) => r.emoji == _selectedFilter).toList();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: GestureDetector(
        onTap: () {},
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Gap(12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Gap(12),
                  Text(
                    'Reactions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Gap(12),
                  if (!_isLoading && _reactions.isNotEmpty) ...[
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildFilterChip(
                            'All',
                            'All',
                            _reactions.length,
                            theme,
                          ),
                          for (var entry in sortedEmojis)
                            _buildFilterChip(
                              entry.key,
                              entry.key,
                              entry.value,
                              theme,
                            ),
                        ],
                      ),
                    ),
                    const Gap(8),
                  ],
                  Expanded(
                    child:
                        _isLoading
                            ? const CustomLoadingIndicator()
                            : displayed.isEmpty
                            ? const Center(child: Text('No reactions yet.'))
                            : ListView.builder(
                              physics: const ClampingScrollPhysics(),
                              controller: scrollController,
                              padding: const EdgeInsets.only(
                                bottom: 100,
                                top: 8,
                              ),
                              itemCount: displayed.length,
                              itemBuilder: (context, index) {
                                final r = displayed[index];
                                final isMe = r.userId == currentUserId;

                                return ListTile(
                                  leading: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (isMe) {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pop();
                                            navController?.jumpToTab(3);
                                          } else {
                                            showDialog(
                                              context: context,
                                              builder:
                                                  (
                                                    context,
                                                  ) => UserPreviewDialog(
                                                    user: ChatUserModel(
                                                      id: r.userId,
                                                      name: r.userName,
                                                      imageUrl: r.userImageUrl,
                                                      lastSeen: r.lastSeen,
                                                    ),
                                                    showContactOptions: false,
                                                  ),
                                            );
                                          }
                                        },
                                        child: AppAvatar(
                                          imageUrl: r.userImageUrl,
                                          size: 44,
                                        ),
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
                                  title: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                      if (isMe) {
                                        navController?.jumpToTab(3);
                                      } else {
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pushNamed(
                                          AppRoutes.profileViewRoute,
                                          arguments: r.userId,
                                        );
                                      }
                                    },
                                    child: Text(
                                      r.userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
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
