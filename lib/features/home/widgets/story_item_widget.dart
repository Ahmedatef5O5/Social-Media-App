import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/features/home/cubit/home_cubit.dart';
import 'package:social_media_app/features/home/models/story_model.dart';
import '../../../core/themes/app_colors.dart';

class StoryItemWidget extends StatelessWidget {
  final StoryModel? story;
  const StoryItemWidget({super.key, this.story});
  void _showAddStoryOptions(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add to Story',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(),
                ),
                const Gap(20),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primaryColor,
                  ),
                  title: const Text('Gallery'),
                  onTap:
                      () => _pickAndUpload(
                        context,
                        ImageSource.gallery,
                        homeCubit,
                      ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.green),
                  title: const Text('Take a Photo'),
                  onTap:
                      () => _pickAndUpload(
                        context,
                        ImageSource.camera,
                        homeCubit,
                      ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    ImageSource source,
    HomeCubit homeCubit,
  ) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final userData = homeCubit.currentUserData;
      if (userData != null) {
        homeCubit.addStory(file: file, user: userData);
      } else {
        debugPrint('User data is null , cannot add story');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (story == null) {
          _showAddStoryOptions(context);
          // Navigate to share story page
        } else {
          // Navigate to view story page
        }
      },

      child: Column(
        children: [
          Container(
            height: 50,
            width: 50,
            // margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgColor2,
              border: Border.all(color: AppColors.bgColor2, width: 2),
            ),
            child: CircleAvatar(
              radius: 8,

              backgroundColor:
                  story == null ? AppColors.bgColor2 : AppColors.transparent,
              backgroundImage:
                  story == null ? null : NetworkImage(story!.imageUrl),

              child:
                  story == null
                      ? const Icon(
                        Icons.add_outlined,
                        size: 22,
                        color: AppColors.white,
                      )
                      : null,
            ),
          ),
          Gap(6),
          story == null
              ? Text(
                'Share Story',
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: AppColors.grey6,
                ),
              )
              : Text(
                story!.authorName.split(' ').first,

                // story!.authorId,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.grey9,
                ),
              ),
        ],
      ),
    );
  }
}
