import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:linkify/linkify.dart' as linkify_pkg;
import 'package:social_media_app/core/widgets/custom_linkify_text.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/single_chats/widgets/full_screen_media_view.dart';
import 'package:social_media_app/features/single_chats/widgets/voice_message_bubble_widget.dart';
import '../../../../core/helpers/formatted_date.dart';
import '../cubits/shared_media_cubit/shared_media_cubit.dart';
import '../widgets/shared_media_date_sectioner.dart';
import '../models/shared_media_item.dart';

class SharedMediaView extends StatefulWidget {
  final SharedMediaCubit mediaCubit;
  final int initialIndex;

  const SharedMediaView({
    super.key,
    required this.mediaCubit,
    this.initialIndex = 0,
  });

  @override
  State<SharedMediaView> createState() => _SharedMediaViewState();
}

class _SharedMediaViewState extends State<SharedMediaView> {
  static const _tabs = SharedMediaTab.values;

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
            children: _tabs.map((tab) => _MediaTabView(tab: tab)).toList(),
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
  const _MediaTabView({required this.tab});

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
          SharedMediaTab.all => _AllMediaGrid(items: items),
          SharedMediaTab.images => _ImagesGrid(items: items),
          SharedMediaTab.videos => _VideosGrid(items: items),
          SharedMediaTab.voice => _VoiceList(items: items),
          SharedMediaTab.links => _LinksList(items: items),
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

void _openFullScreenImage(BuildContext context, SharedMediaItem item) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => FullScreenMediaView(imageUrl: item.imageUrl ?? ''),
    ),
  );
}

void _openFullScreenVideo(BuildContext context, SharedMediaItem item) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => FullScreenMediaView(videoUrl: item.videoUrl ?? ''),
    ),
  );
}

class _AllMediaGrid extends StatelessWidget {
  final List<SharedMediaItem> items;
  const _AllMediaGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return _SectionedMediaGrid(
      items: items,
      tileBuilder: (context, item) {
        return GestureDetector(
          onTap: () {
            if (item.messageType == 'image') {
              _openFullScreenImage(context, item);
            } else if (item.messageType == 'video') {
              _openFullScreenVideo(context, item);
            }
          },
          child: switch (item.messageType) {
            'image' => CachedNetworkImage(
              imageUrl: item.imageUrl ?? '',
              fit: BoxFit.cover,
            ),
            'video' => Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: item.videoUrl ?? '',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: Colors.black12),
                ),
                const Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            _ => Container(
              color: primary.withValues(alpha: 0.12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic_rounded, color: primary),
                  const Gap(4),
                  Text('Voice', style: TextStyle(color: primary, fontSize: 11)),
                ],
              ),
            ),
          },
        );
      },
    );
  }
}

class _ImagesGrid extends StatelessWidget {
  final List<SharedMediaItem> items;
  const _ImagesGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SectionedMediaGrid(
      items: items,
      tileBuilder:
          (context, item) => GestureDetector(
            onTap: () => _openFullScreenImage(context, item),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl ?? '',
              fit: BoxFit.cover,
            ),
          ),
    );
  }
}

class _VideosGrid extends StatelessWidget {
  final List<SharedMediaItem> items;
  const _VideosGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SectionedMediaGrid(
      items: items,
      tileBuilder:
          (context, item) => GestureDetector(
            onTap: () => _openFullScreenVideo(context, item),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: item.videoUrl ?? '',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: Colors.black12),
                ),
                const Center(
                  child: Icon(Icons.play_circle_fill_rounded, size: 28),
                ),
              ],
            ),
          ),
    );
  }
}

/// Voice tab: real inline playback via VoiceMessageBubbleWidget, which now
/// shares its "one voice note at a time" state with every other voice
/// player in the app (see VoicePlaybackController) — so tapping a voice
/// note here automatically pauses one already playing in an underlying
/// open chat, and vice versa.
class _VoiceList extends StatelessWidget {
  final List<SharedMediaItem> items;
  const _VoiceList({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SectionedMediaList(
      items: items,
      tileBuilder: (context, item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.12),
                backgroundImage:
                    (item.senderAvatar != null && item.senderAvatar!.isNotEmpty)
                        ? CachedNetworkImageProvider(item.senderAvatar!)
                        : null,
                child:
                    (item.senderAvatar == null || item.senderAvatar!.isEmpty)
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
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.senderName,
                      style: Theme.of(context).textTheme.titleSmall,
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
        );
      },
    );
  }
}

class _LinksList extends StatelessWidget {
  final List<SharedMediaItem> items;
  const _LinksList({required this.items});

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
          (context, item) => ListTile(
            leading: const Icon(Icons.link_rounded),
            title: CustomLinkifyText(text: item.text, maxLines: 2),
            subtitle: Text(
              '${item.senderName} · ${FormattedDate.getFormattedDate(item.createdAt.toString())}',
            ),
          ),
    );
  }
}
