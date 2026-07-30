import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/presence/widgets/presence_avatar_widget.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/widgets/main_user_avatar.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import '../cubit/posts_cubit/posts_cubit.dart';

class PostWritingCard extends StatelessWidget {
  const PostWritingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final screenSize = MediaQuery.sizeOf(context);
    final isSmallScreen = screenSize.width < 360;

    void navigatorToPost() =>
        Navigator.of(context, rootNavigator: true).pushNamed(
          AppRoutes.createPostViewRoute,
          arguments: context.read<PostsCubit>(),
        );

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final homeCubit = context.read<HomeCubit>();
        final user = homeCubit.currentUserData;
        final displayImage = user?.imageUrl;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
          child: InkWell(
            onTap: navigatorToPost,
            borderRadius: BorderRadius.circular(24),
            splashColor: theme.primaryColor.withValues(alpha: 0.1),
            highlightColor: theme.primaryColor.withValues(alpha: 0.05),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        theme.brightness == Brightness.dark
                            ? Colors.black.withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  isSmallScreen ? 18 : 20,
                  16,
                  isSmallScreen ? 18 : 20,
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: 'user-avatar-hero',
                      child: Container(
                        padding: const EdgeInsets.all(0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.15),
                            width: 3.5,
                          ),
                        ),
                        child: PresenceAvatarWidget(
                          userId: user!.id,
                          avatarSize: isSmallScreen ? 26 : 35,
                          showDot: false,
                          showBorder: false,
                          child: MainUserAvatar(
                            imageUrl: displayImage,
                            size: isSmallScreen ? 26 : 35,
                            showBorder: false,
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        'What\'s on your mind?',
                        style: theme.textTheme.titleMedium!.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                          fontWeight: FontWeight.w500,
                          fontSize: isSmallScreen ? 14 : 15,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Gap(8),

                    const _AnimatedActionCluster(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedActionCluster extends StatefulWidget {
  const _AnimatedActionCluster();

  @override
  State<_AnimatedActionCluster> createState() => _AnimatedActionClusterState();
}

class _AnimatedActionClusterState extends State<_AnimatedActionCluster>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<double> _scale1;
  late Animation<double> _scale2;
  late Animation<double> _scale3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat();

    _rotation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeInOutQuart),
      ),
    );

    _scale1 = _buildScaleSequence(0.55, 0.70);
    _scale2 = _buildScaleSequence(0.70, 0.85);
    _scale3 = _buildScaleSequence(0.85, 1.00);
  }

  Animation<double> _buildScaleSequence(double start, double end) {
    return TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.35,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.35,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Interval(start, end)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(-10.4, 6.0),
                  child: Transform.scale(
                    scale: _scale3.value,
                    child: Transform.rotate(
                      angle: -_rotation.value,
                      child: _MiniIcon(
                        icon: Icons.attach_file_rounded,
                        color: Colors.orange.shade500,
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(10.4, 6.0),
                  child: Transform.scale(
                    scale: _scale2.value,
                    child: Transform.rotate(
                      angle: -_rotation.value,
                      child: _MiniIcon(
                        icon: Icons.videocam_rounded,
                        color: Colors.blue.shade500,
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -12.0),
                  child: Transform.scale(
                    scale: _scale1.value,
                    child: Transform.rotate(
                      angle: -_rotation.value,
                      child: _MiniIcon(
                        icon: Icons.image_rounded,
                        color: Colors.green.shade500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MiniIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(5.5),
      decoration: BoxDecoration(
        color:
            isDark
                ? color.withValues(alpha: 0.18)
                : color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color:
              isDark
                  ? color.withValues(alpha: 0.4)
                  : color.withValues(alpha: 0.3),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(icon, size: 8.5, color: color),
    );
  }
}
