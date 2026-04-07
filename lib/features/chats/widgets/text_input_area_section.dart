import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:social_media_app/features/chats/views/media_preview_screen.dart';
import 'package:social_media_app/features/chats/widgets/custom_icon_btn_widget.dart';
import 'package:social_media_app/features/chats/widgets/reply_preview_widget.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../cubit/chat_details_cubit/chat_details_cubit.dart';
import '../models/chat_user_model.dart';
import '../models/message_model.dart';

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

  @override
  void initState() {
    super.initState();
    widget.messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final notEmpty = widget.messageController.text.trim().isNotEmpty;

    if (notEmpty != _isTextNotEmpty) {
      setState(() => _isTextNotEmpty = notEmpty);
    }

    final cubit = context.read<ChatDetailsCubit>();

    if (notEmpty) {
      cubit.onUserTyping(widget.receiverUser.id);
    } else {
      cubit.stopTyping(widget.receiverUser.id);
    }
  }

  @override
  void dispose() {
    if (_isRecording) {
      _audioRecorder.stop();
    }
    _audioRecorder.dispose();

    widget.messageController.removeListener(_onTextChanged);
    try {
      context.read<ChatDetailsCubit>().stopTyping(widget.receiverUser.id);
    } catch (e) {
      debugPrint("Cubit already disposed or inaccessible");
    }
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
            onCancel: widget.onCancelReply ?? () {},
          ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(color: AppColors.transparent),
          child: Padding(
            padding: const EdgeInsets.only(left: 2, right: 2, bottom: 3),
            child: SafeArea(
              bottom: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconBtnWidget(
                    icon: Icons.add,
                    onTap: () => _showMediaOptions(context),
                    size: 27,
                    padding: EdgeInsets.only(bottom: 11, left: 3, right: 3),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: widget.messageController,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hoverColor: AppColors.white,
                          hintText: "Type a message...",
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
                          onLongPressStart: (_) async {
                            if (await _audioRecorder.hasPermission()) {
                              final dir =
                                  await getApplicationDocumentsDirectory();
                              final path =
                                  '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
                              await _audioRecorder.start(
                                const RecordConfig(
                                  encoder: AudioEncoder.aacLc,
                                  bitRate: 128000,
                                  sampleRate: 44100,
                                ),
                                path: path,
                              );
                              setState(() => _isRecording = true);
                            }
                          },

                          onLongPressEnd: (_) async {
                            final path = await _audioRecorder.stop();
                            setState(() => _isRecording = false);

                            if (path == null) return;

                            final file = File(path);

                            int retries = 10;
                            while (!await file.exists() && retries > 0) {
                              await Future.delayed(
                                const Duration(milliseconds: 300),
                              );
                              retries--;
                            }

                            if (!await file.exists()) {
                              debugPrint(
                                'Error: Recording file not found at $path',
                              );
                              return;
                            }

                            final fileSize = await file.length();
                            if (fileSize < 1000) {
                              debugPrint(
                                'Recording too short or empty: $fileSize bytes',
                              );
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
                          },
                          child: Icon(
                            _isRecording ? Icons.mic : Icons.mic_none,
                            color:
                                _isRecording
                                    ? Colors.red
                                    : Theme.of(context).primaryColor,
                            size: 28,
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
                                    caption:
                                        caption?.isEmpty == true
                                            ? null
                                            : caption,
                                  ),
                            ),
                          ),
                    ),
                  );
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
                final XFile? pickedFile = await picker.pickVideo(
                  source: ImageSource.gallery,
                );
                if (pickedFile != null && context.mounted) {
                  final directory = await getApplicationDocumentsDirectory();
                  final String fileName =
                      "${DateTime.now().millisecondsSinceEpoch}.mp4";
                  final File savedVideo = await File(
                    pickedFile.path,
                  ).copy('${directory.path}/$fileName');

                  final chatCubit = context.read<ChatDetailsCubit>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => BlocProvider.value(
                            value: chatCubit,
                            child: MediaPreviewScreen(
                              file: File(savedVideo.path),
                              type: 'video',
                              onSend: (caption) {
                                chatCubit.sendMessage(
                                  receiverId: widget.receiverUser.id,
                                  messageText: '',
                                  messageType: 'video',
                                  videoFile: savedVideo,
                                  caption:
                                      caption?.isEmpty == true ? null : caption,
                                );
                              },
                            ),
                          ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
