import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/audio/helpers/pulsing_mic_dot.dart';
import '../../../core/presence/models/chat_action_type.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../../core/widgets/animated_activity_text.dart';
import '../../../core/widgets/overlapping_avatar_stack.dart';
import '../../single_chats/widgets/typing_indicator_widget.dart';
import '../models/group_presence_entry.dart';

class GroupPresenceBubbleRow extends StatelessWidget {
  final GroupPresenceSnapshot snapshot;
  const GroupPresenceBubbleRow({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (snapshot.typing.isNotEmpty) {
      rows.add(
        _ActionBubble(entries: snapshot.typing, action: ChatActionType.typing),
      );
    }
    if (snapshot.recording.isNotEmpty) {
      rows.add(
        _ActionBubble(
          entries: snapshot.recording,
          action: ChatActionType.recording,
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

class _ActionBubble extends StatelessWidget {
  final List<GroupPresenceEntry> entries;
  final ChatActionType action;
  const _ActionBubble({required this.entries, required this.action});

  @override
  Widget build(BuildContext context) {
    final isRecording = action == ChatActionType.recording;
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleColor =
        isRecording
            ? (isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.shade50)
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade200);

    final borderColor =
        isRecording
            ? (isDark ? Colors.red.shade700 : Colors.red.shade200)
            : Colors.transparent;

    final dotColor = isDark ? Colors.white70 : Colors.black54;

    Widget avatarWidget;
    if (entries.length == 1) {
      final user = entries.first;
      final hasAvatar = user.userAvatar != null && user.userAvatar!.isNotEmpty;
      avatarWidget = PresenceAvatarWidget(
        userId: user.userId,
        avatarSize: 32,
        showBorder: false,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: primary.withValues(alpha: 0.12),
          backgroundImage:
              hasAvatar ? CachedNetworkImageProvider(user.userAvatar!) : null,
          child:
              !hasAvatar
                  ? Text(
                    user.userName.isNotEmpty
                        ? user.userName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : null,
        ),
      );
    } else {
      avatarWidget = OverlappingAvatarStack(
        avatarUrls: entries.map((e) => e.userAvatar).toList(),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 0, bottom: 6, top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: avatarWidget,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              border: isRecording ? Border.all(color: borderColor) : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child:
                isRecording
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PulsingMicDot(),
                        const SizedBox(width: 8),
                        AnimatedActivityText(
                          text:
                              entries.length == 1
                                  ? '${entries.first.userName} recording audio...'
                                  : '${entries.length} people recording audio...',
                          style: TextStyle(
                            color:
                                isDark
                                    ? Colors.red.shade400
                                    : Colors.red.shade700,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                    : TypingIndicatorWidget(color: dotColor, dotSize: 5),
          ),
        ],
      ),
    );
  }
}
