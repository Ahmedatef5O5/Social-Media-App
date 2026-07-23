import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../models/message_model.dart';
import 'message_time_and_status.dart';

class CallMessageContent extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool hasReaction;
  final double maxBubbleWidth;

  const CallMessageContent({
    super.key,
    required this.message,
    required this.isMe,
    required this.hasReaction,
    required this.maxBubbleWidth,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> callData = {};
    try {
      callData = jsonDecode(message.text) as Map<String, dynamic>;
    } catch (_) {}

    final status = callData['status'] as String? ?? 'ended';
    final callType = callData['call_type'] as String? ?? 'audio';
    final duration = callData['duration'] as String? ?? '';

    final bool isAudio = callType == 'audio';
    final bool isMissed = status == 'rejected' || status == 'missed';

    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final IconData icon =
        isMissed
            ? (isAudio ? Icons.call_missed : Icons.missed_video_call)
            : (isAudio ? Icons.call : Icons.videocam);

    final Color bubbleBg =
        isMe
            ? Theme.of(context).primaryColor.withValues(alpha: 0.95)
            : (isDarkMode
                ? colorScheme.surfaceContainerHigh
                : Colors.grey.shade200);

    final Color textColor =
        isMe
            ? colorScheme.onPrimary
            : colorScheme.onSurface.withValues(alpha: 0.7);
    final Color timeColor =
        isMe
            ? Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8)
            : Theme.of(context).scaffoldBackgroundColor;

    final Color iconColor =
        isMe
            ? colorScheme.onPrimary
            : (isMissed ? Colors.redAccent : Colors.green);

    final Color iconBgColor =
        isMe
            ? Colors.white.withValues(alpha: 0.5)
            : iconColor.withValues(alpha: 0.15);

    String title =
        isMissed
            ? (isAudio ? 'Missed voice call' : 'Missed video call')
            : (isAudio ? 'Voice call' : 'Video call');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(top: 2, bottom: hasReaction ? 28 : 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          constraints: BoxConstraints(maxWidth: maxBubbleWidth, minWidth: 180),
          decoration: BoxDecoration(
            color: bubbleBg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const Gap(12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium!.copyWith(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (duration.isNotEmpty && !isMissed) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Gap(2),
                              Icon(
                                Icons.timer_outlined,
                                size: 11,
                                color: isMe ? timeColor : null,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                duration,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium!.copyWith(
                                  color: isMe ? timeColor : null,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(6),
              Align(
                alignment: Alignment.bottomRight,
                child: MessageTimeAndStatus(
                  message: message,
                  isMe: isMe,
                  iconColor: timeColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
