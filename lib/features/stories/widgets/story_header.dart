import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/router/app_routes.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../model/story_model.dart';
import 'story_delete_dialog.dart';

class StoryHeader extends StatelessWidget {
  final StoryModel story;
  final HomeCubit homeCubit;
  final VoidCallback onClose;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VideoPlayerController? videoController;

  const StoryHeader({
    super.key,
    required this.story,
    required this.homeCubit,
    required this.onClose,
    required this.onPause,
    required this.onResume,
    required this.videoController,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final isMyStory = story.authorId == currentUserId;

    return Row(
      children: [
        InkWell(
          onTap: onClose,
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        const Gap(10),
        CircleAvatar(
          backgroundImage:
              story.authorImageUrl?.isNotEmpty == true
                  ? CachedNetworkImageProvider(story.authorImageUrl!)
                  : const AssetImage(AppImages.defaultUserImg) as ImageProvider,
        ),
        const Gap(10),
        GestureDetector(
          onTap:
              isMyStory
                  ? null
                  : () => Navigator.pushNamed(
                    context,
                    AppRoutes.profileViewRoute,
                    arguments: story.authorId,
                  ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMyStory ? 'You' : story.authorName,
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                FormattedDate.getFormattedDate(
                  DateTime.parse(story.createdAt).toLocal().toIso8601String(),
                ),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (isMyStory)
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onOpened: onPause,
            onCanceled: onResume,
            onSelected: (_) async {
              final confirm = await showDeleteStoryDialog(context);
              if (confirm == true) {
                homeCubit.deleteStory(story.id);
                Navigator.pop(context);
              } else {
                onResume();
              }
            },
            itemBuilder:
                (_) => const [
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
