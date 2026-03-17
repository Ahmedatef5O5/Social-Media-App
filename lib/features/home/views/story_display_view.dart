import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/helpers/formatted_date.dart';
import 'package:social_media_app/features/home/models/story_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/themes/app_colors.dart';

class StoryDisplayView extends StatefulWidget {
  final StoryModel story;

  const StoryDisplayView({super.key, required this.story});

  @override
  State<StoryDisplayView> createState() => _StoryDisplayViewState();
}

class _StoryDisplayViewState extends State<StoryDisplayView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          Center(
            child:
                (widget.story.imageUrl != null &&
                        widget.story.imageUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                      imageUrl: widget.story.imageUrl!,
                      fit: BoxFit.cover,
                    )
                    : Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      color: Color(
                        int.parse(
                          widget.story.backgroundColor ?? 'ff9c27b0',
                          radix: 16,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.story.contentText ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
          ),
          Positioned(
            top: 55,
            left: 20,
            right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 22,
                    color: AppColors.white,
                  ),
                ),
                const Gap(10),
                CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                    widget.story.authorImageUrl ?? '',
                  ),
                ),
                const Gap(10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.story.authorId ==
                              Supabase.instance.client.auth.currentUser!.id
                          ? 'You'
                          : widget.story.authorName,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      FormattedDate.getFormattedDate(widget.story.createdAt),

                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: AppColors.white70,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.more_vert_outlined, color: AppColors.white70),
              ],
            ),
          ),

          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 7),
              tween: Tween(begin: 0.0, end: 1.0),
              builder:
                  (context, value, _) => LinearProgressIndicator(
                    value: value,
                    backgroundColor: AppColors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.white70,
                    ),
                    minHeight: 2.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
