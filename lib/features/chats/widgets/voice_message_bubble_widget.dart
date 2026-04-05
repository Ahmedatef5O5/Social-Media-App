import 'dart:async';

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
  static final Map<String, Future<void>> _preloadFutures = {};

  static Future<Duration?> _fetchDuration(String url) async {
    if (_durationCache.containsKey(url)) return _durationCache[url];
    if (_preloadFutures.containsKey(url)) {
      await _preloadFutures[url];
      return _durationCache[url];
    }
    final completer = Completer<void>();
    _preloadFutures[url] = completer.future;
    VideoPlayerController? temp;
    try {
      temp = VideoPlayerController.networkUrl(Uri.parse(url));
      await temp.initialize();
      final duration = temp.value.duration;
      await temp.dispose();
      temp = null;
      _durationCache[url] = duration;
      completer.complete();
      return duration;
    } catch (e) {
      completer.completeError(e);
      return null;
    } finally {
      await temp?.dispose();
      _preloadFutures.remove(url);
    }
  }

  static Future<void> clearCache() async {
    _activeVoiceUrl.value = null;
    _preloadFutures.clear();
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
  bool _isLocalFile = false;

  static const List<double> _speeds = [1.0, 1.25, 1.5, 1.75, 2.0];
  int _speedIndex = 0;
  double get _currentSpeed => _speeds[_speedIndex];
  Future<void> _preloadDuration() async {
    if (widget.voiceUrl.startsWith('/')) return;

    await VoiceMessageBubbleWidget._fetchDuration(widget.voiceUrl);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    VoiceMessageBubbleWidget._activeVoiceUrl.addListener(_onActiveVoiceChanged);

    if (widget.voiceUrl.startsWith('/')) {
      _isLocalFile = true;
      return;
    }

    if (VoiceMessageBubbleWidget._cache.containsKey(widget.voiceUrl)) {
      _isInitialized = true;
      _isPlaying = _controller!.value.isPlaying;
      _controller!.addListener(_onControllerUpdate);
    }
    // if (!VoiceMessageBubbleWidget._durationCache.containsKey(widget.voiceUrl)) {
    //   _preloadDuration();
    // } else {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if (mounted) setState(() {});
    //   });
    // }
    _preloadDuration();
  }

  @override
  void didUpdateWidget(VoiceMessageBubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.voiceUrl != widget.voiceUrl) {
      _controller?.removeListener(_onControllerUpdate);

      if (!widget.voiceUrl.startsWith('/')) {
        _isLocalFile = false;

        if (VoiceMessageBubbleWidget._cache.containsKey(widget.voiceUrl)) {
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
    final ctrl = _controller;
    if (ctrl != null && ctrl.value.isInitialized) {
      if (_isPlaying) {
        final remaining = ctrl.value.duration - ctrl.value.position;
        return _fmt(remaining.isNegative ? Duration.zero : remaining);
      }
      return _fmt(ctrl.value.duration);
    }

    final cached = VoiceMessageBubbleWidget._durationCache[widget.voiceUrl];

    if (cached != null && cached > Duration.zero) return _fmt(cached);

    if (_isInitialized && _controller != null) {
      return _fmt(_controller!.value.duration);
    }
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
              widget.voiceUrl.startsWith('/')
                  ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CustomLoadingIndicator(
                      // strokeWidth: 2,
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
                    child:
                        _isInitialized && _controller != null
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
