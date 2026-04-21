import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:social_media_app/features/group_chat/widgets/reply_preview_section.dart';
import 'package:video_player/video_player.dart';
import '../cubit/group_details_cubit/group_details_cubit.dart';

class GroupChatInputBarSection extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final VoidCallback onTyping;

  const GroupChatInputBarSection({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onTyping,
  });

  @override
  State<GroupChatInputBarSection> createState() =>
      _GroupChatInputBarSectionState();
}

class _GroupChatInputBarSectionState extends State<GroupChatInputBarSection> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final notEmpty = widget.controller.text.trim().isNotEmpty;
    if (notEmpty != _hasText) setState(() => _hasText = notEmpty);
    if (notEmpty) widget.onTyping();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    if (_isRecording) _audioRecorder.stop();
    _audioRecorder.dispose();
    super.dispose();
  }

  // ── Voice recording ──────────────────────────────────────────────

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
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path == null) return;

    final file = File(path);
    // Wait for file to be flushed
    int retries = 10;
    while (!await file.exists() && retries-- > 0) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!await file.exists()) return;
    final size = await file.length();
    if (size < 1000) {
      await file.delete();
      return;
    }

    if (mounted) {
      context.read<GroupDetailsCubit>().sendMessage(
        text: '',
        messageType: 'voice',
        voiceFile: file,
      );
    }
  }

  // ── Media picker ─────────────────────────────────────────────────

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Send Image'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickAndSendImage();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.videocam,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Send Video'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickAndSendVideo();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _takePhoto();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final cubit = context.read<GroupDetailsCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (ctx) => BlocProvider.value(
              value: cubit,
              child: _GroupMediaPreviewScreen(
                file: File(picked.path),
                type: 'image',
                onSend: (caption) {
                  cubit.sendMessage(
                    text: '',
                    messageType: 'image',
                    imageFile: File(picked.path),
                    caption: caption,
                  );
                },
              ),
            ),
      ),
    );
  }

  Future<void> _pickAndSendVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final cubit = context.read<GroupDetailsCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (ctx) => BlocProvider.value(
              value: cubit,
              child: _GroupMediaPreviewScreen(
                file: File(picked.path),
                type: 'video',
                onSend: (caption) {
                  cubit.sendMessage(
                    text: '',
                    messageType: 'video',
                    videoFile: File(picked.path),
                    caption: caption,
                  );
                },
              ),
            ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null || !mounted) return;

    final cubit = context.read<GroupDetailsCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (ctx) => BlocProvider.value(
              value: cubit,
              child: _GroupMediaPreviewScreen(
                file: File(picked.path),
                type: 'image',
                onSend: (caption) {
                  cubit.sendMessage(
                    text: '',
                    messageType: 'image',
                    imageFile: File(picked.path),
                    caption: caption,
                  );
                },
              ),
            ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reply preview bar
        GroupReplyPreviewSection(cubit: context.read<GroupDetailsCubit>()),

        // Input row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button
                _BarIconButton(
                  icon: Icons.add,
                  color: primary,
                  onTap: _showMediaOptions,
                ),

                const Gap(4),

                // Text field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      onChanged: (_) => widget.onTyping(),
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: _isRecording ? '🎤 Recording…' : 'Message',
                        hintStyle: TextStyle(
                          color:
                              _isRecording
                                  ? Colors.red
                                  : (isDark ? Colors.white38 : Colors.black38),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),

                const Gap(8),

                // Send / Mic button
                _hasText
                    ? _SendButton(
                      primary: primary,
                      onTap: () {
                        final text = widget.controller.text.trim();
                        if (text.isEmpty) return;
                        widget.onSend(text);
                        widget.controller.clear();
                      },
                    )
                    : _MicButton(
                      isRecording: _isRecording,
                      primary: primary,
                      onLongPressStart: (_) => _startRecording(),
                      onLongPressEnd: (_) => _stopRecording(),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _BarIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _BarIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Icon(icon, color: color, size: 27),
    ),
  );
}

class _SendButton extends StatelessWidget {
  final Color primary;
  final VoidCallback onTap;
  const _SendButton({required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
      ),
    ),
  );
}

class _MicButton extends StatelessWidget {
  final bool isRecording;
  final Color primary;
  final void Function(LongPressStartDetails) onLongPressStart;
  final void Function(LongPressEndDetails) onLongPressEnd;

  const _MicButton({
    required this.isRecording,
    required this.primary,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPressStart: onLongPressStart,
    onLongPressEnd: onLongPressEnd,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Icon(
        isRecording ? Icons.mic : Icons.mic_none,
        color: isRecording ? Colors.red : primary,
        size: 28,
      ),
    ),
  );
}

// ── Media Preview Screen (reused from single chat pattern) ────────────────────

class _GroupMediaPreviewScreen extends StatefulWidget {
  final File file;
  final String type; // 'image' | 'video'
  final Function(String? caption) onSend;

  const _GroupMediaPreviewScreen({
    required this.file,
    required this.type,
    required this.onSend,
  });

  @override
  State<_GroupMediaPreviewScreen> createState() =>
      _GroupMediaPreviewScreenState();
}

class _GroupMediaPreviewScreenState extends State<_GroupMediaPreviewScreen> {
  final _captionController = TextEditingController();
  VideoPlayerController? _videoCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video') {
      _videoCtrl = VideoPlayerController.file(widget.file)
        ..initialize().then((_) {
          setState(() {});
          _videoCtrl!.play();
          _videoCtrl!.setLooping(true);
        });
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    _captionController.dispose();
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
      body: Column(
        children: [
          Expanded(
            child: Center(
              child:
                  widget.type == 'image'
                      ? Image.file(widget.file, fit: BoxFit.contain)
                      : (_videoCtrl?.value.isInitialized == true
                          ? AspectRatio(
                            aspectRatio: _videoCtrl!.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                VideoPlayer(_videoCtrl!),
                                GestureDetector(
                                  onTap:
                                      () => setState(
                                        () =>
                                            _videoCtrl!.value.isPlaying
                                                ? _videoCtrl!.pause()
                                                : _videoCtrl!.play(),
                                      ),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.black54,
                                    child: Icon(
                                      _videoCtrl!.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow_rounded,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            color: Colors.black54,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add a caption…',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const Gap(8),
                  GestureDetector(
                    onTap: () {
                      final caption = _captionController.text.trim();
                      Navigator.pop(context);
                      widget.onSend(caption.isEmpty ? null : caption);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
