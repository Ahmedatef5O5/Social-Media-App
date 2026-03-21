import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';

class CreatePostHeaderSection extends StatelessWidget {
  const CreatePostHeaderSection({
    super.key,
    required bool canPost,
    this.onTap,
    this.isLoading = false,
  }) : _canPost = canPost;
  final void Function()? onTap;
  final bool _canPost;
  final bool isLoading;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close, size: 24, color: AppColors.black54),
        ),
        Gap(4),
        Text(
          'Create a Post',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w400,
            color: AppColors.black54,
            fontSize: 16,
          ),
        ),
        Spacer(),
        GestureDetector(
          onTap: onTap,
          child:
              isLoading
                  ? CustomLoadingIndicator()
                  : Text(
                    'Post',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                      color:
                          _canPost
                              ? Theme.of(context).primaryColor
                              : AppColors.black54,
                      fontSize: 17,
                    ),
                  ),
        ),
      ],
    );
  }
}
