import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/widgets/custom_user_profile_image_section.dart';
import 'package:social_media_app/features/auth/data/models/user_data.dart';
import 'package:social_media_app/features/profile/cubits/profile_cubit/profile_cubit.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../posts/cubits/posts_cubit/posts_cubit.dart';
import '../../single_chats/models/chat_user_model.dart';
import '../../social_graph/models/friendship_status.dart';
import '../../social_graph/widgets/unfriend_confirmation_dialog.dart';
import '../../stories/cubits/stories_cubit/stories_cubit.dart';
import '../utils/circular_icon_button.dart';
import '../utils/profile_action_button.dart';
import '../utils/profile_animated_action_button.dart';
import '../utils/profile_header_back_btn_container.dart';
import '../utils/profile_ui_tokens.dart';
import 'profile_header_user_info_section.dart';

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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double bgHeight = screenWidth / 1.7;
    final double avatarSize = screenWidth * 0.26;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: bgHeight + avatarSize / 2 + 12,
              width: double.infinity,
            ),

            // ── Cover + avatar (unchanged) ──
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
              right: ProfileUiTokens.screenPadding,
              top:
                  bgHeight +
                  avatarSize / 2 -
                  ProfileUiTokens.iconButtonSize -
                  8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCircularIconButton(
                    theme: theme,
                    icon:
                        isMe
                            ? Icons.bookmark_outline_outlined
                            : Icons.people_alt_outlined,
                    tooltip: isMe ? 'Saved Posts' : 'Friends List',
                    onPressed: () {
                      if (isMe) {
                        final postsCubit = context.read<PostsCubit>();
                        Navigator.of(context, rootNavigator: true).pushNamed(
                          AppRoutes.savedPostsViewRoute,
                          arguments: {
                            'postsCubit': postsCubit,
                            'userId': user.id,
                          },
                        );
                      } else {
                        _openFriendsList(context);
                      }
                    },
                  ),
                  const Gap(8),
                  _buildCircularIconButton(
                    theme: theme,
                    assetPath: AppImages.storyIcon,
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
            ),

            if (!isMe) ProfileHeaderBackBtnContainer(),
          ],
        ),

        ProfileHeaderUserInfoSection(user: user, isMe: isMe, state: state),
        const Gap(16),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ProfileUiTokens.screenPadding,
          ),
          child:
              isMe
                  ? _buildMyProfileActions(context)
                  : _buildOtherProfileActions(context),
        ),
      ],
    );
  }

  // ───────────────────────── My profile ─────────────────────────

  Widget _buildMyProfileActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ProfileActionButton(
            label: 'Edit Profile',
            icon: Icons.edit_rounded,
            style: ProfileActionStyle.outlinePrimary,
            onPressed: () async {
              final profileCubit = context.read<ProfileCubit>();
              await Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed(AppRoutes.editProfileViewRoute, arguments: user);
              if (context.mounted) {
                profileCubit.getProfileData(user.id);
              }
            },
          ),
        ),
        const Gap(8),
        ProfileSquareIconButton(
          icon: Icons.people_alt_outlined,
          tooltip: 'Friends List',
          onPressed: () => _openFriendsList(context),
        ),
      ],
    );
  }

  // ───────────────────────── Other user ─────────────────────────

  Widget _buildOtherProfileActions(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    final isPendingReceived =
        state.friendshipStatus == FriendshipStatus.pendingReceived;

    return Row(
      children: [
        Expanded(child: _buildFriendshipButton(context, cubit)),
        if (isPendingReceived) ...[
          const Gap(8),
          ProfileSquareIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Decline request',
            iconColor: ProfileUiTokens.of(context).onSurfaceVariant,
            onPressed: () => cubit.declineFriendRequest(),
          ),
        ],
        const Gap(8),
        ProfileAnimatedActionButton(
          width: 112,
          isActive: state.isFollowing,
          idleLabel: 'Follow',
          activeLabel: 'Following',
          idleIcon: Icons.add_rounded,
          activeIcon: Icons.check_rounded,
          idleStyle: ProfileActionStyle.outlineAccent,
          activeStyle: ProfileActionStyle.neutral,
          onPressed: cubit.toggleFollow,
        ),
        const Gap(8),
        ProfileSquareIconButton(
          icon: Icons.message_outlined,
          tooltip: 'Send message',
          onPressed: () {
            final chatUser = ChatUserModel(
              id: user.id,
              name: user.name,
              imageUrl: user.imageUrl,
              lastSeen: user.lastSeen,
            );
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamed(AppRoutes.chatDetailsViewRoute, arguments: chatUser);
          },
        ),
      ],
    );
  }

  Widget _buildFriendshipButton(BuildContext context, ProfileCubit cubit) {
    switch (state.friendshipStatus) {
      case FriendshipStatus.none:
      case FriendshipStatus.pendingSent:
        final isRequested =
            state.friendshipStatus == FriendshipStatus.pendingSent;
        return ProfileAnimatedActionButton(
          key: const ValueKey('friendship-request-button'),
          isActive: isRequested,
          idleLabel: 'Add Friend',
          activeLabel: 'Requested',
          idleIcon: Icons.person_add_alt_1_rounded,
          activeIcon: Icons.hourglass_top_rounded,
          idleStyle: ProfileActionStyle.primary,
          activeStyle: ProfileActionStyle.outlineMuted,
          onPressed:
              () =>
                  isRequested
                      ? cubit.cancelFriendRequest()
                      : cubit.sendFriendRequest(),
        );
      case FriendshipStatus.pendingReceived:
        return ProfileActionButton(
          label: 'Accept',
          icon: Icons.check_rounded,
          style: ProfileActionStyle.primary,
          onPressed: () => cubit.acceptFriendRequest(),
        );
      case FriendshipStatus.accepted:
        return ProfileActionButton(
          label: 'Friends',
          icon: Icons.check_rounded,
          style: ProfileActionStyle.tonal,
          onPressed: () => _confirmUnfriend(context, cubit),
        );
    }
  }

  Future<void> _confirmUnfriend(
    BuildContext context,
    ProfileCubit cubit,
  ) async {
    final confirmed = await showUnfriendConfirmationDialog(
      context,
      friendName: user.name,
    );
    if (confirmed == true) {
      await cubit.unfriend();
    }
  }

  void _openFriendsList(BuildContext context) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.friendsListViewRoute, arguments: user.id);
  }

  Widget _buildCircularIconButton({
    required ThemeData theme,
    IconData? icon,
    String? assetPath,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return CircularIconButton(
      theme: theme,
      icon: icon,
      assetPath: assetPath,
      onPressed: onPressed,
      tooltip: tooltip,
      size: ProfileUiTokens.iconButtonSize,
    );
  }
}
