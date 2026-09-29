import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/widgets/custom_back_to_top_btn.dart';
import 'package:social_media_app/core/widgets/custom_tab_wrapper.dart';
import 'package:social_media_app/features/profile/cubits/profile_cubit/profile_cubit.dart';
import 'package:social_media_app/features/profile/views/profile_shimmer_view.dart';
import 'package:social_media_app/features/profile/widgets/profile_body_content.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/widgets/global_refresh_indicator.dart';
import '../../posts/cubits/posts_cubit/posts_cubit.dart';
import '../cubits/profile_posts_cubit/profile_posts_cubit.dart';

class ProfileView extends StatefulWidget {
  final String? userId;
  final ScrollController? scrollController;
  const ProfileView({super.key, this.userId, this.scrollController});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String? get currentUserId => SupabaseProvider.idOrNull;

  late ScrollController _scrollController;
  final ValueNotifier<double> _refreshProgress = ValueNotifier(0.0);
  final ValueNotifier<bool> _isRefreshing = ValueNotifier(false);
  final ValueNotifier<double> _statusBarScrimProgress = ValueNotifier(0.0);
  bool _showBackToTop = false;
  bool _isRefreshingManual = false;
  double _dragStartY = 0;
  bool _canRefresh = false;
  double _lastOffset = 0;
  bool _isScrollingToTop = false;
  double _coverHeight = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();

    _scrollController = widget.scrollController ?? ScrollController();

    _canRefresh = true;
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    _canRefresh = _scrollController.offset <= 2;

    if (_coverHeight > 0) {
      final progress = (_scrollController.offset / _coverHeight).clamp(
        0.0,
        1.0,
      );
      _statusBarScrimProgress.value = progress;
    }
  }

  void _loadProfileData() {
    final effectiveId = widget.userId ?? currentUserId;
    if (effectiveId != null) {
      context.read<ProfileCubit>().getProfileData(effectiveId);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _statusBarScrimProgress.dispose();
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
    final effectiveId = widget.userId ?? currentUserId;

    if (effectiveId == null) {
      return const SizedBox.shrink();
    }

    final isCurrentUser =
        widget.userId == null || widget.userId == currentUserId;
    final size = MediaQuery.sizeOf(context);
    final profileCubit = context.read<ProfileCubit>();
    final postsCubit = context.read<PostsCubit>();
    final double bgHeight = size.width / 1.7;
    final double avatarSize = size.width * 0.26;
    _coverHeight = bgHeight + avatarSize / 2 + 12;

    return ValueListenableBuilder<double>(
      valueListenable: _statusBarScrimProgress,
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

                final profilePostsCubit = context.read<ProfilePostsCubit>();
                final state = context.read<ProfileCubit>().state;
                if (state is ProfileLoaded) {
                  await Future.wait([
                    profileCubit.getProfileData(state.user.id, isRefresh: true),
                    profilePostsCubit.refresh(),
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
                bool isLoading =
                    state is ProfileInitial ||
                    state is ProfileLoading ||
                    state is ProfileRefreshFeedback;
                String? errorMessage =
                    state is ProfileError ? state.message : null;

                return CustomTabWrapper(
                  isLoading: isLoading,
                  errorMessage: errorMessage,
                  isTopSafeArea: false,
                  loadingSkeleton: ProfileShimmerLoading(
                    isCurrentUser: isCurrentUser,
                  ),
                  onRetry: () {
                    final retryId = widget.userId ?? currentUserId;
                    if (retryId != null) {
                      context.read<ProfileCubit>().getProfileData(retryId);
                    }
                  },
                  child:
                      state is ProfileLoaded
                          ? NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (_isScrollingToTop) return false;

                              if (notification is ScrollUpdateNotification) {
                                final metrics = notification.metrics;
                                double currentOffset = metrics.pixels;

                                bool isScrollingUp =
                                    currentOffset < _lastOffset;

                                if (currentOffset > 450 && isScrollingUp) {
                                  if (!_showBackToTop) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (mounted && !_showBackToTop) {
                                            setState(
                                              () => _showBackToTop = true,
                                            );
                                          }
                                        });
                                  }
                                } else if (!isScrollingUp ||
                                    currentOffset < 10) {
                                  if (_showBackToTop) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (mounted && _showBackToTop) {
                                            setState(
                                              () => _showBackToTop = false,
                                            );
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
                              postsCubit: postsCubit,
                              isCurrentUser: isCurrentUser,
                            ),
                          )
                          : const SizedBox.shrink(),
                );
              },
            ),
          ),

          CustomBackToTopBtn(isVisible: _showBackToTop, onTap: _scrollToTop),

          GlobalRefreshIndicator(
            refreshProgress: _refreshProgress,
            isRefreshing: _isRefreshing,
          ),
        ],
      ),
      builder: (context, progress, staticChild) {
        final brightness = Theme.of(context).brightness;
        final bool pastCover = progress >= 0.5;
        final overlayStyle =
            pastCover
                ? (brightness == Brightness.dark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark)
                : SystemUiOverlayStyle.light;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: Stack(
            children: [
              staticChild!,
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _ProfileStatusBarScrim(progress: progress),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileStatusBarScrim extends StatelessWidget {
  const _ProfileStatusBarScrim({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;
    final Color solidColor = Theme.of(context).colorScheme.surface;

    return IgnorePointer(
      child: SizedBox(
        height: statusBarHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: (1.0 - progress).clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: progress.clamp(0.0, 1.0),
              child: ColoredBox(color: solidColor),
            ),
          ],
        ),
      ),
    );
  }
}
