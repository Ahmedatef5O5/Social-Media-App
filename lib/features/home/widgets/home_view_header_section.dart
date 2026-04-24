import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/features/chats/cubit/chats_cubit/chats_cubit.dart';
import '../../../core/themes/dynamic_logo_app.dart';
import '../../../core/widgets/custom_badge.dart';

class HomeViewHeaderSection extends StatelessWidget {
  final PersistentTabController navController;
  const HomeViewHeaderSection({super.key, required this.navController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            height: 25,
            width: 160,
            child: DynamicHeaderLogo(height: 25),
          ),
          Spacer(),
          InkWell(
            onTap: () {},
            child: Image.asset(
              AppImages.searchIcon,
              width: 24,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Gap(16),
          InkWell(
            onTap: () {},
            child: Image.asset(
              AppImages.notificationIcon,
              width: 24,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Gap(16),
          InkWell(
            onTap: () {
              navController.jumpToTab(2);
            },
            child: BlocBuilder<ChatsCubit, ChatsState>(
              buildWhen: (previous, current) => current is ChatsSuccessloaded,
              builder: (context, state) {
                int totalUnread = 0;
                if (state is ChatsSuccessloaded) {
                  totalUnread = state.chats.fold(
                    0,
                    (sum, chat) => sum + chat.unreadCount,
                  );
                }
                return CustomBadge(
                  count: totalUnread,
                  top: -10.5,
                  right: -30,
                  left: 0,
                  size: 16.5,
                  // fontSize: 9,
                  child: Image.asset(
                    AppImages.paperPlaneIcon,
                    width: 24,
                    color: Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
