import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/chat_shared/helpers/muted_badge_icon.dart';
import '../../../core/widgets/full_screen_image_viewer.dart';
import '../models/group_model.dart';

class GroupInfoHeaderWidget extends StatelessWidget {
  final GroupModel group;
  final bool isAdmin;
  final bool isSavingName;
  final bool isEditingName;
  final bool isUploadingPhoto;
  final TextEditingController controller;
  final VoidCallback onEditTap;
  final VoidCallback onSubmit;
  final VoidCallback onChangePhoto;
  final VoidCallback onSettingsTap;
  final bool isMuted;

  const GroupInfoHeaderWidget({
    super.key,
    required this.group,
    required this.isAdmin,
    required this.isSavingName,
    required this.isEditingName,
    required this.isUploadingPhoto,
    required this.controller,
    required this.onEditTap,
    required this.onSubmit,
    required this.onChangePhoto,
    required this.onSettingsTap,
    required this.isMuted,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _GroupInfoHeaderDelegate(
        group: group,
        isAdmin: isAdmin,
        isEditingName: isEditingName,
        isUploadingPhoto: isUploadingPhoto,
        controller: controller,
        onEditTap: onEditTap,
        onSubmit: onSubmit,
        onChangePhoto: onChangePhoto,
        onSettingsTap: onSettingsTap,
        isMuted: isMuted,
        topPadding: MediaQuery.paddingOf(context).top,
        primary: Theme.of(context).primaryColor,
        isSavingName: isSavingName,
      ),
    );
  }
}

class _GroupInfoHeaderDelegate extends SliverPersistentHeaderDelegate {
  static const double _expandedContentHeight = 250;
  static const double _collapsedContentHeight = kToolbarHeight;
  static const double _avatarExpandedSize = 108;
  static const double _avatarCollapsedSize = 34;
  static const double _avatarExpandedTop = 30;
  static const double _avatarCollapsedLeft = 64;

  final GroupModel group;
  final bool isAdmin;
  final bool isEditingName;
  final bool isSavingName;
  final bool isUploadingPhoto;
  final TextEditingController controller;
  final VoidCallback onEditTap;
  final VoidCallback onSubmit;
  final VoidCallback onChangePhoto;
  final VoidCallback onSettingsTap;
  final bool isMuted;
  final double topPadding;
  final Color primary;

  _GroupInfoHeaderDelegate({
    required this.group,
    required this.isAdmin,
    required this.isEditingName,
    required this.isSavingName,
    required this.isUploadingPhoto,
    required this.controller,
    required this.onEditTap,
    required this.onSubmit,
    required this.onChangePhoto,
    required this.onSettingsTap,
    required this.isMuted,
    required this.topPadding,
    required this.primary,
  });

  @override
  double get maxExtent => _expandedContentHeight + topPadding;

  @override
  double get minExtent => _collapsedContentHeight + topPadding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final maxShrink = maxExtent - minExtent;
    final t = maxShrink <= 0 ? 0.0 : (shrinkOffset / maxShrink).clamp(0.0, 1.0);
    final currentExtent = maxExtent - shrinkOffset;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final hasAvatar = group.avatarUrl?.isNotEmpty == true;

    final hsl = HSLColor.fromColor(primary);
    final bg1 =
        hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
    final bg2 =
        hsl.withLightness((hsl.lightness + 0.05).clamp(0.0, 1.0)).toColor();

    final avatarSize =
        lerpDouble(_avatarExpandedSize, _avatarCollapsedSize, t)!;
    final avatarTop =
        topPadding +
        lerpDouble(
          _avatarExpandedTop,
          (_collapsedContentHeight - _avatarCollapsedSize) / 2,
          t,
        )!;
    final avatarLeft =
        lerpDouble(
          (screenWidth - _avatarExpandedSize) / 2,
          _avatarCollapsedLeft,
          t,
        )!;

    final bigTitleOpacity = (1 - (t / 0.6)).clamp(0.0, 1.0);
    final smallTitleOpacity = ((t - 0.4) / 0.6).clamp(0.0, 1.0);

    return SizedBox(
      height: currentExtent,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: currentExtent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [bg1, primary, bg2],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                Opacity(
                  opacity: (1 - (t / 0.5)).clamp(0.0, 1.0),
                  child: const _AnimatedHeaderIcons(),
                ),
              ],
            ),
          ),

          Positioned(
            top: topPadding,
            left: 0,
            child: _GlassCircleButton(
              icon: Icons.arrow_back_ios_new,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          Positioned(
            top: topPadding,
            right: 0,
            child: _GlassCircleButton(
              icon: Icons.settings_rounded,
              onTap: onSettingsTap,
            ),
          ),

          Positioned(
            top: avatarTop,
            left: avatarLeft,
            width: avatarSize,
            height: avatarSize,
            child: _buildAvatar(context, hasAvatar, avatarSize, t),
          ),

          if (bigTitleOpacity > 0)
            Positioned(
              top: topPadding + _avatarExpandedTop + _avatarExpandedSize + 16,
              left: 0,
              right: 0,
              child: Opacity(opacity: bigTitleOpacity, child: _buildBigTitle()),
            ),

          if (smallTitleOpacity > 0)
            Positioned(
              top: topPadding,
              left: _avatarCollapsedLeft + _avatarCollapsedSize + 10,
              right: 56,
              height: _collapsedContentHeight,
              child: Opacity(
                opacity: smallTitleOpacity,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isMuted)
                        const MutedBadgeIcon(size: 10, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    bool hasAvatar,
    double size,
    double t,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap:
              !hasAvatar
                  ? null
                  : () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => const FullScreenImageViewer(),
                        settings: RouteSettings(
                          arguments: {
                            'url': group.avatarUrl!,
                            'tag': 'group-avatar-${group.id}',
                            'isAsset': false,
                          },
                        ),
                      ),
                    );
                  },
          child: Hero(
            tag: 'group-avatar-${group.id}',
            child: CircleAvatar(
              radius: size / 2,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: CircleAvatar(
                radius: size / 2 - 3,
                backgroundColor: primary,
                backgroundImage:
                    hasAvatar
                        ? CachedNetworkImageProvider(group.avatarUrl!)
                        : null,
                child:
                    !hasAvatar
                        ? Text(
                          group.name.isNotEmpty
                              ? group.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size * 0.36,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : null,
              ),
            ),
          ),
        ),
        if (isAdmin && t < 0.5)
          Positioned(
            bottom: -2,
            right: -2,
            child: Opacity(
              opacity: (1 - (t / 0.5)).clamp(0.0, 1.0),
              child: GestureDetector(
                onTap: isUploadingPhoto ? null : onChangePhoto,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: .8),
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
                              key: ValueKey('header_loading'),
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(
                              Icons.camera_alt_rounded,
                              key: ValueKey('header_camera_icon'),
                              size: 14,
                              color: Colors.white,
                            ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBigTitle() {
    final Widget nameSection;

    if (isEditingName) {
      nameSection = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                textAlign: TextAlign.center,
                onSubmitted: (_) => onSubmit(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 6),
            isSavingName
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : IconButton(
                  icon: const Icon(Icons.check, color: Colors.white, size: 20),
                  onPressed: onSubmit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
          ],
        ),
      );
    } else {
      nameSection = GestureDetector(
        onTap: isAdmin ? onEditTap : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                group.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            if (isMuted) ...[
              const SizedBox(width: 6),
              const MutedBadgeIcon(size: 13, color: Colors.white70),
              const SizedBox(width: 3),
            ],

            if (isAdmin) ...[
              const SizedBox(width: 6),
              const Icon(Icons.edit, color: Colors.white70, size: 15),
            ],
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,

      children: [
        nameSection,
        if (group.title?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              group.title!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  bool shouldRebuild(covariant _GroupInfoHeaderDelegate oldDelegate) {
    return oldDelegate.group != group ||
        oldDelegate.isAdmin != isAdmin ||
        oldDelegate.isEditingName != isEditingName ||
        oldDelegate.isUploadingPhoto != isUploadingPhoto ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.primary != primary;
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(7.0),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedHeaderIcons extends StatefulWidget {
  const _AnimatedHeaderIcons();

  @override
  State<_AnimatedHeaderIcons> createState() => _AnimatedHeaderIconsState();
}

class _AnimatedHeaderIconsState extends State<_AnimatedHeaderIcons>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _floatingIcon(Icons.groups_rounded, 20, 40, t, 0.0, 35),
            _floatingIcon(Icons.chat_bubble_outline, 300, 30, t, 1.5, 28),
            _floatingIcon(Icons.forum_outlined, 150, 15, t, 3.0, 32),
            _floatingIcon(Icons.person_add_alt_1_rounded, 30, 180, t, 4.5, 25),
            _floatingIcon(Icons.send_rounded, 260, 180, t, 0.8, 30),
            _floatingIcon(Icons.favorite_border_rounded, 330, 110, t, 2.2, 22),
            _floatingIcon(Icons.image_outlined, 70, 110, t, 3.7, 26),
            _floatingIcon(Icons.alternate_email_rounded, 200, 80, t, 1.1, 28),
            _floatingIcon(Icons.tag_rounded, 120, 190, t, 5.1, 24),
            _floatingIcon(Icons.mic_none_rounded, 310, 210, t, 2.8, 26),
            _floatingIcon(Icons.videocam_outlined, 10, 100, t, 3.4, 30),
            _floatingIcon(Icons.emoji_emotions_outlined, 180, 150, t, 4.8, 22),
            _floatingIcon(Icons.star_border_rounded, 230, 25, t, 0.5, 20),
            _floatingIcon(Icons.notifications_none_rounded, 90, 50, t, 2.5, 27),
          ],
        );
      },
    );
  }

  Widget _floatingIcon(
    IconData icon,
    double left,
    double top,
    double t,
    double phase,
    double size,
  ) {
    final pulse = math.pow((math.sin(t + phase) + 1) / 2, 5);
    final opacity = 0.08 + (0.40 * pulse);
    final scale = 0.85 + (0.35 * pulse);
    final verticalOffset = math.sin(t + phase) * 15;
    final horizontalOffset = math.cos(t + phase) * 10;

    return Positioned(
      left: left + horizontalOffset,
      top: top + verticalOffset,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          child: Icon(icon, size: size, color: Colors.white),
        ),
      ),
    );
  }
}
