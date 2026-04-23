import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/group_chat/widgets/bar_icon_button.dart';
import '../helpers/mic_button.dart';
import '../helpers/recording_indicator.dart';
import '../helpers/send_button.dart';

class InputBar extends StatelessWidget {
  final bool isRecording;
  final bool hasText;
  final int seconds;
  final TextEditingController controller;
  final VoidCallback onTyping;
  final Function(String) onSend;
  final VoidCallback onShowMedia;
  final Future<void> Function() onStartRecording;
  final Future<void> Function() onStopRecording;

  const InputBar({
    super.key,
    required this.isRecording,
    required this.hasText,
    required this.seconds,
    required this.controller,
    required this.onTyping,
    required this.onSend,
    required this.onShowMedia,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: [
          BarIconButton(icon: Icons.add, color: primary, onTap: onShowMedia),

          const Gap(4),

          Expanded(
            child: AnimatedContainer(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color:
                    isRecording
                        ? Colors.red.withValues(alpha: 0.10)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : primary.withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(24),
              ),
              child:
                  isRecording
                      ? RecordingIndicator(seconds: seconds)
                      : TextField(
                        controller: controller,
                        onChanged: (_) => onTyping(),
                        minLines: 1,
                        maxLines: 5,
                        cursorColor: Colors.blueGrey.shade400,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hoverColor: Colors.white,
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 2,
                          ),
                        ),
                      ),
            ),
          ),

          const Gap(8),

          hasText
              ? SendButton(
                primary: primary,
                onTap: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  onSend(text);
                  controller.clear();
                },
              )
              : MicButton(
                isRecording: isRecording,
                primary: primary,
                onStart: onStartRecording,
                onEnd: onStopRecording,
              ),
        ],
      ),
    );
  }
}
