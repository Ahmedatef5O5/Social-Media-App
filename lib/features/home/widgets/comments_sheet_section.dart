import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:social_media_app/features/home/models/post_model.dart';
import 'package:social_media_app/features/home/widgets/comment_section.dart';
import '../../../core/constants/app_images.dart';
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
          _scrollToBottom();
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
                // Handle/Divider
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
                            width: 65,
                            child: Stack(
                              children: List.generate(
                                post.likersImages!.take(3).length,
                                (index) => Positioned(
                                  left: index * 18.0,
                                  child: CircleAvatar(
                                    radius: 13,
                                    backgroundColor: AppColors.white,
                                    child: CircleAvatar(
                                      radius: 11,
                                      backgroundImage:
                                          CachedNetworkImageProvider(
                                            post.likersImages![index].isNotEmpty
                                                ? post.likersImages![index]
                                                : AppImages.defaultUserImg,
                                          ),
                                      onBackgroundImageError: (
                                        exception,
                                        stackTrace,
                                      ) {
                                        CachedNetworkImageProvider(
                                          AppImages.defaultUserImg,
                                        );
                                        debugPrint(
                                          'Error loading imageLikers : $exception',
                                        );
                                      },
                                      child:
                                          post.likersImages![index].isEmpty
                                              ? Icon(
                                                Icons.person,
                                                size: 18,
                                                color: AppColors.grey7,
                                              )
                                              : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Comments ${post.comments?.length ?? 0}',
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
                        CommentsSection(post: post),
                      ],
                    ),
                  ),
                ),

                const Divider(),
                SendCommentSection(post: post),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
