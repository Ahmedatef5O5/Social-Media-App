import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:linkify/linkify.dart' as linkify_pkg;
import 'package:social_media_app/core/cache/utils/cloudinary_url_extensions.dart';
import 'package:social_media_app/core/widgets/custom_linkify_text.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/single_chats/widgets/voice_message_bubble_widget.dart';
import '../../../../core/helpers/formatted_date.dart';
import '../../link/model/link_preview_data.dart';
import '../../link/services/link_preview_service.dart';
import '../../link/widgets/link_preview_card.dart';
import '../../link/widgets/message_link_preview.dart';
import '../../supabase/supabase_provider.dart';
import '../../toast/app_toast.dart';
import '../controllers/voice_playback_controller.dart';
import '../cubits/shared_media_cubit/shared_media_cubit.dart';
import '../widgets/shared_media_action_menu.dart';
import '../widgets/shared_media_date_sectioner.dart';
import '../widgets/voice_grid_tile.dart';
import '../models/shared_media_item.dart';
import 'full_screen_media_pager.dart';

typedef ShowInChatCallback =
    void Function(BuildContext context, String messageId);

class SharedMediaView extends StatefulWidget {
  final SharedMediaCubit mediaCubit;
  final int initialIndex;
  final ShowInChatCallback? onShowInChat;

  const SharedMediaView({
    super.key,
    required this.mediaCubit,
    this.initialIndex = 0,
    this.onShowInChat,
  });

  @override
  State<SharedMediaView> createState() => _SharedMediaViewState();
}

class _SharedMediaViewState extends State<SharedMediaView> {
  static const _tabs = SharedMediaTab.values;

  @override
  void dispose() {
    // Leaving Shared Media entirely stops any voice note playing while
    // browsing it. VoiceFullScreenView's own dispose now also stops its
    // own audio on close, so this is mostly a safety net at this point.
    VoicePlaybackController.instance.pauseActive();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: _tabs.length,
      initialIndex: widget.initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Shared Media',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          bottom: TabBar(
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.zero,
            splashFactory: NoSplash.splashFactory,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(25),
            ),
            indicatorPadding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 4,
            ),
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Images'),
              Tab(text: 'Videos'),
              Tab(text: 'Voice'),
              Tab(text: 'Links'),
            ],
          ),
        ),
        body: BlocProvider.value(
          value: widget.mediaCubit,
          child: TabBarView(
            children:
                _tabs
                    .map(
                      (tab) => _MediaTabView(
                        tab: tab,
                        onShowInChat: widget.onShowInChat,
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SectionedMediaGrid extends StatelessWidget {
  final List<SharedMediaItem> items;
  final Widget Function(BuildContext, SharedMediaItem) tileBuilder;

  const _SectionedMediaGrid({required this.items, required this.tileBuilder});

  @override
  Widget build(BuildContext context) {
    final sections = SharedMediaDateSectioner.bucket(items);
    return CustomScrollView(
      slivers: [
        for (final section in sections) ...[
          SliverToBoxAdapter(child: _SectionHeader(label: section.key)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => tileBuilder(context, section.value[index]),
                childCount: section.value.length,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionedMediaList extends StatelessWidget {
  final List<SharedMediaItem> items;
  final Widget Function(BuildContext, SharedMediaItem) tileBuilder;

  const _SectionedMediaList({required this.items, required this.tileBuilder});

  @override
  Widget build(BuildContext context) {
    final sections = SharedMediaDateSectioner.bucket(items);
    return CustomScrollView(
      slivers: [
        for (final section in sections) ...[
          SliverToBoxAdapter(child: _SectionHeader(label: section.key)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => tileBuilder(context, section.value[index]),
              childCount: section.value.length,
            ),
          ),
        ],
      ],
    );
  }
}

class _MediaTabView extends StatefulWidget {
  final SharedMediaTab tab;
  final ShowInChatCallback? onShowInChat;

  const _MediaTabView({required this.tab, this.onShowInChat});

  @override
  State<_MediaTabView> createState() => _MediaTabViewState();
}

class _MediaTabViewState extends State<_MediaTabView>
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
          return const Center(child: CustomLoadingIndicator());
        }
        if (items.isEmpty) {
          return Center(child: Text('No ${_labelFor(widget.tab)} shared yet'));
        }

        return switch (widget.tab) {
          SharedMediaTab.all => _AllMediaGrid(
            items: items,
            onShowInChat: widget.onShowInChat,
          ),
          SharedMediaTab.images => _ImagesGrid(
            items: items,
            onShowInChat: widget.onShowInChat,
          ),
          SharedMediaTab.videos => _VideosGrid(
            items: items,
            onShowInChat: widget.onShowInChat,
          ),
          SharedMediaTab.voice => _VoiceList(
            items: items,
            onShowInChat: widget.onShowInChat,
          ),
          SharedMediaTab.links => _LinksList(
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

/// Opens the unified pager for image/video/voice, landing on [tappedItem]'s
/// page. Links are excluded since they have no visual full-screen form.
void _openFullScreenMedia(
  BuildContext context,
  List<SharedMediaItem> tabItems,
  SharedMediaItem tappedItem,
) {
  final playable =
      tabItems
          .where(
            (i) =>
                i.messageType == 'image' ||
                i.messageType == 'video' ||
                (i.voiceUrl ?? '').isNotEmpty,
          )
          .toList();
  final initialIndex = playable.indexWhere((i) => i.id == tappedItem.id);

  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder:
          (_, __, ___) => FullScreenMediaPager(
            items: playable,
            initialIndex: initialIndex < 0 ? 0 : initialIndex,
          ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

void _handleShowInChat(
  BuildContext context,
  SharedMediaItem item,
  ShowInChatCallback? onShowInChat,
) {
  if (onShowInChat == null) {
    AppToast.info('Open this from a chat to jump to the message');
    return;
  }
  onShowInChat(context, item.id);
}

Future<void> _handleDelete(
  BuildContext context,
  SharedMediaItem item, {
  required bool forEveryone,
}) async {
  try {
    await context.read<SharedMediaCubit>().deleteItem(
      item,
      forEveryone: forEveryone,
    );
    if (context.mounted) {
      AppToast.success(
        forEveryone ? 'Deleted for everyone' : 'Deleted for you',
      );
    }
  } catch (e) {
    debugPrint('[SharedMediaView] delete error: $e');
    if (context.mounted) AppToast.error('Failed to delete message');
  }
}

class _AllMediaGrid extends StatelessWidget {
  final List<SharedMediaItem> items;
  final ShowInChatCallback? onShowInChat;
  const _AllMediaGrid({required this.items, this.onShowInChat});

  @override
  Widget build(BuildContext context) {
    return _SectionedMediaGrid(
      items: items,
      tileBuilder: (context, item) {
        final isMe = item.senderId == SupabaseProvider.id;
        final isVoice = (item.voiceUrl ?? '').isNotEmpty;

        VoidCallback? onOpen;
        String openLabel = 'Open';
        IconData openIcon = Icons.open_in_full_rounded;

        if (item.messageType == 'image') {
          onOpen = () => _openFullScreenMedia(context, items, item);
          openLabel = 'View photo';
          openIcon = Icons.image_outlined;
        } else if (item.messageType == 'video') {
          onOpen = () => _openFullScreenMedia(context, items, item);
          openLabel = 'Play video';
          openIcon = Icons.play_circle_outline_rounded;
        } else if (isVoice) {
          onOpen = () => _openFullScreenMedia(context, items, item);
          openLabel = 'Play voice message';
          openIcon = Icons.mic_none_rounded;
        }

        return GestureDetector(
          onTap: () {
            if (item.messageType == 'image' ||
                item.messageType == 'video' ||
                isVoice) {
              _openFullScreenMedia(context, items, item);
            }
          },
          onLongPressStart: ((details) {
            showSharedMediaActionMenu(
              context: context,
              globalPosition: details.globalPosition,
              isMe: isMe,
              onShowInChat:
                  () => _handleShowInChat(context, item, onShowInChat),

              onConfirmedDelete:
                  () => _handleDelete(context, item, forEveryone: isMe),
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

class _ImagesGrid extends StatelessWidget {
  final List<SharedMediaItem> items;
  final ShowInChatCallback? onShowInChat;
  const _ImagesGrid({required this.items, this.onShowInChat});

  @override
  Widget build(BuildContext context) {
    return _SectionedMediaGrid(
      items: items,
      tileBuilder: (context, item) {
        final isMe = item.senderId == SupabaseProvider.id;

        return GestureDetector(
          onTap: () => _openFullScreenMedia(context, items, item),
          onLongPressStart:
              (details) => showSharedMediaActionMenu(
                context: context,
                globalPosition: details.globalPosition,
                isMe: isMe,
                onShowInChat:
                    () => _handleShowInChat(context, item, onShowInChat),

                onConfirmedDelete:
                    () => _handleDelete(context, item, forEveryone: isMe),
                onOpen: () => _openFullScreenMedia(context, items, item),
                openLabel: 'View photo',
                openIcon: Icons.image_outlined,
              ),
          child: CachedNetworkImage(
            imageUrl: item.imageUrl ?? '',
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

class _VideosGrid extends StatelessWidget {
  final List<SharedMediaItem> items;
  final ShowInChatCallback? onShowInChat;
  const _VideosGrid({required this.items, this.onShowInChat});

  @override
  Widget build(BuildContext context) {
    return _SectionedMediaGrid(
      items: items,
      tileBuilder: (context, item) {
        final isMe = item.senderId == SupabaseProvider.id;

        return GestureDetector(
          onTap: () => _openFullScreenMedia(context, items, item),
          onLongPressStart:
              (details) => showSharedMediaActionMenu(
                context: context,
                globalPosition: details.globalPosition,
                isMe: isMe,
                onShowInChat:
                    () => _handleShowInChat(context, item, onShowInChat),
                onConfirmedDelete:
                    () => _handleDelete(context, item, forEveryone: isMe),
                onOpen: () => _openFullScreenMedia(context, items, item),
                openLabel: 'Play video',
                openIcon: Icons.play_circle_outline_rounded,
              ),
          child: Stack(
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
        );
      },
    );
  }
}

class _VoiceList extends StatelessWidget {
  final List<SharedMediaItem> items;
  final ShowInChatCallback? onShowInChat;
  const _VoiceList({required this.items, this.onShowInChat});

  @override
  Widget build(BuildContext context) {
    return _SectionedMediaList(
      items: items,
      tileBuilder: (context, item) {
        final isMe = item.senderId == SupabaseProvider.id;

        return GestureDetector(
          onTap: () => _openFullScreenMedia(context, items, item),
          onLongPressStart:
              (details) => showSharedMediaActionMenu(
                context: context,
                globalPosition: details.globalPosition,
                isMe: isMe,
                onShowInChat:
                    () => _handleShowInChat(context, item, onShowInChat),
                onConfirmedDelete:
                    () => _handleDelete(context, item, forEveryone: isMe),
                onOpen: () => _openFullScreenMedia(context, items, item),
                openLabel: 'Open voice message',
                openIcon: Icons.mic_none_rounded,
              ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openFullScreenMedia(context, items, item),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.12),
                    backgroundImage:
                        (item.senderAvatar != null &&
                                item.senderAvatar!.isNotEmpty)
                            ? CachedNetworkImageProvider(item.senderAvatar!)
                            : null,
                    child:
                        (item.senderAvatar == null ||
                                item.senderAvatar!.isEmpty)
                            ? Text(
                              item.senderName.isNotEmpty
                                  ? item.senderName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 13,
                              ),
                            )
                            : null,
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _openFullScreenMedia(context, items, item),
                        child: Text(
                          item.senderName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const Gap(2),
                      VoiceMessageBubbleWidget(
                        voiceUrl: item.voiceUrl ?? '',
                        isMe: false,
                        timestamp: item.createdAt,
                        isUploading: false,
                        initialDurationSeconds: item.durationSeconds,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LinksList extends StatelessWidget {
  final List<SharedMediaItem> items;
  final ShowInChatCallback? onShowInChat;
  const _LinksList({required this.items, this.onShowInChat});

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

    return _SectionedMediaList(
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
                            () => _handleShowInChat(
                              context,
                              widget.item,
                              widget.onShowInChat,
                            ),

                        onConfirmedDelete:
                            () => _handleDelete(
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
