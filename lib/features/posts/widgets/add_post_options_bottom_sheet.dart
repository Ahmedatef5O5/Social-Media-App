import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/posts/widgets/build_option_item.dart';
import '../../../core/toast/app_toast.dart';
import '../cubit/posts_cubit/posts_cubit.dart';

class AddPostOptionsBottomSheet extends StatelessWidget {
  final DraggableScrollableController controller;
  const AddPostOptionsBottomSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final postsCubit = context.read<PostsCubit>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.2,
      minChildSize: 0.15,
      maxChildSize: 0.75,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 25,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Gap(12),
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    BuildOptionItem(
                      Icons.image_rounded,
                      'Add Photo',
                      const Color(0xFF4CAF50),
                      onTap: () => postsCubit.pickImageFromGallery(),
                    ),
                    BuildOptionItem(
                      Icons.videocam_rounded,
                      'Add Video',
                      const Color(0xFF2196F3),
                      onTap: () => postsCubit.pickVideo(),
                    ),
                    BuildOptionItem(
                      Icons.camera_alt_rounded,
                      'Camera',
                      const Color(0xFF009688),
                      onTap: () => postsCubit.takePhotoByCamera(),
                    ),
                    BuildOptionItem(
                      Icons.insert_drive_file_rounded,
                      'Add A Document',
                      const Color(0xFFFF9800),
                      onTap: () => postsCubit.pickDocument(),
                    ),
                    BuildOptionItem(
                      Icons.color_lens_rounded,
                      'Background Color',
                      const Color(0xFFE91E63),
                      onTap:
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.postThemesViewRoute),
                    ),
                    BuildOptionItem(
                      Icons.gif_box_rounded,
                      'Add GIF',
                      const Color(0xFF9C27B0),
                      onTap: () => AppToast.info('Add GIF is coming soon'),
                    ),
                    BuildOptionItem(
                      Icons.video_camera_front_rounded,
                      'Live Video',
                      const Color(0xFFF44336),
                      onTap: () => AppToast.info('Live Video is coming soon'),
                    ),
                    const Gap(20),
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
