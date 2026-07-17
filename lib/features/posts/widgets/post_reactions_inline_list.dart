import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../comments/helper/reactor_avatar_stack.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../../profile/widgets/user_preview_dialog.dart';
import '../../reactions/model/reaction_entry.dart';
import '../../single_chats/models/chat_user_model.dart';
import '../cubit/posts_cubit/posts_cubit.dart';
import '../model/post_model.dart';
import '../model/post_reaction_model.dart';

class PostReactionsInlineList extends StatefulWidget {
  final String postId;

  const PostReactionsInlineList({super.key, required this.postId});

  @override
  State<PostReactionsInlineList> createState() =>
      _PostReactionsInlineListState();
}

class _PostReactionsInlineListState extends State<PostReactionsInlineList> {
  late Future<List<ReactionEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<ReactionEntry>> _fetch() async {
    final response = await SupabaseProvider.client
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

    return List<Map<String, dynamic>>.from(response).map((r) {
      final user = r[SupabaseConstants.users] as Map<String, dynamic>?;
      final lastSeenStr = user?[UserColumns.lastSeen] as String?;
      return ReactionEntry(
        userId: user?[UserColumns.id] ?? '',
        userName: user?[UserColumns.name] ?? 'Unknown User',
        userImageUrl: user?[UserColumns.imageUrl],
        lastSeen: lastSeenStr != null ? DateTime.tryParse(lastSeenStr) : null,
        emoji: reactionGlyph(r[LikeColumns.reaction] as String? ?? 'like'),
        createdAt: r[LikeColumns.createdAt] as String?,
      );
    }).toList();
  }

  void _refetch() {
    if (!mounted) return;
    setState(() {
      _future = _fetch();
    });
  }

  int _reactionsSignature(PostsState state) {
    if (state is! PostsLoaded) return 0;
    try {
      final post = state.posts.findById(widget.postId);
      final total = post!.reactions.fold<int>(0, (s, r) => s + r.count);
      return Object.hash(total, post.myReactionEmoji);
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PostsCubit, PostsState>(
      listenWhen:
          (previous, current) =>
              _reactionsSignature(previous) != _reactionsSignature(current),
      listener: (context, state) => _refetch(),
      child: FutureBuilder<List<ReactionEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ReactionsListSkeleton();
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Failed to load reactions.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.grey6),
              ),
            );
          }

          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 36,
                      color: AppColors.grey5,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No reactions yet.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.grey6),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${entries.length} Reactions',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium!.copyWith(color: AppColors.grey7),
                  ),
                  const SizedBox(width: 12),
                  ReactorsAvatarStack(
                    imageUrls:
                        entries.map((e) => e.userImageUrl ?? '').toList(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _ReactionEntryTile(entry: entries[index]);
                },
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

class _ReactionEntryTile extends StatelessWidget {
  final ReactionEntry entry;

  const _ReactionEntryTile({required this.entry});

  bool _isMe(BuildContext context) =>
      entry.userId == SupabaseProvider.id && entry.userId.isNotEmpty;

  void _onAvatarTap(BuildContext context) {
    if (_isMe(context)) {
      final navController = context.read<HomeCubit>().navController;
      Navigator.of(context).pop();
      navController?.jumpToTab(3);
    } else {
      showDialog(
        context: context,
        builder:
            (context) => UserPreviewDialog(
              user: ChatUserModel(
                id: entry.userId,
                name: entry.userName,
                imageUrl: entry.userImageUrl,
                lastSeen: entry.lastSeen,
              ),
              showContactOptions: false,
            ),
      );
    }
  }

  void _onNameTap(BuildContext context) {
    if (_isMe(context)) {
      final navController = context.read<HomeCubit>().navController;
      Navigator.of(context).pop();
      navController?.jumpToTab(3);
    } else {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed(AppRoutes.profileViewRoute, arguments: entry.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt =
        entry.createdAt != null ? DateTime.tryParse(entry.createdAt!) : null;

    return Row(
      children: [
        GestureDetector(
          onTap: () => _onAvatarTap(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AppAvatar(imageUrl: entry.userImageUrl, size: 44),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(fontSize: 13),
                    child: Text(entry.emoji),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _onNameTap(context),
            behavior: HitTestBehavior.opaque,
            child: Text(
              entry.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (createdAt != null) ...[
          const SizedBox(width: 8),
          Text(
            _formatRelativeTime(createdAt),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.grey5),
          ),
        ],
      ],
    );
  }
}

String _formatRelativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  if (diff.inHours < 24) return '${diff.inHours} hr';
  if (diff.inDays < 7) return '${diff.inDays} d';
  return '${(diff.inDays / 7).floor()} w';
}

class _ReactionsListSkeleton extends StatelessWidget {
  const _ReactionsListSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 140,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
