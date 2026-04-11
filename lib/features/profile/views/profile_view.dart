import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/widgets/custom_back_to_top_btn.dart';
import 'package:social_media_app/features/profile/cubits/profile_cubit/profile_cubit.dart';
import 'package:social_media_app/features/profile/widgets/profile_body_content.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../home/cubit/home_cubit.dart';
import '../widgets/profile_refresh_indicator.dart';

class ProfileView extends StatefulWidget {
  final String? userId;
  const ProfileView({super.key, this.userId});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final currentUserId = Supabase.instance.client.auth.currentUser!.id;
  late ScrollController _scrollController;
  final ValueNotifier<double> _refreshProgress = ValueNotifier(0.0);
  final ValueNotifier<bool> _isRefreshing = ValueNotifier(false);
  bool _showBackToTop = false;
  bool _isRefreshingManual = false;
  double _dragStartY = 0;
  bool _canRefresh = false;
  double _lastOffset = 0;
  bool _isScrollingToTop = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();

    _scrollController = ScrollController();

    _canRefresh = true;
    _scrollController.addListener(() {
      _canRefresh = _scrollController.offset <= 2;
    });
  }

  void _loadProfileData() {
    final effectiveId = widget.userId ?? currentUserId;
    context.read<ProfileCubit>().getProfileData(effectiveId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() async {
    _isScrollingToTop = true;

    setState(() {
      _showBackToTop = false;
    });

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );

    _lastOffset = 0;
    _isScrollingToTop = false;
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser =
        widget.userId == null || widget.userId == currentUserId;
    final size = MediaQuery.sizeOf(context);
    final profileCubit = context.read<ProfileCubit>();
    final homeCubit = context.read<HomeCubit>();
    return Stack(
      children: [
        Listener(
          onPointerMove: (event) {
            if (!_canRefresh) {
              _dragStartY = 0;
              return;
            }
            if (_dragStartY == 0) _dragStartY = event.position.dy;

            final dy = (event.position.dy - _dragStartY).clamp(0, 150);
            if (dy > 0) {
              final progress = (dy / 150).clamp(0.0, 1.0);
              _refreshProgress.value = progress;
            }
          },
          onPointerUp: (event) async {
            if (_refreshProgress.value >= 1.0 && !_isRefreshingManual) {
              _isRefreshingManual = true;
              _isRefreshing.value = true;

              final state = context.read<ProfileCubit>().state;
              if (state is ProfileLoaded) {
                await Future.wait([
                  profileCubit.getProfileData(state.user.id, isRefresh: true),
                  homeCubit.fetchPosts(isRefresh: true),
                ]);

                await Future.delayed(const Duration(milliseconds: 300));
              }

              _isRefreshingManual = false;
              _isRefreshing.value = false;
            }

            _dragStartY = 0;
            _refreshProgress.value = 0.0;
          },
          onPointerCancel: (_) {
            _dragStartY = 0;
            _refreshProgress.value = 0.0;
            _isRefreshing.value = false;
          },
          child: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoading) {
                return CustomLoadingIndicator();
              } else if (state is ProfileLoaded) {
                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (_isScrollingToTop) return false;

                    if (notification is ScrollUpdateNotification) {
                      final metrics = notification.metrics;
                      double currentOffset = metrics.pixels;

                      bool isScrollingUp = currentOffset < _lastOffset;

                      if (currentOffset > 450 && isScrollingUp) {
                        if (!_showBackToTop) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && !_showBackToTop) {
                              setState(() => _showBackToTop = true);
                            }
                          });
                        }
                      } else if (!isScrollingUp || currentOffset < 10) {
                        if (_showBackToTop) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _showBackToTop) {
                              setState(() => _showBackToTop = false);
                            }
                          });
                        }
                      }

                      _lastOffset = currentOffset;
                    }
                    return false;
                  },
                  child: ProfileBodyContent(
                    state: state,
                    scrollController: _scrollController,
                    size: size,
                    refreshProgress: _refreshProgress,
                    isRefreshing: _isRefreshing,
                    homeCubit: homeCubit,
                    isCurrentUser: isCurrentUser,
                  ),
                );
              } else if (state is ProfileError) {
                return Center(child: Text(state.message));
              } else {
                return SizedBox.shrink();
              }
            },
          ),
        ),

        CustomBackToTopBtn(isVisible: _showBackToTop, onTap: _scrollToTop),

        ProfileRefreshIndicator(
          refreshProgress: _refreshProgress,
          isRefreshing: _isRefreshing,
        ),
      ],
    );
  }
}
