import 'dart:math';
import 'package:flutter/material.dart';
import 'package:social_media_app/features/single_chats/widgets/chat_bubble_shimmer.dart';

class _ShimmerMsgConfig {
  final bool isMe;
  final bool showAvatar;
  final double width;
  final bool isDate;

  const _ShimmerMsgConfig({
    this.isMe = false,
    this.showAvatar = false,
    this.width = 0.5,
    this.isDate = false,
  });
}

class ChatLoadingSkeleton extends StatefulWidget {
  const ChatLoadingSkeleton({super.key});

  @override
  State<ChatLoadingSkeleton> createState() => _ChatLoadingSkeletonState();
}

class _ChatLoadingSkeletonState extends State<ChatLoadingSkeleton> {
  late final List<_ShimmerMsgConfig> _pattern;

  @override
  void initState() {
    super.initState();
    _pattern = _generateRandomChatPattern();
  }

  List<_ShimmerMsgConfig> _generateRandomChatPattern() {
    final random = Random();
    final List<_ShimmerMsgConfig> pattern = [];

    final int itemCount = random.nextInt(7) + 10;

    bool? lastWasMe;
    int messagesInCluster = 0;

    for (int i = 0; i < itemCount; i++) {
      if (i > 0 && i < itemCount - 1 && random.nextDouble() < 0.15) {
        pattern.add(const _ShimmerMsgConfig(isDate: true));
        lastWasMe = null;
        messagesInCluster = 0;
        continue;
      }

      bool isMe;
      if (lastWasMe == null) {
        isMe = random.nextBool();
      } else {
        if (messagesInCluster >= 3) {
          isMe = !lastWasMe;
        } else {
          isMe = random.nextDouble() < 0.6 ? lastWasMe : !lastWasMe;
        }
      }

      final double width = random.nextDouble() * 0.45 + 0.25;

      if (isMe) {
        pattern.add(_ShimmerMsgConfig(isMe: true, width: width));
      } else {
        bool showAvatar = (lastWasMe != false);
        pattern.add(
          _ShimmerMsgConfig(isMe: false, showAvatar: showAvatar, width: width),
        );
      }

      if (lastWasMe == isMe) {
        messagesInCluster++;
      } else {
        messagesInCluster = 1;
      }
      lastWasMe = isMe;
    }

    return pattern;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      reverse: true,
      itemCount: _pattern.length,
      itemBuilder: (context, index) {
        final config = _pattern[index];
        return ChatBubbleShimmer(
          isMe: config.isMe,
          showAvatar: config.showAvatar,
          widthMultiplier: config.width,
          isDateSeparator: config.isDate,
        );
      },
    );
  }
}
