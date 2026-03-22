import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../models/story_model.dart';

class StoryPageItem extends StatefulWidget {
  final StoryModel story;
  final VoidCallback onStoryComplete;
  final PageController controller;
  const StoryPageItem({
    super.key,
    required this.story,
    required this.onStoryComplete,
    required this.controller,
  });

  @override
  State<StoryPageItem> createState() => _StoryPageItemState();
}

class _StoryPageItemState extends State<StoryPageItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _verticalDragDistance = 0;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) widget.onStoryComplete();
      }
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,

      //
      onVerticalDragUpdate: (details) {
        _verticalDragDistance += details.delta.dy;
      },

      // ⬇️ لما المستخدم يسيب
      onVerticalDragEnd: (_) {
        if (_verticalDragDistance.abs() > 120) {
          Navigator.of(context).pop(); // اقفل الاستوري
        }
        _verticalDragDistance = 0;
      },
      //pause
      onLongPressDown: (_) => _animationController.stop(),
      onLongPressUp: () => _animationController.forward(),
      onLongPressCancel: () => _animationController.forward(),
      onTapUp: (details) {
        final width = MediaQuery.of(context).size.width;
        final dx = details.localPosition.dx;
        if (dx < width * 0.3) {
          if (widget.controller.hasClients && widget.controller.page! > 0) {
            widget.controller.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        } else if (dx > width * 0.7) {
          widget.onStoryComplete();
        }
      },
      child: Stack(
        children: [
          Center(
            child:
                (widget.story.imageUrl != null &&
                        widget.story.imageUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                      imageUrl: widget.story.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => const CustomLoadingIndicator(),
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
                          color: AppColors.white,
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
                    errorListener: (_) => const CustomLoadingIndicator(),
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
            child: AnimatedBuilder(
              animation: _animationController,
              builder:
                  (context, child) => LinearProgressIndicator(
                    value: _animationController.value,
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
