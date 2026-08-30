import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/features/group_chats/cubits/group_list_cubit/group_list_cubit.dart';
import 'package:social_media_app/features/single_chats/cubits/chats_cubit/chats_cubit.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/themes/dynamic_logo_app.dart';
import '../../../core/widgets/custom_badge.dart';
import '../../notifications/views/notification_view.dart';
import '../../search/views/search_view.dart';

class HomeViewHeaderSection extends StatefulWidget {
  final PersistentTabController navController;
  const HomeViewHeaderSection({super.key, required this.navController});

  @override
  State<HomeViewHeaderSection> createState() => _HomeViewHeaderSectionState();
}

class _HomeViewHeaderSectionState extends State<HomeViewHeaderSection> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final userId = SupabaseProvider.id;
      final data = await SupabaseProvider.client
          .from('notifications')
          .select('id')
          .eq('receiver_id', userId)
          .eq('is_read', false);
      if (mounted) setState(() => _unreadCount = (data as List).length);
    } catch (e) {
      debugPrint('[HomeHeader] failed to fetch unread notifications count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    final Color iconColor = isDark ? Colors.white : primary;

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
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                PageRouteBuilder(
                  pageBuilder: (_, animation, __) => const SearchView(),
                  transitionsBuilder: (_, anim, __, child) {
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOut),
                        ),
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 280),
                ),
              );
            },
            child: Image.asset(
              AppImages.searchIcon,
              width: 24,
              color: iconColor,
            ),
          ),
          Gap(16),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                PageRouteBuilder(
                  pageBuilder: (_, animation, __) => const NotificationsView(),

                  transitionsBuilder: (_, anim, __, child) {
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOut),
                        ),
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 280),
                ),
              );
              // refresh count after back from notification view
              _loadUnreadCount();
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  AppImages.notificationIcon,
                  width: 24,
                  color:
                      _unreadCount > 0
                          ? iconColor
                          : iconColor.withValues(alpha: isDark ? 0.6 : 0.5),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    top: -9,
                    right: -4,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Gap(16),
          InkWell(
            onTap: () {
              widget.navController.jumpToTab(2);
            },
            child: BlocBuilder<ChatsCubit, ChatsState>(
              buildWhen: (previous, current) => current is ChatsSuccessloaded,
              builder: (context, state) {
                int singleChatsUnread = 0;
                if (state is ChatsSuccessloaded) {
                  singleChatsUnread = state.chats.fold(
                    0,
                    (sum, chat) => sum + chat.unreadCount,
                  );
                }
                return BlocBuilder<GroupListCubit, GroupListState>(
                  buildWhen: (previous, current) => current is GroupListLoaded,
                  builder: (context, groupState) {
                    int groupChatsUnread = 0;
                    if (groupState is GroupListLoaded) {
                      groupChatsUnread = groupState.groups.fold(
                        0,
                        (sum, g) => sum + g.unreadCount,
                      );
                    }
                    final totalUnread = singleChatsUnread + groupChatsUnread;

                    return CustomBadge(
                      count: totalUnread,
                      top: -10.5,
                      right: -30,
                      left: 0,
                      size: 16.5,
                      child: Image.asset(
                        AppImages.paperPlaneIcon,
                        width: 24,
                        color: iconColor,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
