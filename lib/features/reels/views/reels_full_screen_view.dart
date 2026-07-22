import 'package:flutter/material.dart';
import '../model/reel_model.dart';
import '../services/reel_player_controller_pool.dart';
import '../widgets/reel_page.dart';

class ReelsFullScreenView extends StatefulWidget {
  final List<ReelModel> reels;
  final int initialIndex;

  const ReelsFullScreenView({
    super.key,
    required this.reels,
    required this.initialIndex,
  });

  @override
  State<ReelsFullScreenView> createState() => _ReelsFullScreenViewState();
}

class _ReelsFullScreenViewState extends State<ReelsFullScreenView> {
  late final PageController _pageController;
  final ReelPlayerControllerPool _controllerPool = ReelPlayerControllerPool();
  late int _currentIndex;

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

  void _activateIndex(int index) {
    _currentIndex = index;
    _controllerPool.updateActiveIndex(index, widget.reels);
    _controllerPool.setActivelyPlaying(index);
  }

  void _handleDragUpdate(double dy) {
    if (!_pageController.hasClients) return;
    final position = _pageController.position;
    final next = (position.pixels - dy).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _pageController.jumpTo(next);
  }

  void _handleDragEnd(double velocity) {
    if (!_pageController.hasClients) return;
    const flingVelocityThreshold = 600.0;
    final page = _pageController.page ?? _currentIndex.toDouble();

    int target;
    if (velocity <= -flingVelocityThreshold) {
      target = _currentIndex + 1; // fast upward swipe -> next reel
    } else if (velocity >= flingVelocityThreshold) {
      target = _currentIndex - 1; // fast downward swipe -> previous reel
    } else {
      target = page.round(); // slow drag -> snap to nearest page
    }
    target = target.clamp(0, widget.reels.length - 1);

    _pageController
        .animateToPage(
          target,
          duration: const Duration(milliseconds: 260),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const NeverScrollableScrollPhysics(),
        allowImplicitScrolling: true,
        itemCount: widget.reels.length,
        onPageChanged: _activateIndex,
        itemBuilder: (context, index) {
          final reel = widget.reels[index];
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
      ),
    );
  }
}
