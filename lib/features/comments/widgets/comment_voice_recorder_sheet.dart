import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/features/comments/models/comment_attachment_draft.dart';
import 'package:social_media_app/features/comments/models/comment_type.dart';

class CommentVoiceRecorderSheet extends StatefulWidget {
  const CommentVoiceRecorderSheet({super.key});

  @override
  State<CommentVoiceRecorderSheet> createState() =>
      _CommentVoiceRecorderSheetState();
}

class _CommentVoiceRecorderSheetState extends State<CommentVoiceRecorderSheet> {
  final _recorder = AudioRecorder();
  Timer? _timer;
  int _seconds = 0;
  bool _isRecording = false;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (!mounted) return;

        setState(() {
          _isInitializing = false;
          _errorMessage = 'Microphone permission denied';
        });
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/comment_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });

      if (mounted) {
        setState(() {
          _isRecording = true;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Could not start recording';
        });
      }
    }
  }

  Future<void> _stopAndSend() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    if (!mounted) return;

    if (path == null || _seconds < 1) {
      Navigator.of(context).pop();
      return;
    }

    final size = await File(path).length();
    if (!mounted) return;

    Navigator.of(context).pop(
      CommentAttachmentDraft(
        type: CommentType.voice,
        localFile: File(path),
        durationSeconds: _seconds,
        fileSizeBytes: size,
      ),
    );
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              _errorMessage != null
                  ? [
                    Icon(
                      Icons.mic_off_rounded,
                      color: AppColors.grey6,
                      size: 40,
                    ),
                    const Gap(12),
                    Text(_errorMessage!, style: theme.textTheme.bodyMedium),
                    const Gap(16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ]
                  : [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.9, end: _isRecording ? 1.1 : 1.0),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent.withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.redAccent,
                          size: 38,
                        ),
                      ),
                    ),
                    const Gap(16),
                    Text(
                      _isInitializing ? 'Preparing...' : _formattedTime,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Recording voice message',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.grey6,
                      ),
                    ),
                    const Gap(24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RoundButton(
                          icon: Icons.close_rounded,
                          color: AppColors.grey6,
                          onTap: _cancel,
                        ),
                        const Gap(28),
                        _RoundButton(
                          icon: Icons.check_rounded,
                          color: Colors.white,
                          background: theme.primaryColor,
                          onTap: _isRecording ? _stopAndSend : null,
                        ),
                      ],
                    ),
                  ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? background;
  final VoidCallback? onTap;

  const _RoundButton({
    required this.icon,
    required this.color,
    this.background,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background ?? AppColors.grey5.withValues(alpha: 0.15),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}
