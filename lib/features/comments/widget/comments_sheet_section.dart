import 'package:shimmer/shimmer.dart';
import 'package:social_media_app/core/widgets/cached_cloudinary_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/comments/cubit/comments_cubit.dart';
import 'package:social_media_app/features/comments/model/comment_sort_option.dart';
import 'package:social_media_app/features/comments/widget/comments_shimmer_skeleton.dart';
import 'package:social_media_app/features/posts/cubit/posts_cubit/posts_cubit.dart';
import 'package:social_media_app/features/posts/model/post_model.dart';
import 'package:social_media_app/features/comments/widget/comments_section.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/comment_helper.dart';
import '../../../core/themes/app_colors.dart';
import '../../posts/widgets/post_reactions_bottom_sheet.dart';
import 'send_comment_section.dart';

class CommentsSheetSection extends StatefulWidget {
  final String postId;

  const CommentsSheetSection({super.key, required this.postId});

  @override
  State<CommentsSheetSection> createState() => _CommentsSheetSectionState();
}

class _CommentsSheetSectionState extends State<CommentsSheetSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CommentsCubit>().loadComments(postId: widget.postId);
    });
  }

  final ScrollController _scrollController = ScrollController();

  String? _replyingToCommentId;
  String? _replyingToAuthorName;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  bool _isNearBottom([double threshold = 120]) {
    if (!_scrollController.hasClients) return false;
    final pos = _scrollController.position;
    return pos.maxScrollExtent - pos.pixels < threshold;
  }

  void _startReply(String commentId, String authorName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToAuthorName = authorName;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToAuthorName = null;
    });
  }

  void _changeSort(CommentSortOption option) {
    final cubit = context.read<CommentsCubit>();
    if (cubit.currentSort == option) return;
    cubit.loadComments(postId: widget.postId, sort: option);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = context.select<PostsCubit, PostModel?>((cubit) {
      final state = cubit.state;

      if (state is PostsLoaded) {
        try {
          return state.posts.firstWhere((p) => p.id == widget.postId);
        } catch (_) {
          return null;
        }
      }

      return null;
    });
    if (post == null) {
      return const SizedBox(height: 300, child: CustomLoadingIndicator());
    }
    return BlocListener<CommentsCubit, CommentsState>(
      listener: (context, state) {
        if (state is CommentOptimisticAdded) {
          if (_isNearBottom()) {
            _scrollToBottom();
          }
        }
        if (state is CommentTempIdResolved) {
          _cancelReply();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus &&
              currentFocus.focusedChild != null) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  margin: const EdgeInsets.only(left: 150, right: 150),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (post.reactions.isNotEmpty) {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder:
                                    (context) => PostReactionsBottomSheet(
                                      postId: post.id,
                                    ),
                              );
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,

                            children: [
                              Text(
                                '${post.likes?.length ?? 0} Reactions',
                                style: Theme.of(context).textTheme.titleMedium!
                                    .copyWith(color: AppColors.grey7),
                              ),
                              Gap(12),
                              if (post.likersImages != null &&
                                  post.likersImages!.isNotEmpty &&
                                  post.likes!.isNotEmpty)
                                SizedBox(
                                  height: 25,
                                  width: 120,
                                  child: Stack(
                                    children: List.generate(
                                      post.likersImages!.take(8).length,
                                      (index) {
                                        final String imageUrl =
                                            post.likersImages![index];
                                        final bool isNetworkImage =
                                            imageUrl.isNotEmpty &&
                                            imageUrl.startsWith('http') &&
                                            imageUrl != 'asset:default';
                                        return Positioned(
                                          key: ValueKey(
                                            '${post.id}_liker_$index',
                                          ),
                                          left: index * 18.0,
                                          child: Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).scaffoldBackgroundColor,
                                              border: Border.all(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).scaffoldBackgroundColor,
                                                width: 2,
                                              ),
                                            ),
                                            child: ClipOval(
                                              child:
                                                  isNetworkImage
                                                      ? CachedCloudinaryImage(
                                                        secureUrl: imageUrl,
                                                        fit: BoxFit.cover,
                                                        isAvatar: true,
                                                        errorWidget:
                                                            (
                                                              context,
                                                              error,
                                                            ) => Image.asset(
                                                              AppImages
                                                                  .defaultUserImg,
                                                              fit: BoxFit.cover,
                                                            ),
                                                        placeholder:
                                                            (context) =>
                                                                const CustomLoadingIndicator(),
                                                      )
                                                      : Image.asset(
                                                        AppImages
                                                            .defaultUserImg,
                                                        fit: BoxFit.cover,
                                                      ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        BlocBuilder<CommentsCubit, CommentsState>(
                          buildWhen:
                              (previous, current) =>
                                  current is CommentsListLoading ||
                                  current is CommentsListLoaded ||
                                  current is CommentOptimisticAdded ||
                                  current is CommentTempIdResolved,
                          builder: (context, state) {
                            final cubit = context.read<CommentsCubit>();
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),

                                  child:
                                      cubit.isLoadingComments
                                          ? const _CommentsCountSkeleton(
                                            key: ValueKey('count_skeleton'),
                                          )
                                          : Text(
                                            key: const ValueKey('count_text'),
                                            '${countAllComments(cubit.comments)} Comments',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium!.copyWith(
                                              color: AppColors.grey7,
                                            ),
                                          ),
                                ),
                                _ElegantSortMenu(
                                  current: cubit.currentSort,
                                  onChanged: _changeSort,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        BlocBuilder<CommentsCubit, CommentsState>(
                          buildWhen:
                              (previous, current) =>
                                  current is CommentsListLoading ||
                                  current is CommentsListLoaded ||
                                  current is CommentOptimisticAdded ||
                                  current is CommentTempIdResolved ||
                                  current is CommentsUiChanged,
                          builder: (context, state) {
                            final cubit = context.read<CommentsCubit>();
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child:
                                  cubit.isLoadingComments
                                      ? Padding(
                                        key: ValueKey('comments_loading'),
                                        padding: EdgeInsets.zero,
                                        child: CommentsShimmerSkeleton(),
                                      )
                                      : CommentsSection(
                                        key: ValueKey(
                                          'comments_${cubit.currentSort.name}',
                                        ),
                                        postId: post.id,
                                        comments: cubit.comments,
                                        onReplyTap: _startReply,
                                      ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                if (_replyingToCommentId != null)
                  _ReplyingToBanner(
                    authorName: _replyingToAuthorName ?? '',
                    onCancel: _cancelReply,
                  ),

                Row(
                  children: [
                    Expanded(
                      child: SendCommentSection(
                        post: post,
                        replyingToCommentId: _replyingToCommentId,
                        replyingToAuthorName: _replyingToAuthorName,
                        onReplySent: () {
                          setState(() {
                            _replyingToCommentId = null;
                            _replyingToAuthorName = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplyingToBanner extends StatelessWidget {
  final String authorName;
  final VoidCallback onCancel;

  const _ReplyingToBanner({required this.authorName, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply_rounded,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Replying to ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey7,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '@$authorName',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Icon(Icons.close_rounded, size: 18, color: AppColors.grey6),
          ),
        ],
      ),
    );
  }
}

class _ElegantSortMenu extends StatelessWidget {
  final CommentSortOption current;
  final ValueChanged<CommentSortOption> onChanged;

  const _ElegantSortMenu({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopupMenuButton<CommentSortOption>(
      initialValue: current,
      onSelected: onChanged,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      color: isDark ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 40),
      icon: Icon(Icons.sort_rounded, color: AppColors.grey7, size: 26),
      itemBuilder:
          (context) =>
              CommentSortOption.values.map((option) {
                final isSelected = current == option;

                return PopupMenuItem<CommentSortOption>(
                  value: option,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        option.icon,
                        size: 20,
                        color:
                            isSelected ? theme.primaryColor : AppColors.grey6,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color:
                              isSelected
                                  ? theme.primaryColor
                                  : (isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[800]),
                        ),
                      ),
                      const SizedBox(width: 24),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: theme.primaryColor,
                        )
                      else
                        const SizedBox(width: 18),
                    ],
                  ),
                );
              }).toList(),
    );
  }
}

class _CommentsCountSkeleton extends StatelessWidget {
  const _CommentsCountSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: 92,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
