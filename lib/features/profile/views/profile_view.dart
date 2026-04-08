import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_back_to_top_btn.dart';
import 'package:social_media_app/features/profile/cubits/profile_cubit/profile_cubit.dart';
import 'package:social_media_app/features/profile/widgets/profile_body_content.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../home/cubit/home_cubit.dart';
import '../widgets/profile_refresh_indicator.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late ScrollController _scrollController;
  final ValueNotifier<double> _refreshProgress = ValueNotifier(0.0);
  final ValueNotifier<bool> _isRefreshing = ValueNotifier(false);
  bool _showBackToTop = false;
  bool _isRefreshingManual = false;
  double _dragStartY = 0;
  bool _canRefresh = false;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _canRefresh = true;
    _scrollController.addListener(() {
      _canRefresh = _scrollController.offset <= 2;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    setState(() {
      _showBackToTop = false;
    });
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final profileCubit = context.read<ProfileCubit>();
    final homeCubit = context.read<HomeCubit>();
    return BackgroundThemeWidget(
      top: false,
      child: Stack(
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
                      if (notification is ScrollUpdateNotification) {
                        final metrics = notification.metrics;
                        double currentOffset = metrics.pixels;

                        bool isScrollingUp = currentOffset < _lastOffset;

                        if (currentOffset > 450 && isScrollingUp) {
                          if (!_showBackToTop) {
                            setState(() => _showBackToTop = true);
                          }
                        } else {
                          if (_showBackToTop) {
                            setState(() => _showBackToTop = false);
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
      ),
    );
  }
}
