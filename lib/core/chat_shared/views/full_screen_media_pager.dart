import 'package:flutter/material.dart';
import 'package:social_media_app/features/single_chats/widgets/full_screen_media_view.dart';
import '../models/shared_media_item.dart';
import 'voice_full_screen_view.dart';

class FullScreenMediaPager extends StatefulWidget {
  final List<SharedMediaItem> items;
  final int initialIndex;
  final String? currentUserAvatar;

  const FullScreenMediaPager({
    super.key,
    required this.items,
    required this.initialIndex,
    this.currentUserAvatar,
  });

  @override
  State<FullScreenMediaPager> createState() => _FullScreenMediaPagerState();
}

class _FullScreenMediaPagerState extends State<FullScreenMediaPager> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.items.length,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final isActive = index == _currentIndex;

        if ((item.voiceUrl ?? '').isNotEmpty) {
          return VoiceFullScreenView(
            key: ValueKey(item.id),
            item: item,
            isActive: isActive,
            currentUserAvatar: widget.currentUserAvatar,
          );
        }

        final isImage = item.messageType == 'image';
        return FullScreenMediaView(
          key: ValueKey(item.id),
          imageUrl: isImage ? item.imageUrl : null,
          videoUrl: isImage ? null : item.videoUrl,
          isActive: isActive,
        );
      },
    );
  }
}
