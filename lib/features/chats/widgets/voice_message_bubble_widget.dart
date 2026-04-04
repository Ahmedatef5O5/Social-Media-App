import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:video_player/video_player.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/themes/app_colors.dart';

class VoiceMessageBubbleWidget extends StatefulWidget {
  final String voiceUrl;
  final bool isMe;
  final DateTime timestamp;
  final bool? isRead;
  const VoiceMessageBubbleWidget({
    super.key,
    required this.voiceUrl,
    required this.isMe,
    required this.timestamp,
    this.isRead,
  });

  static final ValueNotifier<String?> _activeVoiceUrl = ValueNotifier<String?>(
    null,
  );

  static final Map<String, VideoPlayerController> _cache = {};

  static final Map<String, Duration> _durationCache = {};

  static Future<void> clearCache() async {
    _activeVoiceUrl.value = null;
    for (final c in _cache.values) {
      await c.dispose();
    }
    _cache.clear();
    _durationCache.clear();
  }

  @override
  State<VoiceMessageBubbleWidget> createState() =>
      _VoiceMessageBubbleWidgetState();
}

class _VoiceMessageBubbleWidgetState extends State<VoiceMessageBubbleWidget> {
  VideoPlayerController? get _controller =>
      VoiceMessageBubbleWidget._cache[widget.voiceUrl];

  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isLoading = false;

  static const List<double> _speeds = [1.0, 1.25, 1.5, 1.75, 2.0];
  int _speedIndex = 0;
  double get _currentSpeed => _speeds[_speedIndex];

  @override
  void initState() {
    super.initState();
    VoiceMessageBubbleWidget._activeVoiceUrl.addListener(_onActiveVoiceChanged);

    if (VoiceMessageBubbleWidget._cache.containsKey(widget.voiceUrl)) {
      _isInitialized = true;
      _isPlaying = _controller!.value.isPlaying;
      _controller!.addListener(_onControllerUpdate);
    } else {
      _preloadDuration();
    }
  }

  void _onActiveVoiceChanged() {
    final active = VoiceMessageBubbleWidget._activeVoiceUrl.value;
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
      VoiceMessageBubbleWidget._activeVoiceUrl.value = null;
      setState(() => _isPlaying = false);
    } else {
      setState(() {});
    }
  }

  Future<void> _preloadDuration() async {
    if (VoiceMessageBubbleWidget._durationCache.containsKey(widget.voiceUrl)) {
      if (mounted) setState(() {});
      return;
    }
    try {
      final tempController = VideoPlayerController.networkUrl(
        Uri.parse(widget.voiceUrl),
      );
      await tempController.initialize();
      final duration = tempController.value.duration;
      await tempController.dispose();
      VoiceMessageBubbleWidget._durationCache[widget.voiceUrl] = duration;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _initAndPlay() async {
    if (_isInitialized && _controller != null) {
      if (_isPlaying) {
        _controller!.pause();

        if (mounted) setState(() => _isPlaying = false);
        VoiceMessageBubbleWidget._activeVoiceUrl.value = null;
      } else {
        VoiceMessageBubbleWidget._activeVoiceUrl.value = widget.voiceUrl;
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

    VoiceMessageBubbleWidget._durationCache[widget.voiceUrl] =
        controller.value.duration;

    controller.addListener(_onControllerUpdate);

    VoiceMessageBubbleWidget._cache[widget.voiceUrl] = controller;

    VoiceMessageBubbleWidget._activeVoiceUrl.value = widget.voiceUrl;
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
    VoiceMessageBubbleWidget._activeVoiceUrl.removeListener(
      _onActiveVoiceChanged,
    );
    _controller?.removeListener(_onControllerUpdate);
    super.dispose();
  }

  String get _durationText {
    if (_isInitialized && _controller != null && _isPlaying) {
      final remaining =
          _controller!.value.duration - _controller!.value.position;
      return _fmt(remaining.isNegative ? Duration.zero : remaining);
    }

    final cached = VoiceMessageBubbleWidget._durationCache[widget.voiceUrl];
    if (cached != null) return _fmt(cached);
    return '--:--';
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : _initAndPlay,
          icon:
              _isLoading
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
                    child:
                        _isInitialized
                            ? VideoProgressIndicator(
                              _controller!,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor:
                                    widget.isMe
                                        ? AppColors.white
                                        : Theme.of(context).primaryColor,
                                bufferedColor: Colors.white38,
                                backgroundColor: Colors.white24,
                              ),
                            )
                            : Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
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
                    style: TextStyle(
                      color:
                          widget.isMe ? AppColors.white70 : AppColors.black54,
                      fontSize: 11,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.ltr,
                    children: [
                      Text(
                        FormattedDate.getMessageTime(widget.timestamp),
                        style: TextStyle(
                          color:
                              widget.isMe
                                  ? AppColors.white70
                                  : AppColors.black54,
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
