import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/widgets/custom_user_profile_image_section.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/profile/cubits/profile_cubit/profile_cubit.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../posts/cubit/posts_cubit/posts_cubit.dart';
import '../../single_chats/models/chat_user_model.dart';
import '../../social_graph/models/friendship_status.dart';
import '../../social_graph/widgets/animated_action_button.dart';
import '../../stories/cubit/stories_cubit/stories_cubit.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.size, required this.state});
  final Size size;
  final ProfileLoaded state;
  UserData get user => state.user;

  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseProvider.id;
    final isMe = user.id == currentUserId;
    final theme = Theme.of(context);
    final double bgHeight = MediaQuery.of(context).size.width / 1.7;

    final friendshipTopWidget =
        isMe ? null : _buildFriendshipActionWidget(context, theme);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(height: bgHeight + 100, width: double.infinity),
            CustomUserProfileImagesSection(
              aspectRatio: 1.7,
              avatarSizeFactor: 0.26,
              avatarAlignment: const Alignment(-0.85, .99),
              backgroundUrl:
                  user.backgroundImageUrl ?? AppImages.defaultBackgroundImg,
              avatarUrl: user.imageUrl ?? AppImages.defaultUserImg,
              isProfileHeader: true,
              heroTag: 'edit-profile-avatar',
              profileUserId: isMe ? currentUserId : user.id,
              showBorder: true,
            ),

            Positioned(
              right: 20,
              top: bgHeight + 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMe && friendshipTopWidget != null) ...[
                    SizedBox(width: 166, child: friendshipTopWidget),
                    const Gap(8),
                  ],
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCircularIconButton(
                        context,
                        theme: theme,
                        icon:
                            isMe
                                ? Icons.bookmark_rounded
                                : Icons.people_alt_rounded,
                        tooltip: isMe ? 'Saved Posts' : 'Friends List',
                        onPressed: () {
                          if (isMe) {
                            final postsCubit = context.read<PostsCubit>();
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushNamed(
                              AppRoutes.savedPostsViewRoute,
                              arguments: {
                                'postsCubit': postsCubit,
                                'userId': user.id,
                              },
                            );
                          } else {
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushNamed(
                              AppRoutes.friendsListViewRoute,
                              arguments: user.id,
                            );
                          }
                        },
                      ),
                      const Gap(12),
                      _buildCircularIconButton(
                        context,
                        theme: theme,
                        assetPath: AppImages.filledStoriesIcon,
                        tooltip: 'Stories',
                        onPressed: () {
                          final storiesCubit = context.read<StoriesCubit>();
                          Navigator.of(context, rootNavigator: true).pushNamed(
                            AppRoutes.userStoriesGridViewRoute,
                            arguments: {
                              'userId': user.id,
                              'authorName': user.name,
                              'storiesCubit': storiesCubit,
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (!isMe)
              Align(
                alignment: Alignment.topLeft,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.maybePop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Transform.translate(
          offset: const Offset(0, -30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                      if (user.userName != null &&
                          user.userName!.isNotEmpty) ...[
                        Text(
                          "@${user.userName?.toLowerCase().replaceAll(' ', '_')}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.grey, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 174,
                  child: _FriendsCountBadge(
                    isMe: isMe,
                    friendsCount: state.friendsCount,
                    mutualFriendsCount: state.mutualFriendsCount,
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pushNamed(
                        AppRoutes.friendsListViewRoute,
                        arguments: user.id,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Gap(size.height * 0.003),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child:
              isMe
                  ? Row(
                    children: [
                      Expanded(
                        child: CustomElevatedButton(
                          minimumSize: const Size(double.infinity, 46),
                          maximumSize: const Size(double.infinity, 46),
                          txtBtn: 'Edit Profile',
                          txtBtnStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: theme.primaryColor,
                          ),
                          prefixIcon: Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: theme.primaryColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: AppColors.grey3, width: 1.3),
                          elevation: 0,
                          bgColor: theme.colorScheme.surface,
                          onPressed: () async {
                            final profileCubit = context.read<ProfileCubit>();
                            await Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushNamed(
                              AppRoutes.editProfileViewRoute,
                              arguments: user,
                            );
                            if (context.mounted) {
                              profileCubit.getProfileData(user.id);
                            }
                          },
                        ),
                      ),
                      const Gap(10),
                      _buildCircularIconButton(
                        context,
                        theme: theme,
                        icon: Icons.people_alt_rounded,
                        tooltip: 'Friends List',
                        size: 46,
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pushNamed(
                            AppRoutes.friendsListViewRoute,
                            arguments: user.id,
                          );
                        },
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      Expanded(
                        child: AnimatedActionButton(
                          height: 46,
                          isActive: state.isFollowing,
                          idleLabel: 'Follow',
                          activeLabel: 'Following',
                          idleIcon: Icons.person_add_rounded,
                          activeIcon: Icons.check_rounded,
                          onPressed: () async {
                            await context.read<ProfileCubit>().toggleFollow();
                          },
                        ),
                      ),
                      const Gap(10),
                      _buildCircularIconButton(
                        context,
                        theme: theme,
                        icon: Icons.message_rounded,
                        tooltip: 'Send message',
                        size: 46,
                        onPressed: () {
                          final chatUser = ChatUserModel(
                            id: user.id,
                            name: user.name,
                            imageUrl: user.imageUrl,
                            lastSeen: user.lastSeen,
                          );
                          Navigator.of(context, rootNavigator: true).pushNamed(
                            AppRoutes.chatDetailsViewRoute,
                            arguments: chatUser,
                          );
                        },
                      ),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget? _buildFriendshipActionWidget(BuildContext context, ThemeData theme) {
    final cubit = context.read<ProfileCubit>();

    switch (state.friendshipStatus) {
      case FriendshipStatus.none:
        return AnimatedActionButton(
          height: 42,
          isActive: false,
          idleLabel: 'Add friend',
          activeLabel: 'Requested',
          idleIcon: Icons.person_add_alt_1_rounded,
          activeIcon: Icons.hourglass_top_rounded,
          onPressed: () => cubit.sendFriendRequest(),
        );
      case FriendshipStatus.pendingSent:
        return AnimatedActionButton(
          height: 42,
          isActive: true,
          idleLabel: 'Add friend',
          activeLabel: 'Requested',
          idleIcon: Icons.person_add_alt_1_rounded,
          activeIcon: Icons.hourglass_top_rounded,
          onPressed: () => cubit.cancelFriendRequest(),
        );
      case FriendshipStatus.pendingReceived:
        return _buildSmallActionButton(
          context,
          label: 'Accept',
          txtColor: Colors.white,
          bgColor: theme.primaryColor,
          iconWidget: const Icon(
            Icons.person_add_alt_1_rounded,
            size: 18,
            color: Colors.white,
          ),
          onPressed: () {
            cubit.acceptFriendRequest();
          },
        );
      case FriendshipStatus.accepted:
        return null;
    }
  }

  Widget _buildSmallActionButton(
    BuildContext context, {
    required String label,
    required Widget iconWidget,
    required VoidCallback onPressed,
    TextStyle? txtBtnStyle,
    Color? txtColor,
    BorderSide? side,
    bgColor,
  }) {
    return CustomElevatedButton(
      txtBtn: label,
      onPressed: onPressed,
      maximumSize: const Size(double.infinity, 42),
      minimumSize: const Size(double.infinity, 42),
      txtColor: txtColor,
      txtBtnStyle:
          txtBtnStyle ??
          TextStyle(
            color: txtColor ?? Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
      bgColor: bgColor,
      side: side,
      elevation: 1.1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      prefixIcon: iconWidget,
    );
  }

  Widget _buildCircularIconButton(
    BuildContext context, {
    required ThemeData theme,
    IconData? icon,
    String? assetPath,
    required VoidCallback onPressed,
    String? tooltip,
    double size = 44,
  }) {
    return _CircularIconButton(
      theme: theme,
      icon: icon,
      assetPath: assetPath,
      onPressed: onPressed,
      tooltip: tooltip,
      size: size,
    );
  }
}

class _CircularIconButton extends StatefulWidget {
  final ThemeData theme;
  final IconData? icon;
  final String? assetPath;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;

  const _CircularIconButton({
    required this.theme,
    this.icon,
    this.assetPath,
    required this.onPressed,
    required this.size,
    this.tooltip,
  });

  @override
  State<_CircularIconButton> createState() => _CircularIconButtonState();
}

class _CircularIconButtonState extends State<_CircularIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return AnimatedScale(
      scale: _pressed ? 0.9 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.99),
        shape: CircleBorder(
          side: BorderSide(
            color:
                theme.brightness != Brightness.light
                    ? theme.primaryColor.withValues(alpha: 0.65)
                    : AppColors.grey3,
            width: 1,
          ),
        ),
        elevation: 1.1,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child:
                  widget.assetPath != null
                      ? Image.asset(
                        widget.assetPath!,
                        width: widget.size * 0.43,
                        height: widget.size * 0.43,
                        color: theme.primaryColor,
                      )
                      : Icon(
                        widget.icon,
                        color: theme.primaryColor,
                        size: widget.size * 0.43,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendsCountBadge extends StatelessWidget {
  final bool isMe;
  final int friendsCount;
  final int mutualFriendsCount;
  final VoidCallback onTap;

  const _FriendsCountBadge({
    required this.isMe,
    required this.friendsCount,
    required this.mutualFriendsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showMutual = !isMe && mutualFriendsCount > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$friendsCount ${friendsCount == 1 ? 'Friend' : 'Friends'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (showMutual) ...[
              const SizedBox(height: 2),
              Text(
                '$mutualFriendsCount Mutual',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: AppColors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
