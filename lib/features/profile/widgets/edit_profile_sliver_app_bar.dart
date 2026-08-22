import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';

class EditProfileSliverAppBar extends StatelessWidget {
  final double coverHeight;
  final String? coverUrl;
  final File? selectedCoverFile;
  final VoidCallback onEditCover;
  final String? avatarUrl;
  final File? selectedAvatarFile;
  final VoidCallback onEditAvatar;
  final VoidCallback onBackPressed;

  const EditProfileSliverAppBar({
    super.key,
    required this.coverHeight,
    required this.onEditCover,
    this.coverUrl,
    this.selectedCoverFile,
    this.avatarUrl,
    this.selectedAvatarFile,
    required this.onEditAvatar,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top - 16;
    final double collapsedHeight = topPadding + kToolbarHeight;

    final double expandedAvatarSize = 90.0;
    final double bottomOverlap = expandedAvatarSize * 0.5;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _ProfileHeaderDelegate(
        expandedHeight: coverHeight + bottomOverlap,
        collapsedHeight: collapsedHeight,
        coverHeight: coverHeight,
        coverUrl: coverUrl,
        selectedCoverFile: selectedCoverFile,
        onEditCover: onEditCover,
        avatarUrl: avatarUrl,
        selectedAvatarFile: selectedAvatarFile,
        onEditAvatar: onEditAvatar,
        expandedAvatarSize: expandedAvatarSize,
        topPadding: topPadding,
        onBackPressed: onBackPressed,
      ),
    );
  }
}

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double collapsedHeight;
  final double coverHeight;
  final String? coverUrl;
  final File? selectedCoverFile;
  final VoidCallback onEditCover;
  final String? avatarUrl;
  final File? selectedAvatarFile;
  final VoidCallback onEditAvatar;
  final double expandedAvatarSize;
  final double topPadding;
  final VoidCallback onBackPressed;

  _ProfileHeaderDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.coverHeight,
    this.coverUrl,
    this.selectedCoverFile,
    required this.onEditCover,
    this.avatarUrl,
    this.selectedAvatarFile,
    required this.onEditAvatar,
    required this.expandedAvatarSize,
    required this.topPadding,
    required this.onBackPressed,
  });

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) => true;

  ImageProvider _resolveCoverImage() {
    if (selectedCoverFile != null) return FileImage(selectedCoverFile!);
    if (coverUrl != null && coverUrl!.startsWith('http')) {
      final safeUrl = coverUrl!.replaceAll(
        RegExp(r'\.heic$', caseSensitive: false),
        '.jpg',
      );
      return CachedNetworkImageProvider(safeUrl);
    }
    return const AssetImage(AppImages.defaultBackgroundImg);
  }

  ImageProvider _resolveAvatarImage() {
    if (selectedAvatarFile != null) return FileImage(selectedAvatarFile!);
    if (avatarUrl != null && avatarUrl!.startsWith('http')) {
      return CachedNetworkImageProvider(avatarUrl!);
    }
    return const AssetImage(AppImages.defaultUserImg);
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double progress = (shrinkOffset / (maxExtent - minExtent)).clamp(
      0.0,
      1.0,
    );

    final double collapsedAvatarSize = 36.0;
    final double currentAvatarSize =
        lerpDouble(expandedAvatarSize, collapsedAvatarSize, progress)!;

    final double expandedAvatarTop = coverHeight - (expandedAvatarSize * 0.5);
    final double collapsedAvatarTop =
        topPadding + (kToolbarHeight - collapsedAvatarSize) / 2;
    final double currentAvatarTop =
        lerpDouble(expandedAvatarTop, collapsedAvatarTop, progress)!;

    final double expandedAvatarRight = 20.0;
    final double collapsedAvatarRight = 16.0;
    final double currentAvatarRight =
        lerpDouble(expandedAvatarRight, collapsedAvatarRight, progress)!;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Container(
          color: Theme.of(context).primaryColor.withValues(alpha: progress),
        ),

        Positioned(
          top: -shrinkOffset * 0.5,
          left: 0,
          right: 0,
          height: coverHeight,
          child: Opacity(
            opacity: 1.0 - progress,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.black, Colors.transparent],
                    stops: [0.0, 0.75, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(image: _resolveCoverImage(), fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x66000000), Colors.transparent],
                          stops: [0.0, 0.35],
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0x77000000), Colors.transparent],
                          stops: [0.0, 0.4],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (progress < 1.0)
          Positioned(
            left: 11,
            top: coverHeight - 42 - (shrinkOffset * 0.5),
            child: Opacity(
              opacity: (1.0 - (progress * 2)).clamp(0.0, 1.0),
              child: _CircleIconButton(
                icon: Icons.camera_alt_rounded,
                size: 30,
                onTap: onEditCover,
              ),
            ),
          ),

        Positioned(
          top: topPadding,
          left: 0,
          right: 0,
          height: kToolbarHeight,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _CircleIconButton(
                  icon: Icons.arrow_back_ios_new,
                  size: 32,
                  onTap: onBackPressed,
                ),
              ),
              Expanded(
                child: Opacity(
                  opacity: progress,
                  child: Text(
                    'Edit Profile',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: currentAvatarTop,
          right: currentAvatarRight,
          child: GestureDetector(
            onTap: onEditAvatar,
            child: SizedBox(
              width: currentAvatarSize,
              height: currentAvatarSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: currentAvatarSize,
                    height: currentAvatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.75),
                        width: lerpDouble(1.2, 0.8, progress)!,
                      ),
                      image: DecorationImage(
                        image: _resolveAvatarImage(),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (progress < 0.5)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Opacity(
                        opacity: (1.0 - (progress * 2)).clamp(0.0, 1.0),
                        child: Container(
                          padding: EdgeInsets.all(currentAvatarSize * 0.06),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 1.85,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: currentAvatarSize * 0.145,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.48),
        ),
      ),
    );
  }
}
