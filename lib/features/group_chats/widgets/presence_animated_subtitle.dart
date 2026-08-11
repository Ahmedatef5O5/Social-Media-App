import 'package:flutter/material.dart';
import '../../../core/widgets/animated_activity_text.dart';
import '../helpers/group_presence_text_formatter.dart';
import '../helpers/presence_rotation_controller.dart';
import '../../../core/presence/model/chat_action_type.dart';
import '../models/group_presence_entry.dart';

class PresenceAnimatedSubtitle extends StatefulWidget {
  final GroupPresenceSnapshot presence;
  final Widget fallback;
  final TextStyle? activeStyle;

  const PresenceAnimatedSubtitle({
    super.key,
    required this.presence,
    required this.fallback,
    this.activeStyle,
  });

  @override
  State<PresenceAnimatedSubtitle> createState() =>
      _PresenceAnimatedSubtitleState();
}

class _PresenceAnimatedSubtitleState extends State<PresenceAnimatedSubtitle> {
  final _controller = PresenceRotationController<PresencePhrase>();

  @override
  void initState() {
    super.initState();
    _controller.update(GroupPresenceTextFormatter.format(widget.presence));
  }

  @override
  void didUpdateWidget(covariant PresenceAnimatedSubtitle old) {
    super.didUpdateWidget(old);
    _controller.update(GroupPresenceTextFormatter.format(widget.presence));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PresencePhrase?>(
      valueListenable: _controller.current,
      builder: (context, phrase, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Align(
            key: ValueKey(phrase == null ? 'fallback' : phrase.text),
            alignment: Alignment.centerLeft,
            child:
                phrase == null
                    ? widget.fallback
                    : AnimatedActivityText(
                      text: phrase.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (widget.activeStyle ??
                              const TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ))
                          .copyWith(
                            color:
                                phrase.action == ChatActionType.recording
                                    ? Colors.red.shade700
                                    : (widget.activeStyle?.color ??
                                        Colors.green.shade600),
                          ),
                    ),
          ),
        );
      },
    );
  }
}
