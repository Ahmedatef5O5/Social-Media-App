import 'package:flutter/material.dart';
import 'package:social_media_app/features/chats/widgets/chat_bubble_shimmer.dart';

class ChatLoadingSkeleton extends StatelessWidget {
  const ChatLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      reverse: true,
      itemCount: 12,
      itemBuilder: (context, index) {
        return ChatBubbleShimmer(isMe: index % 3 == 0, index: index);
      },
    );
  }
}
