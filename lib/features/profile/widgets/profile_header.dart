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
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../posts/cubit/posts_cubit/posts_cubit.dart';
import '../../single_chats/models/chat_user_model.dart';
import '../../social_graph/models/friendship_status.dart';

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
            ),

            if (!isMe)
              Positioned(
                right: 20,
                top: bgHeight + 10,
                child: SizedBox(
                  width: 166,
                  child: Column(
                    children: [
                      _buildSmallActionButton(
                        context,
                        label: switch (state.friendshipStatus) {
                          FriendshipStatus.none => 'Add friend',
                          FriendshipStatus.pendingSent => 'Cancel request',
                          FriendshipStatus.pendingReceived => 'Respond',
                          FriendshipStatus.accepted => 'Friends',
                        },
                        txtColor: theme.scaffoldBackgroundColor,
                        iconWidget: Image.asset(
                          AppImages.addUserIcon,
                          width: 18,
                          height: 20,
                          color: theme.scaffoldBackgroundColor,
                        ),
                        onPressed: () async {
                          final cubit = context.read<ProfileCubit>();
                          switch (state.friendshipStatus) {
                            case FriendshipStatus.none:
                              await cubit.sendFriendRequest();
                              break;
                            case FriendshipStatus.pendingSent:
                              await cubit.cancelFriendRequest();
                              break;
                            case FriendshipStatus.pendingReceived:
                              AppToast.info(
                                'Check your notifications to respond to this request',
                              );
                              break;
                            case FriendshipStatus.accepted:
                              break;
                          }
                        },
                      ),

                      const Gap(8),
                      _buildSmallActionButton(
                        context,
                        label: 'Send message',
                        txtColor: Theme.of(context).primaryColor,
                        bgColor: Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withValues(alpha: 0.99),
                        side: BorderSide(
                          color:
                              Theme.of(context).brightness != Brightness.light
                                  ? Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.65)
                                  : Colors.transparent,
                          width: 1,
                        ),
                        iconWidget: Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 2),
                          child: Icon(
                            Icons.message_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 19,
                          ),
                        ),
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
              ),
            if (!isMe)
              Align(
                alignment: Alignment.topLeft,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
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

            if (isMe)
              Positioned(
                right: 20,
                top: bgHeight + 10,
                child: SizedBox(
                  width: 164,
                  child: Column(
                    children: [
                      _buildSmallActionButton(
                        context,
                        label: 'Friends List',
                        txtColor: theme.primaryColor,
                        bgColor: theme.scaffoldBackgroundColor.withValues(
                          alpha: 0.99,
                        ),
                        side: BorderSide(
                          color:
                              theme.brightness != Brightness.light
                                  ? theme.primaryColor.withValues(alpha: 0.65)
                                  : AppColors.grey3,
                          width: 1,
                        ),
                        iconWidget: Icon(
                          Icons.people_alt_rounded,
                          color: theme.primaryColor,
                          size: 19,
                        ),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pushNamed(
                            AppRoutes.friendsListViewRoute,
                            arguments: user.id,
                          );
                          // AppToast.info('this feature is coming soon');
                        },
                      ),
                      const Gap(8),
                      _buildSmallActionButton(
                        context,
                        label: 'Saved Posts',
                        txtColor: theme.primaryColor,
                        bgColor: theme.scaffoldBackgroundColor.withValues(
                          alpha: 0.99,
                        ),
                        side: BorderSide(
                          color:
                              theme.brightness != Brightness.light
                                  ? theme.primaryColor.withValues(alpha: 0.65)
                                  : AppColors.grey3,
                          width: 1,
                        ),
                        iconWidget: Icon(
                          Icons.bookmark_rounded,
                          color: theme.primaryColor,
                          size: 18,
                        ),
                        onPressed: () {
                          final postsCubit = context.read<PostsCubit>();
                          Navigator.of(context, rootNavigator: true).pushNamed(
                            AppRoutes.savedPostsViewRoute,
                            arguments: {
                              'postsCubit': postsCubit,
                              'userId': user.id,
                            },
                          );
                        },
                      ),
                    ],
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
                const SizedBox(width: 174),
              ],
            ),
          ),
        ),
        Gap(size.height * 0.003),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomElevatedButton(
            minimumSize: const Size(double.infinity, 46),
            maximumSize: const Size(double.infinity, 46),
            txtBtn:
                isMe
                    ? 'Edit Profile'
                    : (state.isFollowing ? 'Following' : 'Follow'),
            txtBtnStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: isMe ? theme.primaryColor : Colors.white,
            ),
            prefixIcon:
                isMe
                    ? Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: theme.primaryColor,
                    )
                    : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: isMe ? BorderSide(color: AppColors.grey3, width: 1.3) : null,
            elevation: 0,
            bgColor: isMe ? theme.colorScheme.surface : theme.primaryColor,

            onPressed: () async {
              if (isMe) {
                final profileCubit = context.read<ProfileCubit>();
                await Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed(AppRoutes.editProfileViewRoute, arguments: user);
                if (context.mounted) {
                  profileCubit.getProfileData(user.id);
                }
              } else {
                await context.read<ProfileCubit>().toggleFollow();
              }
            },
          ),
        ),
      ],
    );
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
