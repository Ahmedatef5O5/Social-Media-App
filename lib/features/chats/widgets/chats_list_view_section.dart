import 'package:flutter/material.dart';
import 'package:social_media_app/features/chats/widgets/chat_item_tile.dart';
import '../../../core/themes/app_colors.dart';
import '../models/chat_user_model.dart';

class ChatsListViewSection extends StatelessWidget {
  final List<ChatUserModel> chats;
  const ChatsListViewSection({super.key, required this.chats});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 100),
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      itemCount: chats.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == chats.length) {
          return const SizedBox.shrink();
        }

        return ChatItemTile(user: chats[index]);
      },
      separatorBuilder: (_, __) => const Divider(color: AppColors.black12),
    );
  }
}
