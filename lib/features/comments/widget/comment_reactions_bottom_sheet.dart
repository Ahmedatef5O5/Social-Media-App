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
import '../services/comments_service.dart';

class CommentReactionsBottomSheet extends StatefulWidget {
  final String commentId;
  const CommentReactionsBottomSheet({super.key, required this.commentId});

  @override
  State<CommentReactionsBottomSheet> createState() =>
      _CommentReactionsBottomSheetState();
}

class _CommentReactionsBottomSheetState
    extends State<CommentReactionsBottomSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reactions = [];
  String _selectedFilter = 'All';

  final CommentsService _commentsService = CommentsService();

  @override
  void initState() {
    super.initState();
    _fetchReactions();
  }

  Future<void> _fetchReactions() async {
    final data = await _commentsService.getCommentReactionsDetails(
      widget.commentId,
    );
    if (mounted) {
      setState(() {
        _reactions = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final navController = context.read<HomeCubit>().navController;
    final uniqueEmojis =
        _reactions.map((r) => r['emoji'] as String).toSet().toList();

    final filteredReactions =
        _selectedFilter == 'All'
            ? _reactions
            : _reactions.where((r) => r['emoji'] == _selectedFilter).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
        minHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Gap(16),
          Text(
            'Reactions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(16),

          if (!_isLoading && _reactions.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('All', _reactions.length),
                  const Gap(8),
                  ...uniqueEmojis.map((emoji) {
                    final count =
                        _reactions.where((r) => r['emoji'] == emoji).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(emoji, count),
                    );
                  }),
                ],
              ),
            ),
          const Gap(8),

          Expanded(
            child:
                _isLoading
                    ? const Center(child: CustomLoadingIndicator())
                    : filteredReactions.isEmpty
                    ? const Center(child: Text('No reactions yet.'))
                    : ListView.builder(
                      itemCount: filteredReactions.length,
                      itemBuilder: (context, index) {
                        final reaction = filteredReactions[index];
                        final user = reaction['users'];
                        final emoji = reaction['emoji'];
                        final createdAt = reaction['created_at'];
                        final userId = user?['id'];
                        final userName = user?['name'] ?? 'Unknown User';
                        final userImage = user?['image_url'];
                        final String? lastSeenStr = user?[UserColumns.lastSeen];
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
                                    Navigator.of(context).pop();
                                    navController?.jumpToTab(3);
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => UserPreviewDialog(
                                            user: ChatUserModel(
                                              id: userId,
                                              name: userName,
                                              imageUrl: userImage,
                                              lastSeen: lastSeen,
                                            ),
                                            showContactOptions: false,
                                          ),
                                    );
                                  }
                                },
                                child: AppAvatar(imageUrl: userImage, size: 44),
                              ),
                              Positioned(
                                bottom: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(1.2),
                                  decoration: BoxDecoration(
                                    color: theme.scaffoldBackgroundColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 13),
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
                                  arguments: userId,
                                );
                              }
                            },
                            child: Text(
                              userName,
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
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  )
                                  : null,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey,
                fontSize: 12,
              ),
            ),
            const Gap(6),

            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
