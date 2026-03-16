import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/home/widgets/build_option_item.dart';
import '../../../core/themes/app_colors.dart';
import '../cubit/home_cubit.dart';

class AddPostOptionsBottomSheet extends StatelessWidget {
  final DraggableScrollableController controller;
  const AddPostOptionsBottomSheet({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    return DraggableScrollableSheet(
      controller: controller,
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
                      onTap: () => homeCubit.pickImageFromGallery(),
                    ),
                    BuildOptionItem(
                      Icons.videocam_outlined,
                      'Add Video',
                      AppColors.primaryColor,
                      onTap: () => homeCubit.pickVideo(),
                    ),
                    BuildOptionItem(
                      Icons.file_upload_outlined,
                      'Add A Document',
                      AppColors.primaryColor,
                      onTap: () => homeCubit.pickDocument(),
                    ),
                    BuildOptionItem(
                      Icons.color_lens_outlined,
                      'Background Color',
                      AppColors.primaryColor,
                      onTap:
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.postThemesViewRoute),
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
                      onTap: () => homeCubit.takePhotoByCamera(),
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
