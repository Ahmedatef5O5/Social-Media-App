import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:story_view/story_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/widgets/custom_confirmation_dialog.dart';
import '../cubit/home_cubit.dart';
import '../models/story_model.dart';

class SingleUserStoryView extends StatefulWidget {
  final StoryModel story;
  final HomeCubit homeCubit;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final VoidCallback onClose;

  const SingleUserStoryView({
    super.key,
    required this.story,
    required this.homeCubit,
    required this.onNext,
    required this.onPrev,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onClose,
  });

  @override
  State<SingleUserStoryView> createState() => _SingleUserStoryViewState();
}

class _SingleUserStoryViewState extends State<SingleUserStoryView> {
  double _pointerDownX = 0;
  double _pointerDownY = 0;
  double _pointerDownTime = 0;
  final StoryController controller = StoryController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyItems = [
      if (widget.story.imageUrl != null)
        StoryItem.pageImage(
          url: widget.story.imageUrl!,
          controller: controller,
          duration: const Duration(seconds: 7),
        )
      else
        StoryItem.text(
          title: widget.story.contentText ?? "",
          backgroundColor: Color(
            int.parse(widget.story.backgroundColor ?? 'ff9c27b0', radix: 16),
          ),
          textStyle: const TextStyle(fontSize: 28, color: Colors.white),
        ),
    ];

    return Stack(
      children: [
        StoryView(
          storyItems: storyItems,
          controller: controller,
          onComplete: () {},
          inline: true,
          progressPosition: ProgressPosition.none,
        ),

        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              _pointerDownX = event.position.dx;
              _pointerDownY = event.position.dy;
              _pointerDownTime = event.timeStamp.inMilliseconds.toDouble();
            },
            onPointerUp: (event) {
              final dx = event.position.dx - _pointerDownX;
              final dy = event.position.dy - _pointerDownY;
              final dt = event.timeStamp.inMilliseconds - _pointerDownTime;

              if (dt > 300 && dx.abs() < 10 && dy.abs() < 10) {
                widget.onLongPressEnd();
                return;
              }

              if (dy.abs() > dx.abs() && dy.abs() > 50) {
                widget.onClose();
                return;
              }

              if (dx.abs() > 50) {
                if (dx < 0) {
                  widget.onNext();
                } else {
                  widget.onPrev();
                }
              } else {
                final screenWidth = MediaQuery.of(context).size.width;
                if (event.position.dx < screenWidth / 2) {
                  widget.onPrev();
                } else {
                  widget.onNext();
                }
              }
            },
            onPointerMove: (event) {
              final dx = event.position.dx - _pointerDownX;
              final dy = event.position.dy - _pointerDownY;
              final dt = event.timeStamp.inMilliseconds - _pointerDownTime;

              if (dt > 300 && dx.abs() < 10 && dy.abs() < 10) {
                widget.onLongPressStart();
              }
            },
          ),
        ),

        Positioned(top: 55, left: 20, right: 20, child: _buildHeader(context)),

        if (widget.story.caption != null && widget.story.caption!.isNotEmpty)
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.story.caption!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final story = widget.story;
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    return Row(
      children: [
        InkWell(
          onTap: () => widget.onClose(),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        const Gap(10),
        CircleAvatar(
          backgroundImage:
              (story.authorImageUrl != null && story.authorImageUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(story.authorImageUrl!)
                  : AssetImage(AppImages.defaultUserImg),
        ),
        const Gap(10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              story.authorId == currentUserId ? 'You' : story.authorName,
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              FormattedDate.getFormattedDate(story.createdAt),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const Spacer(),

        if (story.authorId == currentUserId)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_outlined, color: Colors.white70),
            elevation: 1.5,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onOpened: () {
              controller.pause();
              widget.onLongPressStart();
            },
            onCanceled: () {
              controller.play();
              widget.onLongPressEnd();
            },
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await _showDeleteConfirmation(context);
                if (confirm == true) {
                  widget.homeCubit.deleteStory(story.id);
                  if (context.mounted) Navigator.of(context).pop();
                } else {
                  controller.play();
                  widget.onLongPressEnd();
                }
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        Gap(8),
                        Text(
                          'Delete Story',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
      ],
    );
  }
}

Future<bool?> _showDeleteConfirmation(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    pageBuilder: (context, anim1, anim2) => const SizedBox(),
    transitionBuilder: (context, anim1, anim2, child) {
      return Transform.scale(
        scale: anim1.value,
        child: CustomConfirmationDialog(
          title: 'Delete this story?',
          img: AppImages.deleteFilesAnimationLot,
          confirmBtnText: 'Delete',
          cancelBtnText: 'Cancel',
          onConfirm: () => Navigator.of(context, rootNavigator: true).pop(true),
        ),
      );
    },
  );
}
