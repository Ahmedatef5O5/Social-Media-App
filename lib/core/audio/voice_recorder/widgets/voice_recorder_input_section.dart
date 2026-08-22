import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/elevated_glass_icon_btn.dart';
import '../../helpers/lock_indicator_pill.dart';
import '../../helpers/locked_paused_row.dart';
import '../../helpers/locked_recording_row.dart';
import '../../helpers/recording_status_row.dart';
import '../services/voice_chunk_recorder_service.dart';

enum _RecordUiState { idle, recording, locked }

class VoiceRecorderInputSection extends StatefulWidget {
  final Widget textField;
  final bool hasText;
  final Widget sendButton;
  final VoidCallback onShowAttachments;
  final void Function(File file, int durationSeconds) onSendVoice;
  final VoidCallback? onRecordingStart;
  final VoidCallback? onRecordingPause;
  final VoidCallback? onRecordingResume;
  final VoidCallback? onRecordingStop;
  final VoidCallback? onRecordingCancel;
  final VoidCallback? onMicTap;
  final bool isDictating;
  final Future<void> Function()? onForceStopDictation;

  const VoiceRecorderInputSection({
    super.key,
    required this.textField,
    required this.hasText,
    required this.sendButton,
    required this.onShowAttachments,
    required this.onSendVoice,
    this.onRecordingStart,
    this.onRecordingPause,
    this.onRecordingResume,
    this.onRecordingStop,
    this.onRecordingCancel,
    this.onMicTap,
    this.isDictating = false,
    this.onForceStopDictation,
  });

  @override
  State<VoiceRecorderInputSection> createState() =>
      _VoiceRecorderInputSectionState();
}

class _VoiceRecorderInputSectionState extends State<VoiceRecorderInputSection> {
  static const double _lockThreshold = 80.0;
  static const double _cancelThreshold = 120.0;
  static const Duration _minRecordingDuration = Duration(milliseconds: 1000);
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
    if (widget.isDictating) {
      await widget.onForceStopDictation?.call();
    }
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
    widget.onRecordingStart?.call();
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
        widget.onRecordingPause?.call();
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
        widget.onRecordingResume?.call();
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

  bool _isCancelling = false;

  Future<void> _cancelRecording() async {
    if (_isCancelling) return;
    _isCancelling = true;
    try {
      widget.onRecordingCancel?.call();
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
    } finally {
      _isCancelling = false;
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
    widget.onRecordingStop?.call();
    _ticker?.cancel();
    _ticker = null;
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    if (_isPreviewPlaying) await _previewPlayer.stop();

    final file = await _recorderService.finishAndBuild();
    final preciseDuration =
        file != null
            ? await _extractPreciseDuration(file, Duration(seconds: _seconds))
            : Duration(seconds: _seconds);

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

    if (preciseDuration < _minRecordingDuration) {
      await file.delete();
      return;
    }

    final size = await file.length();
    if (size < 1000) {
      await file.delete();
      return;
    }

    widget.onSendVoice(file, preciseDuration.inSeconds);
  }

  Future<Duration> _extractPreciseDuration(File file, Duration fallback) async {
    AudioPlayer? probe;
    try {
      probe = AudioPlayer();
      await probe.setSourceDeviceFile(file.path);
      final duration = await probe.getDuration();
      if (duration != null && duration.inMilliseconds > 0) {
        return duration;
      }
    } catch (_) {
      // Ignore — fall back to the tick counter below.
    } finally {
      await probe?.dispose();
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isRecordingUnlocked = _uiState == _RecordUiState.recording;
    final isLocked = _uiState == _RecordUiState.locked;
    final isActivelyListening = isRecordingUnlocked || widget.isDictating;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child:
              isLocked
                  ? ElevatedIconButton(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.red,
                    onPressed: _cancelRecording,
                  )
                  : ElevatedIconButton(
                    icon: Icons.add,
                    color: primary,
                    onPressed:
                        _uiState == _RecordUiState.idle
                            ? widget.onShowAttachments
                            : null,
                  ),
        ),

        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: _uiState == _RecordUiState.idle ? 0 : 8,
            ),
            decoration: BoxDecoration(
              color:
                  _uiState == _RecordUiState.idle
                      ? primary.withValues(alpha: 0.25)
                      : Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(25),
            ),
            child: switch (_uiState) {
              _RecordUiState.idle => widget.textField,
              _RecordUiState.recording => RecordingStatusRow(
                seconds: _seconds,
                dragDx: _dragDx,
                cancelProgress: _cancelProgress,
              ),
              _RecordUiState.locked =>
                _isPaused
                    ? LockedPausedRow(
                      seconds: _seconds,
                      isPreviewPlaying: _isPreviewPlaying,
                      previewPosition: _previewPosition,
                      previewDuration: _previewDuration,
                      waveformSeed: _recordingSessionId ?? 'recording',
                      onTogglePlay: _togglePreviewPlayback,
                      onSeek: (d) => _previewPlayer.seek(d),
                      onResume: _resumeRecording,
                    )
                    : LockedRecordingRow(
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
                bottom: 58,
                child: LockIndicatorPill(progress: _lockProgress),
              ),

            Padding(
              padding: const EdgeInsets.only(bottom: 2),
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
                        onTap: widget.onMicTap,
                        onLongPressStart: (_) => _startRecording(),
                        onLongPressMoveUpdate: _onDragUpdate,
                        onLongPressEnd: _onLongPressEnd,
                        onLongPressCancel: _onLongPressCancel,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isActivelyListening ? Icons.mic : Icons.mic_none,
                            key: ValueKey(isActivelyListening),
                            color: isActivelyListening ? Colors.red : primary,
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
