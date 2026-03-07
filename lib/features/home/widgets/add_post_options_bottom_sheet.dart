import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/home/widgets/build_option_item.dart';
import '../../../core/themes/app_colors.dart';

class AddPostOptionsBottomSheet extends StatelessWidget {
  const AddPostOptionsBottomSheet({super.key});
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.2,
      minChildSize: 0.15,
      maxChildSize: 0.68,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    Gap(14),
                    Center(
                      child: Container(
                        width: 75,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Gap(12),
                    BuildOptionItem(
                      Icons.image_outlined,
                      'Add Photo',
                      AppColors.primaryColor,
                    ),
                    BuildOptionItem(
                      Icons.videocam_outlined,
                      'Add Video',
                      AppColors.primaryColor,
                    ),
                    BuildOptionItem(
                      Icons.file_upload_outlined,
                      'Add A Document',
                      AppColors.primaryColor,
                    ),
                    BuildOptionItem(
                      Icons.color_lens_outlined,
                      'Background Color',
                      AppColors.primaryColor,
                    ),
                    BuildOptionItem(
                      Icons.gif_box_outlined,
                      'Add GIF',
                      AppColors.primaryColor,
                    ),
                    BuildOptionItem(
                      Icons.video_camera_front_outlined,
                      'Live Video',
                      AppColors.primaryColor,
                    ),
                    BuildOptionItem(
                      Icons.camera_alt_outlined,
                      'Camera',
                      AppColors.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
