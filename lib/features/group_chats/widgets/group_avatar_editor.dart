import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/full_screen_image_viewer.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';

class GroupAvatarEditor extends StatelessWidget {
  final String groupId;
  final String? originalAvatarUrl;
  final String? currentAvatarUrl;
  final String liveGroupName;
  final TextEditingController titleController;
  final bool isUploadingPhoto;
  final bool isRemovingPhoto;
  final VoidCallback onChangePhoto;
  final VoidCallback onRemovePhoto;

  const GroupAvatarEditor({
    super.key,
    required this.groupId,
    required this.originalAvatarUrl,
    required this.currentAvatarUrl,
    required this.liveGroupName,
    required this.titleController,
    required this.isUploadingPhoto,
    required this.isRemovingPhoto,
    required this.onChangePhoto,
    required this.onRemovePhoto,
  });

  void _openFullScreenAvatar(BuildContext context) {
    final displayUrl = currentAvatarUrl ?? originalAvatarUrl;

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => const FullScreenImageViewer(),
        settings: RouteSettings(
          arguments: {
            'url': displayUrl ?? AppImages.defaultGroupImg,
            'tag': 'group-avatar-$groupId',
            'isAsset': displayUrl == null,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Column(
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _openFullScreenAvatar(context),
                child: Hero(
                  tag: 'group-avatar-$groupId',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primary.withValues(alpha: 0.185),
                        width: 5.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 72,
                      backgroundColor: AppColors.black12,
                      backgroundImage:
                          currentAvatarUrl != null
                              ? CachedNetworkImageProvider(currentAvatarUrl!)
                              : null,
                      child:
                          currentAvatarUrl == null
                              ? Container(
                                padding: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: AssetImage(
                                      AppImages.defaultGroupImg,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                              : null,
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                child: GestureDetector(
                  onTap: isUploadingPhoto ? null : onChangePhoto,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (child, animation) => ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              ),
                          child:
                              isUploadingPhoto
                                  ? const SizedBox(
                                    key: ValueKey('loading'),
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.camera_alt_rounded,
                                    key: ValueKey('camera_icon'),
                                    size: 18,
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (currentAvatarUrl != null && currentAvatarUrl!.isNotEmpty)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: isRemovingPhoto ? null : onRemovePhoto,
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.red.shade500.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder:
                                (child, animation) => ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                ),
                            child:
                                isRemovingPhoto
                                    ? const SizedBox(
                                      key: ValueKey('loading_remove'),
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.delete_outline_rounded,
                                      key: ValueKey('delete_icon'),
                                      size: 18,
                                      color: Colors.white,
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- Live Group Name & Title Preview ---
        Center(
          child: Text(
            liveGroupName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: AnimatedBuilder(
            animation: titleController,
            builder: (context, _) {
              final titleText = titleController.text.trim();
              if (titleText.isEmpty) return const SizedBox.shrink();
              return Text(
                titleText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ),
      ],
    );
  }
}
