import 'package:flutter/material.dart';
import 'package:social_media_app/features/single_chats/widgets/chat_bubble_shimmer.dart';
import '../models/starred_message_entry.dart';
import '../widgets/empty_starred_msg_state.dart';
import '../widgets/starred_message_tile.dart';

class StarredMessagesView extends StatefulWidget {
  final Future<List<StarredMessageEntry>> Function() entriesLoader;
  final void Function(String messageId) onTapEntry;
  final Future<void> Function(String messageId) onUnstar;

  const StarredMessagesView({
    super.key,
    required this.entriesLoader,
    required this.onTapEntry,
    required this.onUnstar,
  });

  @override
  State<StarredMessagesView> createState() => _StarredMessagesViewState();
}

class _StarredMessagesViewState extends State<StarredMessagesView> {
  List<StarredMessageEntry>? _entries;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final loaded = await widget.entriesLoader();
    if (!mounted) return;
    setState(() {
      _entries = [...loaded]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _handleUnstar(StarredMessageEntry entry) async {
    setState(() => _entries?.removeWhere((e) => e.id == entry.id));
    await widget.onUnstar(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,

            leadingWidth: 56,
            leading: Center(
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: primaryColor.withValues(alpha: 0.08),
                  shape: const CircleBorder(),
                  fixedSize: const Size(38, 38),
                  minimumSize: const Size(38, 38),
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: primaryColor,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            titleSpacing: 4,
            centerTitle: false,
            title: const Text(
              'Starred Messages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),

            actions: [
              if (entries != null && entries.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${entries.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          if (entries == null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ChatBubbleShimmer(
                    isMe: index.isEven,
                    showAvatar: true,
                    widthMultiplier: index.isEven ? 0.55 : 0.4,
                  ),
                  childCount: 8,
                ),
              ),
            )
          else if (entries.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStarredMsgState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = entries[index];
                  return StarredMessageTile(
                    key: ValueKey(entry.id),
                    entry: entry,
                    onTap: () => widget.onTapEntry(entry.id),
                    onUnstar: () => _handleUnstar(entry),
                  );
                }, childCount: entries.length),
              ),
            ),
        ],
      ),
    );
  }
}
