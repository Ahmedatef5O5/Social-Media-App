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
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const Gap(12),
          Text(
            'Create a Post',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
          Spacer(),
          GestureDetector(
            onTap: onTap,
            child:
                isLoading
                    ? CustomLoadingIndicator()
                    : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _canPost
                                ? Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.9)
                                : AppColors.grey4.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Post',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _canPost ? Colors.white : AppColors.grey4,
                          fontSize: 14,
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
