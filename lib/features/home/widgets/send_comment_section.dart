import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import '../../../core/themes/app_colors.dart';
import '../models/post_model.dart';

class SendCommentSection extends StatefulWidget {
  const SendCommentSection({super.key, required this.post});

  final PostModel post;

  @override
  State<SendCommentSection> createState() => _SendCommentSectionState();
}

class _SendCommentSectionState extends State<SendCommentSection> {
  final _commentController = TextEditingController();
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final textComment = _commentController.text.trim();
    if (textComment.isNotEmpty) {
      context.read<HomeCubit>().addComment(widget.post.id, textComment);
      _commentController.clear();
      // FocusScope.of(context).unfocus(); to close keyboard after send a comment
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state is AddCommentSuccess) {
          _commentController.clear();
        }
        if (state is AddCommentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AddingCommentLoading;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  enabled: !isLoading,
                  onSubmitted: (_) => _submitComment(),
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              isLoading
                  ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CupertinoActivityIndicator(color: AppColors.black12),
                  )
                  : IconButton(
                    onPressed: () {
                      _submitComment();
                      // logic
                    },
                    icon: const Icon(Icons.send, color: AppColors.primaryColor),
                  ),
            ],
          ),
        );
      },
    );
  }
}
