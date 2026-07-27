import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/link/widgets/message_link_preview.dart';
import '../../../core/mentions/widgets/mention_rich_text.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
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
                textWidget: MentionRichText(
                  text: postText,
                  mentions: post.mentions,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                  ),
                  onMentionTap: (userId, name) {
                    final currentUserId = SupabaseProvider.idOrNull;
                    if (userId == currentUserId) return;
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed(AppRoutes.profileViewRoute, arguments: userId);
                  },
                ),
              ),
              const Gap(8),
            ],
          ),
        )
        : const SizedBox.shrink();
  }
}
