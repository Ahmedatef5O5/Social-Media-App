import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../home/widgets/full_screen_image_viewer.dart';
import '../models/group_model.dart';

class GroupInfoHeader extends StatelessWidget {
  final GroupModel group;
  final bool isAdmin;
  final bool isEditingName;
  final TextEditingController controller;
  final VoidCallback onEditTap;
  final VoidCallback onSubmit;
  final VoidCallback onChangePhoto;

  const GroupInfoHeader({
    super.key,
    required this.group,
    required this.isAdmin,
    required this.isEditingName,
    required this.controller,
    required this.onEditTap,
    required this.onSubmit,
    required this.onChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = group.avatarUrl?.isNotEmpty == true;
    final primary = Theme.of(context).primaryColor;
    final hsl = HSLColor.fromColor(primary);
    final bg1 =
        hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
    final bg2 =
        hsl.withLightness((hsl.lightness + 0.05).clamp(0.0, 1.0)).toColor();

    return SliverAppBar(
      pinned: true,
      expandedHeight: 250,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
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
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
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

            const _AnimatedHeaderIcons(),

            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.85 + (value * 0.15),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Gap(30),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (!hasAvatar) return;

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
                              radius: 58,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: bg1,
                                backgroundImage:
                                    hasAvatar
                                        ? CachedNetworkImageProvider(
                                          group.avatarUrl!,
                                        )
                                        : null,
                                child:
                                    !hasAvatar
                                        ? Text(
                                          group.name[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 42,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                        : null,
                              ),
                            ),
                          ),
                        ),
                        if (isAdmin)
                          Positioned(
                            bottom: -5,
                            right: -5,
                            child: GestureDetector(
                              onTap: onChangePhoto,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: .8,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const Gap(16),
                    Text(
                      group.name,
                      textAlign: TextAlign.center,
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
                  ],
                ),
              ),
            ),
          ],
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
