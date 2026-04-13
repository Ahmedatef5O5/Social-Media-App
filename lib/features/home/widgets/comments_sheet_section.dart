import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:social_media_app/features/home/models/post_model.dart';
import 'package:social_media_app/features/home/widgets/comments_section.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/comment_helper.dart';
import '../../../core/themes/app_colors.dart';
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
  }

  final ScrollController _scrollController = ScrollController();

  /// When set, the send-field shows "@name" prefix and sends a reply
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = context.select<HomeCubit, PostModel?>((cubit) {
      final state = cubit.state;
      List<PostModel>? postsList;
      if (state is PostsLoaded) {
        postsList = state.posts;
      } else if (state is AddingCommentLoading) {
        postsList = state.oldPosts;
      }

      if (postsList != null) {
        try {
          return postsList.firstWhere((p) => p.id == widget.postId);
        } catch (_) {
          return null;
        }
      }

      return null;
    });
    if (post == null) {
      return const SizedBox(height: 300, child: CustomLoadingIndicator());
    }
    return BlocListener<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state is PostsLoaded || state is AddCommentSuccess) {
          if (_isNearBottom()) {
            _scrollToBottom();
          }
          if (state is AddCommentSuccess) _cancelReply();
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
                const Divider(thickness: 4, indent: 150, endIndent: 150),
                const SizedBox(height: 10),

                Flexible(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Likes ${post.likes?.length ?? 0}',
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(color: AppColors.grey7),
                        ),
                        Gap(2),
                        if (post.likersImages != null &&
                            post.likersImages!.isNotEmpty &&
                            post.likes!.isNotEmpty)
                          SizedBox(
                            height: 25,
                            width: 125,
                            child: Stack(
                              children: List.generate(
                                post.likersImages!.take(6).length,
                                (index) {
                                  final String imageUrl =
                                      post.likersImages![index];
                                  final bool isNetworkImage =
                                      imageUrl.isNotEmpty &&
                                      imageUrl.startsWith('http') &&
                                      imageUrl != 'asset:default';
                                  return Positioned(
                                    key: ValueKey('${post.id}_liker_$index'),
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
                                                ? CachedNetworkImage(
                                                  imageUrl: imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Image.asset(
                                                            AppImages
                                                                .defaultUserImg,
                                                            fit: BoxFit.cover,
                                                          ),
                                                  placeholder:
                                                      (context, url) =>
                                                          const CustomLoadingIndicator(),
                                                )
                                                : Image.asset(
                                                  AppImages.defaultUserImg,
                                                  fit: BoxFit.cover,
                                                ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Comments ${countAllComments(post.comments)}',
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(color: AppColors.grey7),
                            ),
                            Spacer(),
                            Text(
                              'Most Recent',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium!.copyWith(
                                color: AppColors.grey6,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 22.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 12,
                                    child: Icon(
                                      Icons.arrow_drop_up_rounded,
                                      size: 35,
                                      color: AppColors.grey7,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 12,
                                    child: Icon(
                                      Icons.arrow_drop_down_rounded,
                                      size: 35,
                                      color: AppColors.grey7,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CommentsSection(post: post, onReplyTap: _startReply),
                      ],
                    ),
                  ),
                ),

                const Divider(),
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
