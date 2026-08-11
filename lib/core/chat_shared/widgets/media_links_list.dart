import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:linkify/linkify.dart' as linkify_pkg;
import '../../helpers/formatted_date.dart';
import '../../link/model/link_preview_data.dart';
import '../../link/services/link_preview_service.dart';
import '../../link/widgets/link_preview_card.dart';
import '../../link/widgets/message_link_preview.dart';
import '../../supabase/supabase_provider.dart';
import '../../widgets/custom_linkify_text.dart';
import '../helpers/media_action_helper.dart';
import '../models/shared_media_item.dart';
import 'sectioned_media_list.dart';
import 'shared_media_action_menu.dart';

class MediaLinksList extends StatelessWidget {
  final List<SharedMediaItem> items;
  final ShowInChatCallback? onShowInChat;

  const MediaLinksList({super.key, required this.items, this.onShowInChat});

  @override
  Widget build(BuildContext context) {
    final confirmed =
        items
            .where(
              (m) => linkify_pkg
                  .linkify(m.text)
                  .any((el) => el is linkify_pkg.UrlElement),
            )
            .toList();

    if (confirmed.isEmpty) {
      return const Center(child: Text('No links shared yet'));
    }

    return SectionedMediaList(
      items: confirmed,
      tileBuilder:
          (context, item) => _LinkTile(item: item, onShowInChat: onShowInChat),
    );
  }
}

class _LinkTile extends StatefulWidget {
  final SharedMediaItem item;
  final ShowInChatCallback? onShowInChat;
  const _LinkTile({required this.item, this.onShowInChat});

  @override
  State<_LinkTile> createState() => _LinkTileState();
}

class _LinkTileState extends State<_LinkTile> {
  late final String _url;
  late final Future<LinkPreviewData?> _future;

  @override
  void initState() {
    super.initState();
    _url = MessageLinkPreview.extractFirstUrl(widget.item.text)!;
    _future = LinkPreviewService.instance.fetch(_url);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.item.senderName} · ${FormattedDate.getFormattedDate(widget.item.createdAt.toString())}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(4),
          FutureBuilder<LinkPreviewData?>(
            future: _future,
            builder: (context, snapshot) {
              final isMe = widget.item.senderId == SupabaseProvider.id;

              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(
                    height: 2,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                );
              }

              final data = snapshot.data;
              if (data == null || !data.hasContent) {
                return GestureDetector(
                  onLongPressStart:
                      (details) => showSharedMediaActionMenu(
                        context: context,
                        globalPosition: details.globalPosition,
                        isMe: isMe,
                        onShowInChat:
                            () => MediaActionHelper.handleShowInChat(
                              context,
                              widget.item,
                              widget.onShowInChat,
                            ),

                        onConfirmedDelete:
                            () => MediaActionHelper.handleDelete(
                              context,
                              widget.item,
                              forEveryone: isMe,
                            ),
                        openLabel: 'Open link',
                        openIcon: Icons.open_in_new_rounded,
                      ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.link_rounded),
                    title: CustomLinkifyText(
                      text: widget.item.text,
                      maxLines: 2,
                    ),
                  ),
                );
              }

              return LinkPreviewCard(data: data);
            },
          ),
        ],
      ),
    );
  }
}
