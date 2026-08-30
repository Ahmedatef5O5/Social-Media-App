import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/reels_feed_cubit/reels_feed_cubit.dart';
import '../models/reel_model.dart';
import '../services/reel_player_controller_pool.dart';
import '../widgets/reel_page.dart';

class ReelsFullScreenView extends StatefulWidget {
  final List<ReelModel>? reels;
  final int? sectionIndex;
  final int initialIndex;

  const ReelsFullScreenView({
    super.key,
    this.reels,
    this.sectionIndex,
    required this.initialIndex,
  }) : assert(
         sectionIndex != null || reels != null,
         'Must provide either sectionIndex or reels',
       );

  @override
  State<ReelsFullScreenView> createState() => _ReelsFullScreenViewState();
}

class _ReelsFullScreenViewState extends State<ReelsFullScreenView> {
  late final PageController _pageController;
  final ReelPlayerControllerPool _controllerPool = ReelPlayerControllerPool();
  late int _currentIndex;
  double _accumulatedDragDistance = 0;
  static const int _loadMoreThreshold = 3;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _activateIndex(widget.initialIndex);
    });
  }

  List<ReelModel> _currentReels() {
    if (widget.reels != null) {
      return widget.reels!;
    }

    final state = context.read<ReelsFeedCubit>().state;
    if (state is ReelsFeedLoaded &&
        widget.sectionIndex! < state.sections.length) {
      return state.sections[widget.sectionIndex!];
    }
    return const [];
  }

  void _activateIndex(int index) {
    final reels = _currentReels();
    if (reels.isEmpty) return;

    _currentIndex = index;
    _controllerPool.updateActiveIndex(index, reels);
    _controllerPool.setActivelyPlaying(index);
    _maybeLoadMore(index, reels.length);
  }

  void _maybeLoadMore(int index, int totalCount) {
    if (widget.sectionIndex == null) return;

    if (index >= totalCount - _loadMoreThreshold) {
      context.read<ReelsFeedCubit>().loadMoreReelsForSection(
        widget.sectionIndex!,
      );
    }
  }

  void _handleDragUpdate(double dy) {
    if (!_pageController.hasClients) return;
    _accumulatedDragDistance += dy;
    final position = _pageController.position;
    final next = (position.pixels - dy).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _pageController.jumpTo(next);
  }

  void _handleDragEnd(double velocity) {
    if (!_pageController.hasClients) return;
    final reelsCount = _currentReels().length;
    if (reelsCount == 0) return;
    const flingVelocityThreshold = 300.0;
    final distanceThreshold = MediaQuery.sizeOf(context).height * 0.18;
    final draggedDistance = _accumulatedDragDistance;
    _accumulatedDragDistance = 0;
    final page = _pageController.page ?? _currentIndex.toDouble();

    int target;
    if (velocity <= -flingVelocityThreshold) {
      target = _currentIndex + 1;
    } else if (velocity >= flingVelocityThreshold) {
      target = _currentIndex - 1;
    } else if (draggedDistance <= -distanceThreshold) {
      target = _currentIndex + 1;
    } else if (draggedDistance >= distanceThreshold) {
      target = _currentIndex - 1;
    } else {
      target = page.round();
    }
    target = target.clamp(0, reelsCount - 1);

    _pageController
        .animateToPage(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        )
        .then((_) {
          if (mounted && target != _currentIndex) {
            _activateIndex(target);
          }
        });
  }

  @override
  void dispose() {
    _controllerPool.disposeAll();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reels != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildPageView(widget.reels!),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<ReelsFeedCubit, ReelsFeedState>(
        buildWhen: (previous, current) {
          if (previous is! ReelsFeedLoaded || current is! ReelsFeedLoaded) {
            return true;
          }
          final prevLen =
              widget.sectionIndex! < previous.sections.length
                  ? previous.sections[widget.sectionIndex!].length
                  : 0;
          final currLen =
              widget.sectionIndex! < current.sections.length
                  ? current.sections[widget.sectionIndex!].length
                  : 0;
          return prevLen != currLen;
        },
        builder: (context, state) {
          final reels = _currentReels();
          if (reels.isEmpty) {
            return const SizedBox.shrink();
          }

          return _buildPageView(reels);
        },
      ),
    );
  }

  Widget _buildPageView(List<ReelModel> reels) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: const NeverScrollableScrollPhysics(),
      allowImplicitScrolling: true,
      itemCount: reels.length,
      onPageChanged: _activateIndex,
      itemBuilder: (context, index) {
        final reel = reels[index];
        final controller = _controllerPool.controllerFor(
          index,
          reel.youtubeVideoId,
          isActive: index == _currentIndex,
        );
        return ReelPage(
          reel: reel,
          controller: controller,
          keepAlive: _controllerPool.isWithinWindow(index, _currentIndex),
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
        );
      },
    );
  }
}
