import 'package:flutter/material.dart';
import '../../supabase/supabase_provider.dart';
import '../helpers/media_action_helper.dart' hide ShowInChatCallback;
import '../models/shared_media_item.dart';
import '../views/shared_media_view.dart';
import 'document_grid_tile.dart';
import 'sectioned_media_grid.dart';
import 'shared_media_action_menu.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class SharedDocumentsGrid extends StatelessWidget {
  final List<SharedMediaItem> items;
  final ShowInChatCallback? onShowInChat;

  const SharedDocumentsGrid({
    super.key,
    required this.items,
    this.onShowInChat,
  });

  @override
  Widget build(BuildContext context) {
    return SectionedMediaGrid(
      items: items,
      tileBuilder: (context, item) {
        final isMe = item.senderId == SupabaseProvider.id;

        return GestureDetector(
          onTap: () => DocumentGridTile.openFile(item.fileUrl),
          onLongPressStart: (details) {
            showSharedMediaActionMenu(
              context: context,
              globalPosition: details.globalPosition,
              isMe: isMe,
              onShowInChat:
                  () => MediaActionHelper.handleShowInChat(
                    context,
                    item,
                    onShowInChat,
                  ),
              onConfirmedDelete:
                  () => MediaActionHelper.handleDelete(
                    context,
                    item,
                    forEveryone: isMe,
                  ),
              onOpen: () => DocumentGridTile.openFile(item.fileUrl),
              openLabel: context.l10n.open,
              openIcon: Icons.open_in_new_rounded,
            );
          },
          child: DocumentGridTile(item: item),
        );
      },
    );
  }
}
