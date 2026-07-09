import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../../single_chats/models/chat_user_model.dart';
import '../model/post_reaction_model.dart';

class PostReactionsBottomSheet extends StatefulWidget {
  final String postId;
  const PostReactionsBottomSheet({super.key, required this.postId});

  @override
  State<PostReactionsBottomSheet> createState() =>
      _PostReactionsBottomSheetState();
}

class _PostReactionsBottomSheetState extends State<PostReactionsBottomSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reactions = [];

  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchReactions();
  }

  Future<void> _fetchReactions() async {
    try {
      final response = await Supabase.instance.client
          .from(SupabaseConstants.likes)
          .select('''
            ${LikeColumns.reaction},
            ${LikeColumns.createdAt},
            ${SupabaseConstants.users} (
              ${UserColumns.id},
              ${UserColumns.name},
              ${UserColumns.imageUrl},
              ${UserColumns.lastSeen}
            )
          ''')
          .eq(LikeColumns.postId, widget.postId)
          .order(LikeColumns.createdAt, ascending: false);

      if (mounted) {
        setState(() {
          _reactions = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching reactions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildFilterChip(
    String filterKey,
    String displayEmoji,
    int count,
    ThemeData theme,
  ) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterKey;
        });
      },
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
              Text(
                displayEmoji,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withValues(alpha: 1.0) ??
                      Colors.black,
                ),
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

    Map<String, int> reactionCounts = {};
    for (var r in _reactions) {
      final type = r[LikeColumns.reaction] as String? ?? 'like';
      reactionCounts[type] = (reactionCounts[type] ?? 0) + 1;
    }
    final sortedReactions =
        reactionCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final displayedReactions =
        _selectedFilter == 'All'
            ? _reactions
            : _reactions
                .where(
                  (r) =>
                      (r[LikeColumns.reaction] as String? ?? 'like') ==
                      _selectedFilter,
                )
                .toList();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: GestureDetector(
        onTap: () {},
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
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
                  // Indicator Top line
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

                          for (var entry in sortedReactions)
                            _buildFilterChip(
                              entry.key,
                              reactionGlyph(entry.key),
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
                            : displayedReactions.isEmpty
                            ? const Center(child: Text('No reactions yet.'))
                            : ListView.builder(
                              physics: const ClampingScrollPhysics(),
                              controller: scrollController,
                              padding: const EdgeInsets.only(
                                bottom: 100,
                                top: 8,
                              ),
                              itemCount: displayedReactions.length,
                              itemBuilder: (context, index) {
                                final reactionData = displayedReactions[index];
                                final user =
                                    reactionData[SupabaseConstants.users]
                                        as Map<String, dynamic>?;
                                final reactionRaw =
                                    reactionData[LikeColumns.reaction]
                                        as String? ??
                                    'like';
                                final emoji = reactionGlyph(reactionRaw);
                                final createdAt =
                                    reactionData[LikeColumns.createdAt]
                                        as String?;

                                final String userId =
                                    user?[UserColumns.id] ?? '';
                                final String userName =
                                    user?[UserColumns.name] ?? 'Unknown User';
                                final String? userImageUrl =
                                    user?[UserColumns.imageUrl];
                                final String? lastSeenStr =
                                    user?[UserColumns.lastSeen];
                                final DateTime? lastSeen =
                                    lastSeenStr != null
                                        ? DateTime.tryParse(lastSeenStr)
                                        : null;
                                final bool isMe = userId == currentUserId;

                                return ListTile(
                                  leading: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (isMe) {
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
                                                      id: userId,
                                                      name: userName,
                                                      imageUrl: userImageUrl,
                                                      lastSeen: lastSeen,
                                                    ),
                                                    showContactOptions: false,
                                                  ),
                                            );
                                          }
                                        },
                                        child: AppAvatar(
                                          imageUrl: userImageUrl,
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
                                            emoji,
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
                                      if (isMe) {
                                        navController?.jumpToTab(3);
                                      } else {
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pushNamed(
                                          AppRoutes.profileViewRoute,
                                          arguments: userId,
                                        );
                                      }
                                    },
                                    child: Text(
                                      user?[UserColumns.name] ?? 'Unknown User',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  trailing:
                                      createdAt != null
                                          ? Text(
                                            FormattedDate.getFormattedDate(
                                              createdAt,
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
