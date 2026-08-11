import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cache/utils/cloudinary_url_extensions.dart';
import '../../supabase/supabase_provider.dart';
import '../cubits/shared_media_cubit/shared_media_cubit.dart';
import '../helpers/media_action_helper.dart' hide ShowInChatCallback;
import '../helpers/shared_media_tabs_skeleton.dart';
import '../models/shared_media_item.dart';
import '../views/shared_media_view.dart';
import 'media_links_list.dart';
import 'sectioned_media_grid.dart';
import 'shared_media_action_menu.dart';
import 'shared_images_grid.dart';
import 'video_thumbnail_grid.dart';
import 'voice_grid_tile.dart';
import 'voice_message_grid.dart';

class MediaTabView extends StatefulWidget {
  final SharedMediaTab tab;
  final ShowInChatCallback? onShowInChat;

  const MediaTabView({super.key, required this.tab, this.onShowInChat});

  @override
  State<MediaTabView> createState() => _MediaTabViewState();
}

class _MediaTabViewState extends State<MediaTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<SharedMediaCubit>().loadTab(widget.tab);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<SharedMediaCubit, SharedMediaState>(
      builder: (context, state) {
        final isLoading = state.isLoading(widget.tab);
        final items = state.itemsFor(widget.tab);

        if (isLoading && items.isEmpty) {
          return switch (widget.tab) {
            SharedMediaTab.all => const GridMediaSkeleton(),
            SharedMediaTab.images => const GridMediaSkeleton(),
            SharedMediaTab.videos => const GridMediaSkeleton(),
            SharedMediaTab.voice => const VoiceListSkeleton(),
            SharedMediaTab.links => const LinksListSkeleton(),
          };
        }
        if (items.isEmpty) {
          return Center(child: Text('No ${_labelFor(widget.tab)} shared yet'));
        }

        return switch (widget.tab) {
          SharedMediaTab.all => _AllMediaGrid(
            items: items,
            onShowInChat: widget.onShowInChat,
          ),
          SharedMediaTab.images => SharedImagesGrid(
            items: items,
            onShowInChat: widget.onShowInChat,
          ),
          SharedMediaTab.videos => VideoThumbnailGrid(
            items: items,
            onShowInChat: widget.onShowInChat,
          ),
          SharedMediaTab.voice => VoiceMessageGrid(
            items: items,
            onShowInChat: widget.onShowInChat,
          ),
          SharedMediaTab.links => MediaLinksList(
            items: items,
            onShowInChat: widget.onShowInChat,
          ),
        };
      },
    );
  }

  String _labelFor(SharedMediaTab tab) => switch (tab) {
    SharedMediaTab.all => 'media',
    SharedMediaTab.images => 'images',
    SharedMediaTab.videos => 'videos',
    SharedMediaTab.voice => 'voice messages',
    SharedMediaTab.links => 'links',
  };
}

class _AllMediaGrid extends StatelessWidget {
  final List<SharedMediaItem> items;
  final ShowInChatCallback? onShowInChat;
  const _AllMediaGrid({required this.items, this.onShowInChat});

  @override
  Widget build(BuildContext context) {
    return SectionedMediaGrid(
      items: items,
      tileBuilder: (context, item) {
        final isMe = item.senderId == SupabaseProvider.id;
        final isVoice = (item.voiceUrl ?? '').isNotEmpty;

        VoidCallback? onOpen;
        String openLabel = 'Open';
        IconData openIcon = Icons.open_in_full_rounded;

        if (item.messageType == 'image') {
          onOpen =
              () => MediaActionHelper.openFullScreenMedia(context, items, item);
          openLabel = 'View photo';
          openIcon = Icons.image_outlined;
        } else if (item.messageType == 'video') {
          onOpen =
              () => MediaActionHelper.openFullScreenMedia(context, items, item);
          openLabel = 'Play video';
          openIcon = Icons.play_circle_outline_rounded;
        } else if (isVoice) {
          onOpen =
              () => MediaActionHelper.openFullScreenMedia(context, items, item);
          openLabel = 'Play voice message';
          openIcon = Icons.mic_none_rounded;
        }

        return GestureDetector(
          onTap: () {
            if (item.messageType == 'image' ||
                item.messageType == 'video' ||
                isVoice) {
              MediaActionHelper.openFullScreenMedia(context, items, item);
            }
          },
          onLongPressStart: ((details) {
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
              onOpen: onOpen,
              openLabel: openLabel,
              openIcon: openIcon,
            );
          }),
          child: switch (item.messageType) {
            'image' => CachedNetworkImage(
              imageUrl: item.imageUrl ?? '',
              fit: BoxFit.cover,
            ),
            'video' => Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl:
                      item.videoUrl?.cloudinaryVideoThumbnailUrl ??
                      item.videoUrl ??
                      '',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.black12),
                  errorWidget: (_, __, ___) => Container(color: Colors.black12),
                ),
                const Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            _ => VoiceGridTile(item: item),
          },
        );
      },
    );
  }
}
