import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/home/widgets/build_option_item.dart';
import '../cubit/home_cubit.dart';

class AddPostOptionsBottomSheet extends StatelessWidget {
  final DraggableScrollableController controller;
  const AddPostOptionsBottomSheet({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.2,
      minChildSize: 0.15,
      maxChildSize: 0.68,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.9),

            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            border: Border.all(
              color:
                  theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0 : 0.15,
                ),
                blurRadius: 20,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    Gap(14),
                    Center(
                      child: Container(
                        width: 70,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Gap(12),
                    BuildOptionItem(
                      Icons.image_outlined,
                      'Add Photo',
                      colorScheme.primary,
                      onTap: () => homeCubit.pickImageFromGallery(),
                    ),
                    BuildOptionItem(
                      Icons.videocam_outlined,
                      'Add Video',
                      colorScheme.primary,
                      onTap: () => homeCubit.pickVideo(),
                    ),
                    BuildOptionItem(
                      Icons.file_upload_outlined,
                      'Add A Document',
                      colorScheme.primary,
                      onTap: () => homeCubit.pickDocument(),
                    ),
                    BuildOptionItem(
                      Icons.color_lens_outlined,
                      'Background Color',
                      colorScheme.primary,
                      onTap:
                          () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.postThemesViewRoute),
                    ),
                    BuildOptionItem(
                      Icons.gif_box_outlined,
                      'Add GIF',
                      colorScheme.primary,
                    ),
                    BuildOptionItem(
                      Icons.video_camera_front_outlined,
                      'Live Video',
                      colorScheme.primary,
                    ),
                    BuildOptionItem(
                      Icons.camera_alt_outlined,
                      'Camera',
                      colorScheme.primary,
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
