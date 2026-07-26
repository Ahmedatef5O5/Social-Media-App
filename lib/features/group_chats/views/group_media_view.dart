import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:linkify/linkify.dart' as linkify_pkg;
import 'package:video_player/video_player.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/widgets/custom_linkify_text.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubit/group_media_cubit/group_media_cubit.dart';
import '../models/groupe_message_model.dart';

class GroupMediaView extends StatefulWidget {
  final GroupMediaCubit mediaCubit;
  final String groupId;
  final int initialIndex;

  const GroupMediaView({
    super.key,
    required this.mediaCubit,
    required this.groupId,
    this.initialIndex = 0,
  });

  @override
  State<GroupMediaView> createState() => _GroupMediaViewState();
}

class _GroupMediaViewState extends State<GroupMediaView> {
  static const _tabs = GroupMediaTab.values;

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
            // isScrollable: true,
            // tabAlignment: TabAlignment.center,
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

class _MediaTabView extends StatefulWidget {
  final GroupMediaTab tab;
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
    context.read<GroupMediaCubit>().loadTab(widget.tab);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<GroupMediaCubit, GroupMediaState>(
      builder: (context, state) {
        final isLoading = state.loadingTabs.contains(widget.tab);
        final items = state.items[widget.tab] ?? const [];

        if (isLoading && items.isEmpty) {
          return const Center(child: CustomLoadingIndicator());
        }
        if (items.isEmpty) {
          return Center(child: Text('No ${_labelFor(widget.tab)} shared yet'));
        }

        return switch (widget.tab) {
          GroupMediaTab.all => _AllMediaGrid(items: items),
          GroupMediaTab.images => _ImagesGrid(items: items),
          GroupMediaTab.videos => _VideosGrid(items: items),
          GroupMediaTab.voice => _VoiceList(items: items),
          GroupMediaTab.links => _LinksList(items: items),
        };
      },
    );
  }

  String _labelFor(GroupMediaTab tab) => switch (tab) {
    GroupMediaTab.all => 'media',
    GroupMediaTab.images => 'images',
    GroupMediaTab.videos => 'videos',
    GroupMediaTab.voice => 'voice messages',
    GroupMediaTab.links => 'links',
  };
}

class _AllMediaGrid extends StatelessWidget {
  final List<GroupMessageModel> items;
  const _AllMediaGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final msg = items[index];
        return GestureDetector(
          onTap: () {
            if (msg.messageType == 'image') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => _FullScreenNetworkImage(url: msg.imageUrl ?? ''),
                ),
              );
            } else if (msg.messageType == 'video') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => _FullScreenNetworkVideo(url: msg.videoUrl ?? ''),
                ),
              );
            }
          },
          child: switch (msg.messageType) {
            'image' => CachedNetworkImage(
              imageUrl: msg.imageUrl ?? '',
              fit: BoxFit.cover,
            ),
            'video' => Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: msg.videoUrl ?? '',
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
  final List<GroupMessageModel> items;
  const _ImagesGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final msg = items[index];
        return GestureDetector(
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => _FullScreenNetworkImage(url: msg.imageUrl ?? ''),
                ),
              ),
          child: CachedNetworkImage(
            imageUrl: msg.imageUrl ?? '',
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

class _VideosGrid extends StatelessWidget {
  final List<GroupMessageModel> items;
  const _VideosGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final msg = items[index];
        return GestureDetector(
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => _FullScreenNetworkVideo(url: msg.videoUrl ?? ''),
                ),
              ),
          child: Container(
            color: Colors.black12,
            child: const Center(
              child: Icon(Icons.play_circle_fill_rounded, size: 28),
            ),
          ),
        );
      },
    );
  }
}

class _VoiceList extends StatefulWidget {
  final List<GroupMessageModel> items;
  const _VoiceList({required this.items});

  @override
  State<_VoiceList> createState() => _VoiceListState();
}

class _VoiceListState extends State<_VoiceList> {
  String? _playingId;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: widget.items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final msg = widget.items[index];
        final isPlaying = _playingId == msg.id;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).primaryColor.withValues(alpha: 0.12),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow_rounded,
              color: Theme.of(context).primaryColor,
            ),
          ),
          title: Text(msg.senderName),
          subtitle: Text(
            FormattedDate.getFormattedDate(
              DateTime.parse(
                msg.createdAt.toString(),
              ).toLocal().toIso8601String(),
            ),
          ),
          onTap: () => setState(() => _playingId = isPlaying ? null : msg.id),
        );
      },
    );
  }
}

class _LinksList extends StatelessWidget {
  final List<GroupMessageModel> items;
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

    return ListView.separated(
      itemCount: confirmed.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final msg = confirmed[index];
        return ListTile(
          leading: const Icon(Icons.link_rounded),
          title: CustomLinkifyText(text: msg.text, maxLines: 2),
          subtitle: Text(
            '${msg.senderName} · ${FormattedDate.getFormattedDate(msg.createdAt.toString())}',
          ),
        );
      },
    );
  }
}

class _FullScreenNetworkImage extends StatelessWidget {
  final String url;
  const _FullScreenNetworkImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
      ),
    );
  }
}

class _FullScreenNetworkVideo extends StatefulWidget {
  final String url;
  const _FullScreenNetworkVideo({required this.url});

  @override
  State<_FullScreenNetworkVideo> createState() =>
      _FullScreenNetworkVideoState();
}

class _FullScreenNetworkVideoState extends State<_FullScreenNetworkVideo> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child:
            _controller.value.isInitialized
                ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: GestureDetector(
                    onTap:
                        () => setState(
                          () =>
                              _controller.value.isPlaying
                                  ? _controller.pause()
                                  : _controller.play(),
                        ),
                    child: VideoPlayer(_controller),
                  ),
                )
                : const CustomLoadingIndicator(color: Colors.white),
      ),
    );
  }
}
