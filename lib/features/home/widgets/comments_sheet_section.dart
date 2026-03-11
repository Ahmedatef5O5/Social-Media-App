import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:social_media_app/features/home/models/post_model.dart';
import 'package:social_media_app/features/home/widgets/comment_section.dart';
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

  @override
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
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return GestureDetector(
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
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Likes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Comments',
                        style: Theme.of(context).textTheme.titleMedium,
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
    );
  }
}
