import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/deep_link/services/deep_link_service.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/share_intent/widgets/share_content_bottom_sheet.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../cubits/stories_cubit/stories_cubit.dart';
import '../models/story_model.dart';
import 'story_delete_dialog.dart';

class StoryHeader extends StatelessWidget {
  final StoryModel story;
  final StoriesCubit storiesCubit;
  final VoidCallback onClose;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VideoPlayerController? videoController;

  const StoryHeader({
    super.key,
    required this.story,
    required this.storiesCubit,
    required this.onClose,
    required this.onPause,
    required this.onResume,
    required this.videoController,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseProvider.id;
    final isMyStory = story.authorId == currentUserId;

    return Row(
      children: [
        InkWell(
          onTap: onClose,
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        const Gap(10),
        GestureDetector(
          onTap:
              isMyStory
                  ? null
                  : () async {
                    onPause();
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.profileViewRoute,
                      arguments: story.authorId,
                    );
                    onResume();
                  },
          child: Row(
            children: [
              PresenceAvatarWidget(
                userId: story.authorId,
                avatarSize: 40,

                showBorder: false,
                child: CircleAvatar(
                  backgroundImage:
                      story.authorImageUrl?.isNotEmpty == true
                          ? CachedNetworkImageProvider(story.authorImageUrl!)
                          : const AssetImage(AppImages.defaultUserImg)
                              as ImageProvider,
                ),
              ),
              const Gap(10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMyStory ? 'You' : story.authorName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    FormattedDate.getFormattedDate(
                      DateTime.parse(
                        story.createdAt,
                      ).toLocal().toIso8601String(),
                    ),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Spacer(),
        if (!isMyStory)
          InkWell(
            onTap: () {
              onPause();
              final url = DeepLinkService.urlForStory(story.id);
              ShareContentBottomSheet.show(
                context,
                url: url,
                shareText:
                    "Check out ${story.authorName}'s story on Social Media App: $url",
              ).whenComplete(onResume);
            },
            child: const Icon(CupertinoIcons.paperplane, color: Colors.white),
          ),
        if (isMyStory)
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onOpened: onPause,
            onCanceled: onResume,
            onSelected: (value) async {
              if (value == 'share') {
                final url = DeepLinkService.urlForStory(story.id);
                ShareContentBottomSheet.show(
                  context,
                  url: url,
                  shareText: 'Check out my story on Social Media App: $url',
                ).whenComplete(onResume);
                return;
              }

              final confirm = await showDeleteStoryDialog(context);
              if (confirm == true) {
                storiesCubit.deleteStory(story.id);
                if (context.mounted) Navigator.pop(context);
              } else {
                onResume();
              }
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'share', child: Text('Share Story')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete Story',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
          ),
      ],
    );
  }
}
