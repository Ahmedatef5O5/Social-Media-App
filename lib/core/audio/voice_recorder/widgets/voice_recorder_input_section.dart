import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/core/widgets/waveform_progress_bar.dart';

import '../services/voice_chunk_recorder_service.dart';

enum _RecordUiState { idle, recording, locked }

class VoiceRecorderInputSection extends StatefulWidget {
  final Widget textField;
  final bool hasText;
  final Widget sendButton;
  final VoidCallback onShowAttachments;
  final void Function(File file, int durationSeconds) onSendVoice;

  const VoiceRecorderInputSection({
    super.key,
    required this.textField,
    required this.hasText,
    required this.sendButton,
    required this.onShowAttachments,
    required this.onSendVoice,
  });

  @override
  State<VoiceRecorderInputSection> createState() =>
      _VoiceRecorderInputSectionState();
}

class _VoiceRecorderInputSectionState extends State<VoiceRecorderInputSection> {
  static const double _lockThreshold = 80.0;
  static const double _cancelThreshold = 120.0;
  static const int _maxLiveBars = 40;

  final VoiceChunkRecorderService _recorderService =
      VoiceChunkRecorderService();
  final AudioPlayer _previewPlayer = AudioPlayer();

  Timer? _ticker;
  Timer? _amplitudeTimer;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _completeSub;

  _RecordUiState _uiState = _RecordUiState.idle;
  double _dragDx = 0;
  double _dragDy = 0;
  int _seconds = 0;

  bool _isPaused = false;
  String? _recordingSessionId;
  File? _previewFile;
  final List<double> _liveAmplitudes = [];

  bool _isPreviewPlaying = false;
  Duration _previewDuration = Duration.zero;
  Duration _previewPosition = Duration.zero;

  double get _lockProgress => (-_dragDy / _lockThreshold).clamp(0.0, 1.0);
  double get _cancelProgress => (-_dragDx / _cancelThreshold).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _playerStateSub = _previewPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPreviewPlaying = state == PlayerState.playing);
      }
    });
    _durationSub = _previewPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _previewDuration = d);
    });
    _positionSub = _previewPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _previewPosition = p);
    });
    _completeSub = _previewPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPreviewPlaying = false;
          _previewPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _amplitudeTimer?.cancel();
    _playerStateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _recorderService.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!await _recorderService.hasPermission) return;

    await _recorderService.start();

    _recordingSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _seconds = 0;
    _dragDx = 0;
    _dragDy = 0;
    _isPaused = false;
    _liveAmplitudes.clear();
    _previewFile = null;
    _previewDuration = Duration.zero;
    _previewPosition = Duration.zero;

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    _startAmplitudeSampling();

    if (mounted) setState(() => _uiState = _RecordUiState.recording);
  }

  void _startAmplitudeSampling() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 120), (
      _,
    ) async {
      try {
        final amp = await _recorderService.getAmplitude();
        final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
        if (!mounted) return;
        setState(() {
          _liveAmplitudes.add(normalized);
          if (_liveAmplitudes.length > _maxLiveBars) {
            _liveAmplitudes.removeAt(0);
          }
        });
      } catch (_) {}
    });
  }

  void _onDragUpdate(LongPressMoveUpdateDetails details) {
    if (_uiState != _RecordUiState.recording) return;

    final offset = details.offsetFromOrigin;
    setState(() {
      _dragDx = offset.dx;
      _dragDy = offset.dy;
    });

    if (_lockProgress >= 1.0) {
      _lockRecording();
      return;
    }
    if (_cancelProgress >= 1.0) {
      _cancelRecording();
    }
  }

  void _lockRecording() {
    HapticFeedback.mediumImpact();
    setState(() {
      _uiState = _RecordUiState.locked;
      _dragDx = 0;
      _dragDy = 0;
    });
  }

  Future<void> _pauseRecording() async {
    await _recorderService.pause();
    _amplitudeTimer?.cancel();
    _ticker?.cancel();

    final preview = await _recorderService.previewMergedSoFar();

    if (mounted) {
      setState(() {
        _isPaused = true;
        _previewFile = preview;
        _previewDuration = Duration.zero;
        _previewPosition = Duration.zero;
      });
    }
  }

  Future<void> _resumeRecording() async {
    if (_isPreviewPlaying) await _previewPlayer.stop();
    await _recorderService.resume();
    _startAmplitudeSampling();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    if (mounted) {
      setState(() {
        _isPaused = false;
        _previewPosition = Duration.zero;
      });
    }
  }

  Future<void> _togglePreviewPlayback() async {
    if (_isPreviewPlaying) {
      await _previewPlayer.pause();
      return;
    }
    if (_previewFile == null) return;
    if (_previewDuration > Duration.zero &&
        _previewPosition >= _previewDuration) {
      await _previewPlayer.seek(Duration.zero);
    }
    await _previewPlayer.play(DeviceFileSource(_previewFile!.path));
  }

  Future<void> _cancelRecording() async {
    HapticFeedback.lightImpact();
    _ticker?.cancel();
    _ticker = null;
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    if (_isPreviewPlaying) await _previewPlayer.stop();

    await _recorderService.cancelAndCleanup();

    if (mounted) {
      setState(() {
        _uiState = _RecordUiState.idle;
        _seconds = 0;
        _dragDx = 0;
        _dragDy = 0;
        _isPaused = false;
        _recordingSessionId = null;
        _previewFile = null;
        _liveAmplitudes.clear();
        _previewDuration = Duration.zero;
        _previewPosition = Duration.zero;
      });
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_uiState == _RecordUiState.locked) return;
    if (_uiState == _RecordUiState.idle) return;
    _finishAndSend();
  }

  void _onLongPressCancel() {
    if (_uiState == _RecordUiState.recording) _cancelRecording();
  }

  Future<void> _finishAndSend() async {
    _ticker?.cancel();
    _ticker = null;
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    if (_isPreviewPlaying) await _previewPlayer.stop();

    final file = await _recorderService.finishAndBuild();
    final seconds =
        file != null ? await _extractPreciseDuration(file, _seconds) : _seconds;

    if (mounted) {
      setState(() {
        _uiState = _RecordUiState.idle;
        _seconds = 0;
        _dragDx = 0;
        _dragDy = 0;
        _isPaused = false;
        _recordingSessionId = null;
        _previewFile = null;
        _liveAmplitudes.clear();
        _previewDuration = Duration.zero;
        _previewPosition = Duration.zero;
      });
    }

    if (file == null) return;

    final size = await file.length();
    if (size < 1000) {
      await file.delete();
      return;
    }

    widget.onSendVoice(file, seconds);
  }

  /// Reads the exact duration of the freshly recorded local file using a
  /// throwaway [AudioPlayer] instance (metadata probe only — never played).
  /// Falls back to the tick-based [fallbackSeconds] counter if the probe
  /// fails or returns an implausible value (e.g. 0 on some Android OEMs
  /// right after the file handle is closed).
  Future<int> _extractPreciseDuration(File file, int fallbackSeconds) async {
    AudioPlayer? probe;
    try {
      probe = AudioPlayer();
      await probe.setSourceDeviceFile(file.path);
      final duration = await probe.getDuration();
      if (duration != null && duration.inMilliseconds > 0) {
        return (duration.inMilliseconds / 1000).round();
      }
    } catch (_) {
      // Ignore — fall back to the tick counter below.
    } finally {
      await probe?.dispose();
    }
    return fallbackSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isRecordingUnlocked = _uiState == _RecordUiState.recording;
    final isLocked = _uiState == _RecordUiState.locked;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, right: 2),
          child:
              isLocked
                  ? InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _cancelRecording,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 26,
                      ),
                    ),
                  )
                  : IconButton(
                    icon: Icon(Icons.add, color: primary),
                    onPressed:
                        _uiState == _RecordUiState.idle
                            ? widget.onShowAttachments
                            : null,
                  ),
        ),

        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color:
                  _uiState == _RecordUiState.idle
                      ? primary.withValues(alpha: 0.25)
                      : Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(25),
            ),
            child: switch (_uiState) {
              _RecordUiState.idle => widget.textField,
              _RecordUiState.recording => _RecordingStatusRow(
                seconds: _seconds,
                dragDx: _dragDx,
                cancelProgress: _cancelProgress,
              ),
              _RecordUiState.locked =>
                _isPaused
                    ? _LockedPausedRow(
                      seconds: _seconds,
                      isPreviewPlaying: _isPreviewPlaying,
                      previewPosition: _previewPosition,
                      previewDuration: _previewDuration,
                      waveformSeed: _recordingSessionId ?? 'recording',
                      onTogglePlay: _togglePreviewPlayback,
                      onSeek: (d) => _previewPlayer.seek(d),
                      onResume: _resumeRecording,
                    )
                    : _LockedRecordingRow(
                      seconds: _seconds,
                      amplitudes: _liveAmplitudes,
                      onPause: _pauseRecording,
                    ),
            },
          ),
        ),

        const SizedBox(width: 8),

        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            if (isRecordingUnlocked)
              Positioned(
                bottom: 52,
                child: _LockIndicatorPill(progress: _lockProgress),
              ),

            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child:
                  isLocked
                      ? InkWell(
                        onTap: _finishAndSend,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      )
                      : widget.hasText
                      ? widget.sendButton
                      : GestureDetector(
                        onLongPressStart: (_) => _startRecording(),
                        onLongPressMoveUpdate: _onDragUpdate,
                        onLongPressEnd: _onLongPressEnd,
                        onLongPressCancel: _onLongPressCancel,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isRecordingUnlocked ? Icons.mic : Icons.mic_none,
                            key: ValueKey(isRecordingUnlocked),
                            color: isRecordingUnlocked ? Colors.red : primary,
                            size: 28,
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecordingStatusRow extends StatelessWidget {
  final int seconds;
  final double dragDx;
  final double cancelProgress;

  const _RecordingStatusRow({
    required this.seconds,
    required this.dragDx,
    required this.cancelProgress,
  });

  String get _formatted {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final visualOffset = dragDx.clamp(-70.0, 0.0);
    return Row(
      children: [
        const _PulsingRedDot(),
        const SizedBox(width: 8),
        Text(
          _formatted,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
            fontSize: 15,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Expanded(
          child: Transform.translate(
            offset: Offset(visualOffset, 0),
            child: Opacity(
              opacity: 1 - cancelProgress,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.keyboard_arrow_left_rounded,
                    color: Colors.grey,
                    size: 18,
                  ),
                  Flexible(
                    child: Text(
                      'Slide to cancel',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
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
}

class _LockedRecordingRow extends StatelessWidget {
  final int seconds;
  final List<double> amplitudes;
  final VoidCallback onPause;

  const _LockedRecordingRow({
    required this.seconds,
    required this.amplitudes,
    required this.onPause,
  });

  String get _formatted {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _PulsingRedDot(),
        const SizedBox(width: 8),
        Text(
          _formatted,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
            fontSize: 15,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _LiveWaveform(amplitudes: amplitudes)),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPause,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.pause_rounded, color: Colors.red, size: 22),
          ),
        ),
      ],
    );
  }
}

class _LockedPausedRow extends StatelessWidget {
  final int seconds;
  final bool isPreviewPlaying;
  final Duration previewPosition;
  final Duration previewDuration;
  final String waveformSeed;
  final VoidCallback onTogglePlay;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onResume;

  const _LockedPausedRow({
    required this.seconds,
    required this.isPreviewPlaying,
    required this.previewPosition,
    required this.previewDuration,
    required this.waveformSeed,
    required this.onTogglePlay,
    required this.onSeek,
    required this.onResume,
  });

  String get _formatted {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTogglePlay,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              isPreviewPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: primary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          _formatted,
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: WaveformProgressBar(
            seed: waveformSeed,
            position: previewPosition,
            duration:
                previewDuration > Duration.zero
                    ? previewDuration
                    : Duration(seconds: seconds),
            activeColor: primary,
            onSeek: onSeek,
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onResume,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic_none_rounded, color: primary, size: 16),
                const SizedBox(width: 3),
                Text(
                  'Resume',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveWaveform extends StatelessWidget {
  final List<double> amplitudes;
  const _LiveWaveform({required this.amplitudes});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (final amp in amplitudes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                width: 2.5,
                height: 4 + (amp * 20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LockIndicatorPill extends StatelessWidget {
  final double progress;
  const _LockIndicatorPill({required this.progress});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final travel = 40.0 * (1 - progress);

    return Transform.translate(
      offset: Offset(0, travel),
      child: Container(
        width: 38,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard_arrow_up_rounded,
              color: primary.withValues(alpha: 0.5 + progress * 0.5),
              size: 18,
            ),
            const SizedBox(height: 2),
            Icon(Icons.lock_outline_rounded, color: primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PulsingRedDot extends StatefulWidget {
  const _PulsingRedDot();

  @override
  State<_PulsingRedDot> createState() => _PulsingRedDotState();
}

class _PulsingRedDotState extends State<_PulsingRedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

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
  Widget build(BuildContext context) => FadeTransition(
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
