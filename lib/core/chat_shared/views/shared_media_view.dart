import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../controllers/voice_playback_controller.dart';
import '../cubits/shared_media_cubit/shared_media_cubit.dart';
import '../widgets/media_tab_view_widget.dart';

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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Shared Media',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          titleSpacing: 0,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
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
                      (tab) => MediaTabView(
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
