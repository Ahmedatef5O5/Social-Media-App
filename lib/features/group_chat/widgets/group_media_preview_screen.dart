import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:video_player/video_player.dart';

class GroupMediaPreviewScreen extends StatefulWidget {
  final File file;
  final String type;
  final Function(String? caption) onSend;

  const GroupMediaPreviewScreen({
    super.key,
    required this.file,
    required this.type,
    required this.onSend,
  });

  @override
  State<GroupMediaPreviewScreen> createState() =>
      _GroupMediaPreviewScreenState();
}

class _GroupMediaPreviewScreenState extends State<GroupMediaPreviewScreen> {
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
