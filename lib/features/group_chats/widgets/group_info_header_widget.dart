import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/widgets/directional_text_field.dart';
import '../../../core/chat_shared/helpers/muted_badge_icon.dart';
import '../../../core/constants/app_images.dart';
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
  final VoidCallback onCancel;
  final VoidCallback onChangePhoto;
  final VoidCallback onSettingsTap;
  final bool isMuted;
  final int totalMembersCount;
  final int onlineMembersCount;

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
    required this.onCancel,
    required this.onChangePhoto,
    required this.onSettingsTap,
    required this.isMuted,
    required this.totalMembersCount,
    required this.onlineMembersCount,
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
        onCancel: onCancel,
        onChangePhoto: onChangePhoto,
        onSettingsTap: onSettingsTap,
        isMuted: isMuted,
        topPadding: MediaQuery.paddingOf(context).top,
        primary: Theme.of(context).primaryColor,
        isSavingName: isSavingName,
        totalMembersCount: totalMembersCount,
        onlineMembersCount: onlineMembersCount,
      ),
    );
  }
}

class _GroupInfoHeaderDelegate extends SliverPersistentHeaderDelegate {
  static const double _badgesReservedHeight = 40;
  static const double _expandedContentHeight = 250 + _badgesReservedHeight;
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
  final VoidCallback onCancel;
  final VoidCallback onChangePhoto;
  final VoidCallback onSettingsTap;
  final bool isMuted;
  final double topPadding;
  final Color primary;
  final int totalMembersCount;
  final int onlineMembersCount;

  _GroupInfoHeaderDelegate({
    required this.group,
    required this.isAdmin,
    required this.isEditingName,
    required this.isSavingName,
    required this.isUploadingPhoto,
    required this.controller,
    required this.onEditTap,
    required this.onSubmit,
    required this.onCancel,
    required this.onChangePhoto,
    required this.onSettingsTap,
    required this.isMuted,
    required this.topPadding,
    required this.primary,
    required this.totalMembersCount,
    required this.onlineMembersCount,
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
    final badgesScrollOpacity = (1 - (t / 0.5)).clamp(0.0, 1.0);

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

          if (badgesScrollOpacity > 0) ...[
            Positioned(
              left: 16,
              bottom: 16,
              child: Opacity(
                opacity: badgesScrollOpacity,
                child: _EdgeBadgeSlot(
                  isEditingName: isEditingName,
                  child: _TotalMembersBadge(count: totalMembersCount),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Opacity(
                opacity: badgesScrollOpacity,
                child: _EdgeBadgeSlot(
                  isEditingName: isEditingName,
                  child: _OnlineMembersBadge(count: onlineMembersCount),
                ),
              ),
            ),
          ],
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
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => const FullScreenImageViewer(),
                settings: RouteSettings(
                  arguments: {
                    'url': group.avatarUrl ?? AppImages.defaultGroupImg,
                    'tag': 'group-avatar-${group.id}',
                    'isAsset': hasAvatar ? false : true,
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
                        ? Container(
                          padding: EdgeInsets.zero,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage(AppImages.defaultGroupImg),
                              fit: BoxFit.cover,
                            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.only(left: 14, right: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: DirectionalTextField(
                      controller: controller,
                      onSubmitted: (_) => onSubmit(),
                      cursorColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        hintText: 'Group name',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  if (isSavingName)
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else ...[
                    _GlassIconAction(
                      icon: Icons.close_rounded,
                      onTap: onCancel,
                      iconColor: Colors.white70,
                      tooltip: 'Cancel',
                    ),
                    const SizedBox(width: 2),
                    _GlassIconAction(
                      icon: Icons.check_rounded,
                      onTap: onSubmit,
                      iconColor: Colors.white,
                      emphasized: true,
                      tooltip: 'Save',
                    ),
                  ],
                ],
              ),
            ),
          ),
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
        oldDelegate.isSavingName != isSavingName ||
        oldDelegate.isUploadingPhoto != isUploadingPhoto ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.primary != primary ||
        oldDelegate.totalMembersCount != totalMembersCount ||
        oldDelegate.onlineMembersCount != onlineMembersCount;
  }
}

class _EdgeBadgeSlot extends StatelessWidget {
  final bool isEditingName;
  final Widget child;

  const _EdgeBadgeSlot({required this.isEditingName, required this.child});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isEditingName,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        offset: isEditingName ? const Offset(0, 0.6) : Offset.zero,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: isEditingName ? 0.0 : 1.0,
          child: child,
        ),
      ),
    );
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

class _GlassIconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final bool emphasized;
  final String? tooltip;

  const _GlassIconAction({
    required this.icon,
    required this.onTap,
    required this.iconColor,
    this.emphasized = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              emphasized
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Icon(icon, color: iconColor, size: 17),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _GroupInfoGlassBadge extends StatelessWidget {
  final Widget child;

  const _GroupInfoGlassBadge({required this.child, Key? key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: key,
      borderRadius: BorderRadius.circular(20),

      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Bottom-left "N Members" glass pill.
class _TotalMembersBadge extends StatelessWidget {
  final int count;

  const _TotalMembersBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child:
          count <= 0
              ? const SizedBox.shrink(
                key: ValueKey('total_members_badge_hidden'),
              )
              : _GroupInfoGlassBadge(
                key: const ValueKey('total_members_badge_visible'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RollingCountText(
                      count: count,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.people_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'Members',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

/// Bottom-right "N online" glass pill with a breathing presence dot.

class _OnlineMembersBadge extends StatelessWidget {
  final int count;

  const _OnlineMembersBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder:
          (child, animation) =>
              FadeTransition(opacity: animation, child: child),
      child:
          count <= 0
              ? const SizedBox.shrink(key: ValueKey('online_badge_hidden'))
              : _GroupInfoGlassBadge(
                key: const ValueKey('online_badge_visible'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _PulsingOnlineDot(size: 8),
                    const SizedBox(width: 6),
                    _RollingCountText(
                      count: count,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'online',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class _PulsingOnlineDot extends StatefulWidget {
  final double size;

  const _PulsingOnlineDot({required this.size});

  @override
  State<_PulsingOnlineDot> createState() => _PulsingOnlineDotState();
}

class _PulsingOnlineDotState extends State<_PulsingOnlineDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
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
        final t = Curves.easeInOut.transform(_controller.value);
        final scale = 0.85 + (0.35 * t);
        final opacity = 0.55 + (0.45 * t);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF34D399), // emerald-400
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RollingCountText extends StatefulWidget {
  final int count;
  final TextStyle style;

  const _RollingCountText({required this.count, required this.style});

  @override
  State<_RollingCountText> createState() => _RollingCountTextState();
}

class _RollingCountTextState extends State<_RollingCountText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _oldCount;
  late int _newCount;

  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _oldCount = widget.count;
    _newCount = widget.count;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didUpdateWidget(covariant _RollingCountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count == _newCount) return;

    _direction = widget.count > _newCount ? 1 : -1;
    _oldCount = _newCount;
    _newCount = widget.count;
    _controller
      ..reset()
      ..forward();
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
        if (_controller.isDismissed) {
          return Text('$_newCount', style: widget.style);
        }

        final t = Curves.easeOutCubic.transform(_controller.value);
        final outgoingOffset = Offset(0, _direction * t);
        final incomingOffset = Offset(0, -_direction * (1 - t));

        return ClipRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              FractionalTranslation(
                translation: outgoingOffset,
                child: Text('$_oldCount', style: widget.style),
              ),
              FractionalTranslation(
                translation: incomingOffset,
                child: Text('$_newCount', style: widget.style),
              ),
            ],
          ),
        );
      },
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
