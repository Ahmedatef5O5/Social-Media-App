import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import 'package:social_media_app/features/comments/widgets/comment_voice_player.dart';

class FeedbackVoiceRecorder extends StatefulWidget {
  final File? file;
  final int seconds;
  final void Function(File? file, int seconds) onChanged;
  final bool enabled;

  const FeedbackVoiceRecorder({
    super.key,
    required this.file,
    required this.seconds,
    required this.onChanged,
    this.enabled = true,
  });

  static const int maxSeconds = 120;

  @override
  State<FeedbackVoiceRecorder> createState() => _FeedbackVoiceRecorderState();
}

class _FeedbackVoiceRecorderState extends State<FeedbackVoiceRecorder> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  int _elapsed = 0;
  bool _recording = false;
  bool _starting = false;

  @override
  void dispose() {
    _timer?.cancel();
    () async {
      try {
        if (await _recorder.isRecording()) await _recorder.stop();
      } catch (_) {}
      await _recorder.dispose();
    }();
    super.dispose();
  }

  Future<void> _start() async {
    if (_starting || _recording || !widget.enabled) return;
    setState(() => _starting = true);
    try {
      if (!await _recorder.hasPermission()) {
        AppToast.warning('Microphone permission is required to record.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/feedback_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      HapticFeedback.mediumImpact();
      _elapsed = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsed++);
        if (_elapsed >= FeedbackVoiceRecorder.maxSeconds) _stop();
      });
      if (mounted) setState(() => _recording = true);
    } catch (e) {
      AppToast.error('Could not start recording.');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    final seconds = _elapsed;
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _recording = false);

    if (path == null || seconds < 1) {
      AppToast.info('Recording was too short.');
      return;
    }
    widget.onChanged(File(path), seconds);
  }

  Future<void> _delete() async {
    final f = widget.file;
    widget.onChanged(null, 0);
    try {
      if (f != null && await f.exists()) await f.delete();
    } catch (_) {}
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100;

    if (widget.file != null && !_recording) {
      return Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: CommentVoicePlayer(
                key: ValueKey(widget.file!.path),
                source: widget.file!.path,
                isLocalFile: true,
                durationSeconds: widget.seconds,
              ),
            ),
            IconButton(
              tooltip: 'Delete voice note',
              onPressed: widget.enabled ? _delete : null,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFE5484D),
              ),
            ),
          ],
        ),
      );
    }

    if (_recording) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            const _PulsingDot(),
            const SizedBox(width: 10),
            Text(
              _fmt(_elapsed),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              '  /  ${_fmt(FeedbackVoiceRecorder.maxSeconds)}',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
            ),
            const Spacer(),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: _stop,
              icon: const Icon(Icons.stop_rounded, size: 20),
              label: const Text('Stop'),
            ),
          ],
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: widget.enabled ? _start : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.mic_rounded, color: theme.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Record a voice note (up to ${FeedbackVoiceRecorder.maxSeconds ~/ 60} min)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (_starting)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
    child: Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
      ),
    ),
  );
}
