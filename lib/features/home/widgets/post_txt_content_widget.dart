import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_linkify_text.dart';
import '../models/post_model.dart';

class PostTxtContentWidget extends StatelessWidget {
  const PostTxtContentWidget({super.key, required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return post.text.trim().isNotEmpty
        ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              const Gap(4),
              CustomLinkifyText(
                text: post.text.trim(),
                maxLines: 10,
                overflow: TextOverflow.ellipsis,

                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                ),
              ),
              const Gap(8),
            ],
          ),
        )
        : SizedBox.shrink();
  }
}
