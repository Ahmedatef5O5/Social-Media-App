import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/widgets/waveform_progress_bar.dart';

class CommentVoicePlayer extends StatefulWidget {
  final String source;
  final bool isLocalFile;
  final int? durationSeconds;
  final Color? accentColor;
  final bool showBubbleBackground;

  const CommentVoicePlayer({
    super.key,
    required this.source,
    this.isLocalFile = false,
    this.durationSeconds,
    this.accentColor,
    this.showBubbleBackground = false,
  });

  @override
  State<CommentVoicePlayer> createState() => _CommentVoicePlayerState();
}

class _CommentVoicePlayerState extends State<CommentVoicePlayer> {
  static _CommentVoicePlayerState? _activePlayer;
  final _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  bool _hasSetSource = false;

  @override
  void initState() {
    super.initState();
    _total = Duration(seconds: widget.durationSeconds ?? 0);
    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    _player.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _total = d);
    });
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  Future<void> _toggle() async {
    if (_activePlayer != null && _activePlayer != this) {
      await _activePlayer!._player.pause();
    }
    _activePlayer = this;

    if (_isPlaying) {
      await _player.pause();
      return;
    }

    if (!_hasSetSource ||
        _player.state == PlayerState.completed ||
        _player.state == PlayerState.stopped) {
      final audioSource =
          widget.isLocalFile
              ? DeviceFileSource(widget.source)
              : UrlSource(widget.source);

      await _player.play(audioSource);
      _hasSetSource = true;
    } else {
      await _player.resume();
    }
  }

  Future<void> _seek(Duration target) async {
    try {
      if (_player.state == PlayerState.completed ||
          _player.state == PlayerState.stopped) {
        return;
      }
      await _player.seek(target);
    } catch (e) {
      debugPrint('Voice comment seek error: $e');
    }
  }

  @override
  void dispose() {
    if (_activePlayer == this) {
      _activePlayer = null;
    }
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? Theme.of(context).primaryColor;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _toggle,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: color,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          height: 24,
          child: WaveformProgressBar(
            seed: widget.source,
            position: _position,
            duration: _total,
            activeColor: color,
            inactiveColor: AppColors.grey5.withValues(alpha: 0.5),
            onSeek: _seek,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _isPlaying || _position > Duration.zero
              ? _format(_position)
              : _format(_total),
          style: TextStyle(fontSize: 11, color: AppColors.grey6),
        ),
      ],
    );

    if (!widget.showBubbleBackground) return content;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: content,
    );
  }
}
