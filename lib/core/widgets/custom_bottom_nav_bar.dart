import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:social_media_app/core/themes/cubits/theme_cubit.dart';
import 'package:social_media_app/core/widgets/custom_confirmation_dialog.dart';
import 'package:social_media_app/core/widgets/main_user_avatar.dart';
import 'package:social_media_app/features/single_chats/cubits/chats_cubit/chats_cubit.dart';
import 'package:social_media_app/features/single_chats/views/chats_view.dart';
import 'package:social_media_app/features/discover/views/discover_view.dart';
import 'package:social_media_app/features/profile/services/user_services.dart';
import 'package:social_media_app/features/profile/views/profile_view.dart';
import 'package:social_media_app/features/settings/widgets/profile_drawer.dart';
import '../../features/group_chats/cubits/group_list_cubit/group_list_cubit.dart';
import '../../features/home/cubits/home_cubit/home_cubit.dart';
import '../../features/home/views/home_view.dart';
import '../../features/profile/cubits/profile_cubit/profile_cubit.dart';
import '../../features/social_graph/services/follow_services.dart';
import '../../features/social_graph/services/friendship_services.dart';
import '../connectivity/cubits/connectivity_cubit.dart';
import '../connectivity/cubits/connectivity_state.dart';
import '../connectivity/services/connectivity_banner_controller.dart';
import '../constants/app_images.dart';
import '../supabase/supabase_provider.dart';
import '../router/main_tab_bridge.dart';
import 'custom_floating_nav_bar.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late PersistentTabController _controller;

  final List<ScrollController> _scrollControllers = [
    ScrollController(), // for Home
    ScrollController(), // for Discover
    ScrollController(), // for Chats
    ScrollController(), // for Profile
  ];

  StreamSubscription<ChatsState>? _chatsSub;
  StreamSubscription<GroupListState>? _groupListSub;
  StreamSubscription<int>? _tabRequestSub;

  bool _chatsReady = false;
  bool _groupsReady = false;
  int _singleChatsUnread = 0;
  int _groupChatsUnread = 0;

  int? get _combinedUnreadCount {
    if (!_chatsReady || !_groupsReady) return null;
    return _singleChatsUnread + _groupChatsUnread;
  }

  void _listenForUnreadCounts() {
    final chatsCubit = context.read<ChatsCubit>();
    final groupListCubit = context.read<GroupListCubit>();

    _applyChatsState(chatsCubit.state);
    _applyGroupListState(groupListCubit.state);

    _chatsSub = chatsCubit.stream.listen(_applyChatsState);
    _groupListSub = groupListCubit.stream.listen(_applyGroupListState);
  }

  void _applyChatsState(ChatsState state) {
    if (state is! ChatsSuccessloaded) return;
    final unread = state.chats.fold<int>(0, (s, c) => s + c.unreadCount);
    if (!mounted) return;
    setState(() {
      _singleChatsUnread = unread;
      _chatsReady = true;
    });
  }

  void _applyGroupListState(GroupListState state) {
    if (state is! GroupListLoaded) return;
    final unread = state.groups.fold<int>(0, (s, g) => s + g.unreadCount);
    if (!mounted) return;
    setState(() {
      _groupChatsUnread = unread;
      _groupsReady = true;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isOffline =
          context.read<ConnectivityCubit>().state is ConnectivityOffline;
      if (isOffline) {
        ConnectivityBannerController.notifyBlockedByOffline();
      }
    });
    _controller = PersistentTabController(initialIndex: 0);
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _listenForUnreadCounts();

    _tabRequestSub = MainTabBridge.instance.requests.listen((tabIndex) {
      if (!mounted) return;
      if (tabIndex < 0 || tabIndex > 3) return;
      _controller.jumpToTab(tabIndex);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    _chatsSub?.cancel();
    _groupListSub?.cancel();
    _tabRequestSub?.cancel();
    super.dispose();
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => CustomConfirmationDialog(
            title: 'Are you sure you want to quit ?',
            img: AppImages.exitAnimationLot,

            onConfirm:
                () => Navigator.of(context, rootNavigator: true).pop(true),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = SupabaseProvider.idOrNull;
    if (userId == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final currentTheme = themeState.theme;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
              _scaffoldKey.currentState?.closeEndDrawer();
              return;
            }
            if (Navigator.of(context, rootNavigator: true).canPop()) return;

            if (_controller.index != 0) {
              _controller.jumpToTab(0);
              return;
            }
            bool shouldExit =
                await _showExitConfirmationDialog(context) ?? false;
            if (shouldExit == true) {
              await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            }
          },
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create:
                    (context) => ProfileCubit(
                      context.read<UserService>(),
                      friendshipServices: context.read<FriendshipServices>(),
                      followServices: context.read<FollowServices>(),
                      homeCubit: context.read<HomeCubit>(),
                      connectivityCubit: context.read<ConnectivityCubit>(),
                    )..getProfileData(userId),
              ),
            ],
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: (currentTheme.isDark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark)
                  .copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: currentTheme.bgBase,
                    systemNavigationBarIconBrightness:
                        currentTheme.isDark
                            ? Brightness.light
                            : Brightness.dark,
                  ),
              child: Scaffold(
                backgroundColor: currentTheme.bgBase,
                key: _scaffoldKey,
                extendBody: true,
                endDrawer: ProfileDrawer(navController: _controller),
                body: Stack(
                  children: [
                    PersistentTabView(
                      backgroundColor: Colors.transparent,
                      controller: _controller,
                      gestureNavigationEnabled: true,
                      handleAndroidBackButtonPress: false,
                      selectedTabPressConfig: const SelectedTabPressConfig(
                        popAction: PopActionType.all,
                      ),
                      navBarBuilder: (config) => const SizedBox.shrink(),
                      tabs: [
                        PersistentTabConfig(
                          screen: HomeView(
                            navController: _controller,
                            scrollController: _scrollControllers[0],
                          ),
                          item: ItemConfig(icon: const Icon(Icons.home)),
                        ),
                        PersistentTabConfig(
                          screen: DiscoverView(
                            scrollController: _scrollControllers[1],
                          ),
                          item: ItemConfig(icon: const Icon(Icons.group)),
                        ),
                        PersistentTabConfig(
                          screen: ChatsView(
                            scrollController: _scrollControllers[2],
                          ),
                          item: ItemConfig(icon: const Icon(Icons.chat)),
                        ),
                        PersistentTabConfig(
                          screen: ProfileView(
                            scrollController: _scrollControllers[3],
                          ),
                          item: ItemConfig(icon: const Icon(Icons.person)),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 8,
                      child: Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.92,
                          child: BlocBuilder<ProfileCubit, ProfileState>(
                            builder: (context, profileState) {
                              String? imageUrl;
                              if (profileState is ProfileLoaded) {
                                imageUrl = profileState.user.imageUrl;
                              }
                              return CustomFloatingNavBar(
                                currentIndex: _controller.index,
                                onTap: (i) {
                                  if (_controller.index == i) {
                                    if (_scrollControllers[i].hasClients) {
                                      _scrollControllers[i].animateTo(
                                        0.0,
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.easeOutBack,
                                      );
                                    }
                                  } else {
                                    _controller.jumpToTab(i);
                                  }
                                  if (i == 3) {
                                    _scaffoldKey.currentState!.openEndDrawer();
                                  }
                                  setState(() {});
                                },
                                items: [
                                  const NavBarItem(icon: Icons.home_outlined),
                                  const NavBarItem(icon: Icons.group_outlined),
                                  NavBarItem(
                                    icon: Icons.chat_bubble_outline,
                                    badgeCount: _combinedUnreadCount ?? 0,
                                  ),
                                  NavBarItem(
                                    child: MainUserAvatar(
                                      userId: userId,
                                      imageUrl: imageUrl,
                                      showBorder: false,
                                      size: 30,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
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
