import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../cubit/chat_details_cubit/chat_details_cubit.dart';
import '../models/chat_user_model.dart';
import '../models/message_model.dart';
import '../views/media_preview_screen.dart';
import 'custom_icon_btn_widget.dart';
import 'reply_preview_widget.dart';

class TextInputAreaSection extends StatefulWidget {
  final TextEditingController messageController;
  final ChatUserModel receiverUser;
  final MessageModel? replyTo;
  final VoidCallback? onCancelReply;

  const TextInputAreaSection({
    super.key,
    required this.messageController,
    required this.receiverUser,
    this.replyTo,
    this.onCancelReply,
  });

  @override
  State<TextInputAreaSection> createState() => _TextInputAreaSectionState();
}

class _TextInputAreaSectionState extends State<TextInputAreaSection> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isTextNotEmpty = false;

  int _recordSeconds = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    widget.messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final notEmpty = widget.messageController.text.trim().isNotEmpty;
    if (notEmpty != _isTextNotEmpty) setState(() => _isTextNotEmpty = notEmpty);
    final cubit = context.read<ChatDetailsCubit>();
    if (notEmpty) {
      cubit.onUserTyping(widget.receiverUser.id);
    } else {
      cubit.stopTyping(widget.receiverUser.id);
    }
  }

  Future<void> _startRecording() async {
    if (!await _audioRecorder.hasPermission()) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );
    _recordSeconds = 0;
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds++);
    });
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });

    if (path == null) return;
    final file = File(path);

    int retries = 10;
    while (!await file.exists() && retries-- > 0) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!await file.exists()) return;

    final fileSize = await file.length();
    if (fileSize < 1000) {
      await file.delete();
      return;
    }

    if (context.mounted) {
      context.read<ChatDetailsCubit>().sendMessage(
        receiverId: widget.receiverUser.id,
        messageText: '',
        messageType: 'voice',
        voiceFile: file,
        replyTo: widget.replyTo,
      );
      widget.onCancelReply?.call();
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    if (_isRecording) _audioRecorder.stop();
    _audioRecorder.dispose();
    widget.messageController.removeListener(_onTextChanged);
    try {
      context.read<ChatDetailsCubit>().stopTyping(widget.receiverUser.id);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.replyTo != null)
          ReplyPreviewBar(
            replyTo: widget.replyTo!,
            isMe:
                widget.replyTo!.senderId ==
                context.read<ChatDetailsCubit>().currentUserId,
            senderName:
                widget.replyTo!.senderId ==
                        context.read<ChatDetailsCubit>().currentUserId
                    ? 'You'
                    : widget.receiverUser.name,
            onCancel: widget.onCancelReply ?? () {},
          ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: const BoxDecoration(color: AppColors.transparent),
          child: Padding(
            padding: const EdgeInsets.only(left: 2, right: 2, bottom: 3),
            child: SafeArea(
              top: false,
              bottom: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomIconBtnWidget(
                    icon: Icons.add,
                    onTap: () => _showMediaOptions(context),
                    size: 27,
                    padding: const EdgeInsets.only(
                      bottom: 11,
                      left: 3,
                      right: 3,
                    ),
                  ),

                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color:
                            _isRecording
                                ? Colors.red.withValues(alpha: 0.12)
                                : Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child:
                          _isRecording
                              ? _RecordingIndicator(seconds: _recordSeconds)
                              : TextField(
                                controller: widget.messageController,
                                minLines: 1,
                                maxLines: 5,
                                cursorColor: Colors.blueGrey.shade400,
                                textInputAction: TextInputAction.newline,
                                decoration: const InputDecoration(
                                  hoverColor: AppColors.white,
                                  hintText: 'Type a message...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 2,
                                  ),
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send / Mic button
                  _isTextNotEmpty
                      ? InkWell(
                        splashColor: AppColors.transparent,
                        onTap: () {
                          final text = widget.messageController.text.trim();
                          if (text.isNotEmpty) {
                            context.read<ChatDetailsCubit>().sendMessage(
                              receiverId: widget.receiverUser.id,
                              messageText: text,
                              replyTo: widget.replyTo,
                            );
                            widget.messageController.clear();
                            context.read<ChatDetailsCubit>().stopTyping(
                              widget.receiverUser.id,
                            );
                            widget.onCancelReply?.call();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Image.asset(
                            AppImages.sendIcon,
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.95),
                            width: 28,
                            height: 28,
                          ),
                        ),
                      )
                      : Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onLongPressStart: (_) => _startRecording(),
                          onLongPressEnd: (_) => _stopRecording(),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _isRecording ? Icons.mic : Icons.mic_none,
                              key: ValueKey(_isRecording),
                              color:
                                  _isRecording
                                      ? Colors.red
                                      : Theme.of(context).primaryColor,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showMediaOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Send Image'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final file = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (file != null && context.mounted) {
                  final chatCubit = context.read<ChatDetailsCubit>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => BlocProvider.value(
                            value: chatCubit,
                            child: MediaPreviewScreen(
                              file: File(file.path),
                              type: 'image',
                              onSend:
                                  (caption) => chatCubit.sendMessage(
                                    receiverId: widget.receiverUser.id,
                                    messageText: '',
                                    messageType: 'image',
                                    imageFile: File(file.path),
                                    caption: caption,
                                    replyTo: widget.replyTo,
                                  ),
                            ),
                          ),
                    ),
                  );
                  widget.onCancelReply?.call();
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.videocam,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Send Video'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final file = await picker.pickVideo(
                  source: ImageSource.gallery,
                );
                if (file != null && context.mounted) {
                  final chatCubit = context.read<ChatDetailsCubit>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => BlocProvider.value(
                            value: chatCubit,
                            child: MediaPreviewScreen(
                              file: File(file.path),
                              type: 'video',
                              onSend:
                                  (caption) => chatCubit.sendMessage(
                                    receiverId: widget.receiverUser.id,
                                    messageText: '',
                                    messageType: 'video',
                                    videoFile: File(file.path),
                                    caption: caption,
                                    replyTo: widget.replyTo,
                                  ),
                            ),
                          ),
                    ),
                  );
                  widget.onCancelReply?.call();
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class _RecordingIndicator extends StatelessWidget {
  final int seconds;
  const _RecordingIndicator({required this.seconds});

  String get _formatted {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.red, size: 18),
          const SizedBox(width: 6),
          // Animated pulsing dot
          _PulsingDot(),
          const SizedBox(width: 6),
          Text(
            _formatted,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            'Release to send',
            style: TextStyle(
              color: Colors.red.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
