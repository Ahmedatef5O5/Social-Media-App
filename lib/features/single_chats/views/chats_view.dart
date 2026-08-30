import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/single_chats/cubits/chats_cubit/chats_cubit.dart';
import 'package:social_media_app/features/group_chats/cubits/group_list_cubit/group_list_cubit.dart';
import '../../../core/chat_shared/cubits/conversation_selection_cubit/conversation_selection_cubit.dart';
import '../../../core/chat_shared/cubits/conversations_cubit/conversations_cubit.dart';
import '../../../core/chat_shared/helpers/conversation_delete_confirmation.dart';
import '../../../core/chat_shared/widgets/conversations_selection_header_bar.dart';
import '../../../core/chat_shared/widgets/conversations_tab_body.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/widgets/custom_pull_to_refresh.dart';
import '../../../core/widgets/custom_tab_wrapper.dart';
import '../../../core/widgets/global_refresh_indicator.dart';
import '../../group_chats/services/group_chat_services.dart';
import '../widgets/messages_header_section.dart';
import 'chats_view_skeleton.dart';

class ChatsView extends StatefulWidget {
  final ScrollController? scrollController;
  const ChatsView({super.key, this.scrollController});

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  late final ConversationSelectionCubit _selectionCubit;
  late final ConversationsCubit _conversationsCubit;
  bool _conversationsCubitReady = false;
  final ValueNotifier<double> _refreshProgress = ValueNotifier(0.0);
  final ValueNotifier<bool> _isRefreshing = ValueNotifier(false);
  final ValueNotifier<bool> isPullRefreshing = ValueNotifier(false);
  double _dragStartY = 0;
  bool _canRefresh = true;

  static const List<ConversationTab> _tabOrder = ConversationTab.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabOrder.length, vsync: this);
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(() {
      _canRefresh = _scrollController.offset <= 2;
    });
    _selectionCubit = ConversationSelectionCubit();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _selectionCubit.clear();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(AppImages.chatBotIcon), context);

    if (!_conversationsCubitReady) {
      _conversationsCubitReady = true;
      _conversationsCubit = ConversationsCubit(
        chatsCubit: context.read<ChatsCubit>(),
        groupListCubit: context.read<GroupListCubit>(),
        groupChatServices: context.read<GroupChatServices>(),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _selectionCubit.close();
    _conversationsCubit.close();
    _refreshProgress.dispose();
    _isRefreshing.dispose();
    isPullRefreshing.dispose();
    super.dispose();
  }

  ConversationTab get _activeTab => _tabOrder[_tabController.index];
  bool get _tabNeedsChats => _activeTab != ConversationTab.groups;
  bool get _tabNeedsGroups => _activeTab != ConversationTab.chats;

  Future<void> _refreshActiveSources(BuildContext context) async {
    final futures = <Future>[];
    if (_tabNeedsChats) {
      futures.add(context.read<ChatsCubit>().getChats(isRefresh: true));
    }
    if (_tabNeedsGroups) {
      futures.add(context.read<GroupListCubit>().loadGroups(isRefresh: true));
    }
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _selectionCubit),
        BlocProvider.value(value: _conversationsCubit),
      ],
      child: BlocBuilder<ChatsCubit, ChatsState>(
        builder: (context, chatsState) {
          return BlocBuilder<GroupListCubit, GroupListState>(
            builder: (context, groupsState) {
              final chatsLoading =
                  (context.read<ChatsCubit>().showSkeleton &&
                      chatsState is! ChatsSuccessloaded) ||
                  isPullRefreshing.value;
              final groupsLoading =
                  groupsState is GroupListInitial ||
                  groupsState is GroupListLoading ||
                  isPullRefreshing.value;

              final isLoading =
                  (_tabNeedsChats && chatsLoading) ||
                  (_tabNeedsGroups && groupsLoading);

              final errorMsg =
                  (_tabNeedsChats && chatsState is ChatsError)
                      ? chatsState.message
                      : (_tabNeedsGroups && groupsState is GroupListError)
                      ? groupsState.message
                      : null;

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
                      if (_refreshProgress.value >= 1.0 &&
                          !_isRefreshing.value) {
                        _isRefreshing.value = true;
                        isPullRefreshing.value = true;

                        await _refreshActiveSources(context);

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
                        return CustomTabWrapper(
                          isLoading: isLoading,
                          loadingSkeleton: const ChatsViewSkeleton(),
                          errorMessage: errorMsg,
                          onRetry: () {
                            if (_tabNeedsChats) {
                              context.read<ChatsCubit>().getChats();
                            }
                            if (_tabNeedsGroups) {
                              context.read<GroupListCubit>().loadGroups();
                            }
                          },
                          child: child!,
                        );
                      },

                      child: CustomPullToRefresh(
                        onRefresh: () async {
                          isPullRefreshing.value = true;
                          await _refreshActiveSources(context);
                          isPullRefreshing.value = false;
                        },

                        child: NestedScrollView(
                          controller: widget.scrollController,
                          headerSliverBuilder: (context, innerBoxIsScrolled) {
                            return [
                              BlocBuilder<
                                ConversationSelectionCubit,
                                ConversationSelectionState
                              >(
                                builder: (context, selection) {
                                  final headerColumn = Column(
                                    children: [
                                      const SizedBox(height: 40),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 260,
                                        ),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        transitionBuilder: (child, animation) {
                                          final slide = Tween<Offset>(
                                            begin: const Offset(0, -0.2),
                                            end: Offset.zero,
                                          ).animate(animation);
                                          return FadeTransition(
                                            opacity: animation,
                                            child: SlideTransition(
                                              position: slide,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child:
                                            selection.isSelecting
                                                ? ConversationsSelectionHeaderBar(
                                                  key: const ValueKey(
                                                    'selection_bar',
                                                  ),
                                                  selectedRefs:
                                                      selection.selectedRefs,
                                                  onCancel:
                                                      () =>
                                                          context
                                                              .read<
                                                                ConversationSelectionCubit
                                                              >()
                                                              .clear(),
                                                  onDelete:
                                                      () =>
                                                          confirmAndDeleteConversations(
                                                            context,
                                                            selection
                                                                .selectedRefs,
                                                          ),
                                                )
                                                : MessagesHeaderSection(
                                                  key: const ValueKey(
                                                    'normal_header',
                                                  ),
                                                  tabController: _tabController,
                                                  isDark: isDark,
                                                  primary: primary,
                                                ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  );

                                  if (selection.isSelecting) {
                                    return SliverPersistentHeader(
                                      pinned: true,
                                      delegate: _PinnedChatsHeaderDelegate(
                                        height: 100,
                                        child: headerColumn,
                                      ),
                                    );
                                  }
                                  return SliverToBoxAdapter(
                                    child: headerColumn,
                                  );
                                },
                              ),
                            ];
                          },
                          body: TabBarView(
                            controller: _tabController,
                            physics: const NeverScrollableScrollPhysics(),
                            children:
                                _tabOrder
                                    .map(
                                      (tab) => ConversationsTabBody(
                                        tab: tab,
                                        tabController: _tabController,
                                      ),
                                    )
                                    .toList(),
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
      ),
    );
  }
}

class _PinnedChatsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const _PinnedChatsHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedChatsHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
