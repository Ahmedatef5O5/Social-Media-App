import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:video_player/video_player.dart';
import '../../../core/chat_shared/controllers/voice_playback_controller.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/waveform_progress_bar.dart';

class VoiceMessageBubbleWidget extends StatefulWidget {
  final String voiceUrl;
  final bool isMe;
  final DateTime timestamp;
  final bool? isRead;
  final bool isUploading;
  final int? initialDurationSeconds;
  const VoiceMessageBubbleWidget({
    super.key,
    required this.voiceUrl,
    required this.isMe,
    required this.timestamp,
    this.isRead,
    required this.isUploading,
    this.initialDurationSeconds,
  });

  static Future<void> clearCache() =>
      VoicePlaybackController.instance.clearCache();

  @override
  State<VoiceMessageBubbleWidget> createState() =>
      _VoiceMessageBubbleWidgetState();
}

class _VoiceMessageBubbleWidgetState extends State<VoiceMessageBubbleWidget> {
  final VoicePlaybackController _voice = VoicePlaybackController.instance;

  VideoPlayerController? get _controller =>
      _voice.controllerFor(widget.voiceUrl);

  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  // ignore: unused_field
  bool _isLocalFile = false;

  static const List<double> _speeds = [1.0, 1.25, 1.5, 1.75, 2.0];
  int _speedIndex = 0;
  double get _currentSpeed => _speeds[_speedIndex];

  Future<void> _preloadDuration() async {
    if (widget.isUploading || widget.voiceUrl.startsWith('/')) return;

    await _voice.fetchDuration(widget.voiceUrl);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _voice.activeVoiceUrl.addListener(_onActiveVoiceChanged);

    if (widget.voiceUrl.startsWith('/')) {
      _isLocalFile = true;
      return;
    }

    if (_voice.cache.containsKey(widget.voiceUrl)) {
      _isInitialized = true;
      _isPlaying = _controller!.value.isPlaying;
      _controller!.addListener(_onControllerUpdate);
    }
    _preloadDuration();
  }

  @override
  void didUpdateWidget(VoiceMessageBubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.voiceUrl != widget.voiceUrl) {
      _controller?.removeListener(_onControllerUpdate);

      if (!widget.voiceUrl.startsWith('/')) {
        _isLocalFile = false;

        if (_voice.cache.containsKey(widget.voiceUrl)) {
          _isInitialized = true;
          _controller!.addListener(_onControllerUpdate);
        } else {
          _isInitialized = false;
        }

        _preloadDuration();
      }

      if (mounted) setState(() {});
    }
  }

  void _onActiveVoiceChanged() {
    final active = _voice.activeVoiceUrl.value;
    if (active != widget.voiceUrl && _isPlaying) {
      _controller?.pause();
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final ctrl = _controller;
    if (ctrl == null) return;

    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;

    if (dur > Duration.zero && pos >= dur) {
      ctrl.seekTo(Duration.zero);
      ctrl.pause();
      _voice.markStopped(widget.voiceUrl);
      setState(() => _isPlaying = false);
    } else {
      setState(() {});
    }
  }

  Future<void> _initAndPlay() async {
    if (_isInitialized && _controller != null) {
      if (_isPlaying) {
        _controller!.pause();
        if (mounted) setState(() => _isPlaying = false);
        _voice.markStopped(widget.voiceUrl);
      } else {
        _voice.setActive(widget.voiceUrl);
        await _controller!.setPlaybackSpeed(_currentSpeed);
        _controller!.play();
        if (mounted) setState(() => _isPlaying = true);
      }
      return;
    }
    if (mounted) setState(() => _isLoading = true);

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.voiceUrl),
    );
    await controller.initialize();

    controller.addListener(_onControllerUpdate);
    _voice.register(widget.voiceUrl, controller);

    _voice.setActive(widget.voiceUrl);
    await controller.setPlaybackSpeed(_currentSpeed);
    await controller.play();

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _isLoading = false;
        _isPlaying = true;
      });
    }
  }

  Future<void> _cycleSpeed() async {
    setState(() => _speedIndex = (_speedIndex + 1) % _speeds.length);
    if (_isInitialized && _controller != null) {
      await _controller!.setPlaybackSpeed(_currentSpeed);
    }
  }

  @override
  void dispose() {
    _voice.activeVoiceUrl.removeListener(_onActiveVoiceChanged);
    _controller?.removeListener(_onControllerUpdate);
    super.dispose();
  }

  Duration? get _effectiveDuration {
    final ctrl = _controller;
    if (ctrl != null &&
        ctrl.value.isInitialized &&
        ctrl.value.duration >= VoicePlaybackController.minReliableDuration) {
      return ctrl.value.duration;
    }

    if (widget.initialDurationSeconds != null &&
        widget.initialDurationSeconds! > 0) {
      return Duration(seconds: widget.initialDurationSeconds!);
    }

    final cached = _voice.durationCache[widget.voiceUrl];
    if (cached != null &&
        cached >= VoicePlaybackController.minReliableDuration) {
      return cached;
    }

    return null;
  }

  String get _durationText {
    final total = _effectiveDuration;
    if (total == null) return '--:--';

    final ctrl = _controller;
    if (_isPlaying && ctrl != null && ctrl.value.isInitialized) {
      final remaining = total - ctrl.value.position;
      return _fmt(remaining.isNegative ? Duration.zero : remaining);
    }
    return _fmt(total);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        widget.isMe ? AppColors.white : Theme.of(context).primaryColor;
    final showLoadingIcon =
        widget.isUploading ||
        _isLoading ||
        widget.voiceUrl.isEmpty ||
        widget.voiceUrl.startsWith('/');
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          onPressed: showLoadingIcon ? null : _initAndPlay,
          icon:
              showLoadingIcon
                  ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CustomLoadingIndicator(
                      color:
                          widget.isMe
                              ? AppColors.white
                              : Theme.of(context).primaryColor,
                    ),
                  )
                  : _isLoading
                  ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CustomLoadingIndicator(
                      color:
                          widget.isMe
                              ? AppColors.white
                              : Theme.of(context).primaryColor,
                    ),
                  )
                  : Icon(
                    _isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color:
                        widget.isMe
                            ? AppColors.white
                            : Theme.of(context).primaryColor,
                    size: 32,
                  ),
        ),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: WaveformProgressBar(
                      seed: widget.voiceUrl,
                      position: _controller?.value.position ?? Duration.zero,
                      duration: _effectiveDuration ?? Duration.zero,
                      activeColor: activeColor,
                      inactiveColor: activeColor.withValues(alpha: 0.25),
                      onSeek:
                          _isInitialized && _controller != null
                              ? (target) => _controller!.seekTo(target)
                              : null,
                    ),
                  ),
                  const Gap(8),
                  GestureDetector(
                    onTap: _cycleSpeed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      margin: const EdgeInsets.only(top: 1.4),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_currentSpeed == _currentSpeed.truncateToDouble() ? _currentSpeed.toInt() : _currentSpeed}x',
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const Gap(4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _durationText,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color:
                          widget.isMe
                              ? AppColors.white70
                              : Theme.of(context).colorScheme.onSurface,
                      fontSize: 9,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.ltr,
                    children: [
                      Text(
                        FormattedDate.getMessageTime(widget.timestamp),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium!.copyWith(
                          color:
                              widget.isMe
                                  ? AppColors.white70
                                  : Theme.of(context).colorScheme.onSurface,
                          fontSize: 9,
                        ),
                      ),
                      if (widget.isMe) ...[
                        const Gap(2),
                        Icon(
                          (widget.isRead ?? false)
                              ? Icons.done_all
                              : Icons.done,
                          size: 12,
                          color:
                              (widget.isRead ?? false)
                                  ? Colors.blue[200]
                                  : AppColors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
