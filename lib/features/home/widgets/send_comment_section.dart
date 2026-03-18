import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
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
              InkWell(
                onTap: () {},
                child: Image.asset(
                  AppImages.attachmentIcon,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),

              // InkWell(
              //   onTap: () {},
              //   child: Image.asset(
              //     AppImages.selectEmojisIcon,
              //     width: 28,
              //     height: 28,
              //     fit: BoxFit.cover,
              //   ),
              // ),
              const Gap(5),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  enabled: !isLoading,
                  onSubmitted: (_) => _submitComment(),
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: AppColors.grey5,
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                    ),
                    suffixIcon: InkWell(
                      splashColor: AppColors.transparent,
                      onTap: () {},
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.primaryColor,
                        size: 24,
                      ),
                    ),
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(
                        color: AppColors.primaryColor,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(8),
              isLoading
                  ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CustomLoadingIndicator(),
                  )
                  : InkWell(
                    onTap: () {
                      _submitComment();
                    },
                    child: Image.asset(
                      AppImages.sendIcon,
                      width: 24,
                      height: 24,
                      color: AppColors.primaryColor,
                    ),
                  ),
              const Gap(2),
            ],
          ),
        );
      },
    );
  }
}
