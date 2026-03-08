import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/themes/app_colors.dart';

class CreatePostHeaderSection extends StatelessWidget {
  const CreatePostHeaderSection({
    super.key,
    required bool hasText,
    this.onTap,
    this.isLoading = false,
  }) : _hasText = hasText;
  final void Function()? onTap;
  final bool _hasText;
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
          onTap: _hasText ? onTap : null,
          child:
              isLoading
                  ? CupertinoActivityIndicator(
                    color: Theme.of(context).primaryColor,
                  )
                  : Text(
                    'Post',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                      color:
                          _hasText
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
