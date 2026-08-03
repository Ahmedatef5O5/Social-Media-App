import 'package:flutter/material.dart';
import '../models/starred_message_entry.dart';
import '../widgets/empty_starred_msg_state.dart';
import '../widgets/starred_message_tile.dart';

class StarredMessagesView extends StatefulWidget {
  final List<StarredMessageEntry> entries;

  final void Function(String messageId) onTapEntry;

  final Future<void> Function(String messageId) onUnstar;

  const StarredMessagesView({
    super.key,
    required this.entries,
    required this.onTapEntry,
    required this.onUnstar,
  });

  @override
  State<StarredMessagesView> createState() => _StarredMessagesViewState();
}

class _StarredMessagesViewState extends State<StarredMessagesView> {
  late List<StarredMessageEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = [...widget.entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _handleUnstar(StarredMessageEntry entry) async {
    setState(() => _entries.removeWhere((e) => e.id == entry.id));
    await widget.onUnstar(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Starred'),
        centerTitle: false,
        elevation: 0,
      ),
      body:
          _entries.isEmpty
              ? EmptyStarredMsgState()
              : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return StarredMessageTile(
                    entry: entry,
                    onTap: () => widget.onTapEntry(entry.id),
                    onUnstar: () => _handleUnstar(entry),
                  );
                },
              ),
    );
  }
}
