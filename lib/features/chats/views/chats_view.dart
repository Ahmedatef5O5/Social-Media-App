import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/chats/cubit/chats_cubit/chats_cubit.dart';
import 'package:social_media_app/features/group_chat/cubit/group_list_cubit/group_list_cubit.dart';
import '../../../core/widgets/custom_pull_to_refresh.dart';
import '../../../core/widgets/custom_tab_wrapper.dart';
import '../../../core/widgets/global_refresh_indicator.dart';
import '../widgets/messages_header_section.dart';
import '../widgets/chats_view_body.dart';
import '../../group_chat/widgets/group_list_view_body.dart';
import 'chats_view_skeleton.dart';

class ChatsView extends StatefulWidget {
  const ChatsView({super.key});

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final ValueNotifier<double> _refreshProgress = ValueNotifier(0.0);
  final ValueNotifier<bool> _isRefreshing = ValueNotifier(false);
  final ValueNotifier<bool> isPullRefreshing = ValueNotifier(false);
  double _dragStartY = 0;
  bool _canRefresh = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      _canRefresh = _scrollController.offset <= 2;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _refreshProgress.dispose();
    _isRefreshing.dispose();
    isPullRefreshing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ChatsCubit, ChatsState>(
      builder: (context, chatsState) {
        return BlocBuilder<GroupListCubit, GroupListState>(
          builder: (context, groupsState) {
            return Stack(
              children: [
                Listener(
                  onPointerMove: (event) {
                    if (!_canRefresh) {
                      _dragStartY = 0;
                      return;
                    }
                    if (_dragStartY == 0) _dragStartY = event.position.dy;

                    final double refreshThreshold = 90.0;
                    final dy = (event.position.dy - _dragStartY).clamp(
                      0.0,
                      refreshThreshold,
                    );

                    if (dy > 0) {
                      _refreshProgress.value = (dy / refreshThreshold).clamp(
                        0.0,
                        1.0,
                      );
                    }
                  },
                  onPointerUp: (event) async {
                    if (_refreshProgress.value >= 1.0 && !_isRefreshing.value) {
                      _isRefreshing.value = true;

                      isPullRefreshing.value = true;

                      if (_tabController.index == 0) {
                        await context.read<ChatsCubit>().getChats(
                          isRefresh: true,
                        );
                      } else {
                        await context.read<GroupListCubit>().loadGroups();
                      }

                      await Future.delayed(const Duration(milliseconds: 300));

                      isPullRefreshing.value = false;
                      _isRefreshing.value = false;
                    }
                    _dragStartY = 0;
                    _refreshProgress.value = 0.0;
                  },
                  onPointerCancel: (_) {
                    _dragStartY = 0;
                    _refreshProgress.value = 0.0;
                  },

                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _tabController,
                      isPullRefreshing,
                    ]),
                    builder: (context, child) {
                      bool isLoading = false;
                      String? errorMsg;

                      if (_tabController.index == 0) {
                        final cubit = context.read<ChatsCubit>();
                        final showSkeleton =
                            (cubit.showSkeleton &&
                                chatsState is! ChatsSuccessloaded) ||
                            isPullRefreshing.value;
                        isLoading = showSkeleton;
                        errorMsg =
                            chatsState is ChatsError
                                ? chatsState.message
                                : null;
                      } else {
                        isLoading =
                            groupsState is GroupListInitial ||
                            groupsState is GroupListLoading;
                        errorMsg =
                            groupsState is GroupListError
                                ? groupsState.message
                                : null;
                      }

                      return CustomTabWrapper(
                        isLoading: isLoading,
                        loadingSkeleton: const ChatsViewSkeleton(),
                        errorMessage: errorMsg,
                        onRetry: () {
                          if (_tabController.index == 0) {
                            context.read<ChatsCubit>().getChats();
                          } else {
                            context.read<GroupListCubit>().loadGroups();
                          }
                        },
                        child: child!,
                      );
                    },

                    child: CustomPullToRefresh(
                      onRefresh: () async {
                        isPullRefreshing.value = true;

                        if (_tabController.index == 0) {
                          await context.read<ChatsCubit>().getChats(
                            isRefresh: true,
                          );
                        } else {
                          await context.read<GroupListCubit>().loadGroups(
                            isRefresh: true,
                          );
                          isPullRefreshing.value = false;
                        }
                      },

                      child: NestedScrollView(
                        controller: _scrollController,
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                          return [
                            SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  const SizedBox(height: 50),
                                  MessagesHeaderSection(
                                    tabController: _tabController,
                                    isDark: isDark,
                                    primary: primary,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ];
                        },
                        body: TabBarView(
                          controller: _tabController,
                          physics: NeverScrollableScrollPhysics(),
                          children: [ChatsViewBody(), GroupsListViewBody()],
                        ),
                      ),
                    ),
                  ),
                ),

                GlobalRefreshIndicator(
                  refreshProgress: _refreshProgress,
                  isRefreshing: _isRefreshing,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
