import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_linkify_text.dart';
import '../../../core/link/widgets/message_link_preview.dart';
import '../model/post_model.dart';

class PostTxtContentWidget extends StatelessWidget {
  const PostTxtContentWidget({super.key, required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final String postText = post.text.trim();

    return postText.isNotEmpty
        ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // const Gap(4),
              MessageLinkPreview(
                text: postText,
                isMe: false,
                textWidget: CustomLinkifyText(
                  text: postText,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                  ),
                  linkStyle: const TextStyle(
                    color: Colors.blue,
                    decorationColor: Colors.blue,
                  ),
                ),
              ),
              const Gap(8),
            ],
          ),
        )
        : const SizedBox.shrink();
  }
}
