import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:video_player/video_player.dart';
import '../../../features/single_chats/helper/glass_icon_btn.dart';
import '../../audio/helpers/animated_mic_badge.dart';
import '../../cache/repository/media_cache_repository.dart';
import '../../helpers/formatted_date.dart';
import '../../supabase/supabase_provider.dart';
import '../../themes/app_colors.dart';
import '../../widgets/cached_cloudinary_image.dart';
import '../../widgets/custom_loading_indicator.dart';
import '../../widgets/waveform_progress_bar.dart';
import '../controllers/voice_playback_controller.dart';
import '../models/shared_media_item.dart';

class VoiceFullScreenView extends StatefulWidget {
  final SharedMediaItem item;
  final bool isActive;
  final String? currentUserAvatar;

  const VoiceFullScreenView({
    super.key,
    required this.item,
    this.isActive = true,
    this.currentUserAvatar,
  });

  @override
  State<VoiceFullScreenView> createState() => _VoiceFullScreenViewState();
}

class _VoiceFullScreenViewState extends State<VoiceFullScreenView> {
  final VoicePlaybackController _voice = VoicePlaybackController.instance;

  String get _voiceUrl => widget.item.voiceUrl ?? '';
  VideoPlayerController? get _controller => _voice.controllerFor(_voiceUrl);

  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isLoading = false;

  static const List<double> _speeds = [1.0, 1.25, 1.5, 1.75, 2.0];
  int _speedIndex = 0;
  double get _currentSpeed => _speeds[_speedIndex];

  @override
  void initState() {
    super.initState();
    _voice.activeVoiceUrl.addListener(_onActiveVoiceChanged);

    if (_voice.cache.containsKey(_voiceUrl)) {
      _isInitialized = true;
      _isPlaying = _controller!.value.isPlaying;
      _controller!.addListener(_onControllerUpdate);
    } else {
      _voice.fetchDuration(_voiceUrl).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant VoiceFullScreenView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;

    if (widget.isActive) {
      if (_isInitialized && _controller != null && !_isPlaying) {
        _togglePlayback();
      }
    } else if (_isPlaying) {
      _controller?.pause();
      _voice.markStopped(_voiceUrl);
      setState(() => _isPlaying = false);
    }
  }

  void _onActiveVoiceChanged() {
    final active = _voice.activeVoiceUrl.value;
    if (active != _voiceUrl && _isPlaying) {
      setState(() => _isPlaying = false);
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
      _voice.markStopped(_voiceUrl);
      setState(() => _isPlaying = false);
    } else {
      setState(() {});
    }
  }

  Future<void> _cycleSpeed() async {
    setState(() => _speedIndex = (_speedIndex + 1) % _speeds.length);
    if (_isInitialized && _controller != null) {
      await _controller!.setPlaybackSpeed(_currentSpeed);
    }
  }

  Future<void> _togglePlayback() async {
    if (_isInitialized && _controller != null) {
      if (_isPlaying) {
        _controller!.pause();
        _voice.markStopped(_voiceUrl);
        setState(() => _isPlaying = false);
      } else {
        _voice.setActive(_voiceUrl);
        await _controller!.setPlaybackSpeed(_currentSpeed);
        if (!mounted) return;
        _controller!.play();
        setState(() => _isPlaying = true);
      }
      return;
    }

    setState(() => _isLoading = true);

    final localPath = await context
        .read<MediaCacheRepository>()
        .resolveLocalPath(_voiceUrl);

    final controller =
        localPath != null
            ? VideoPlayerController.file(File(localPath))
            : VideoPlayerController.networkUrl(Uri.parse(_voiceUrl));

    try {
      await controller.initialize();
    } catch (e) {
      debugPrint('Voice init error: $e');
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }

    controller.addListener(_onControllerUpdate);
    _voice.register(_voiceUrl, controller);
    _voice.setActive(_voiceUrl);
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

  Duration? get _effectiveDuration {
    final ctrl = _controller;
    if (ctrl != null &&
        ctrl.value.isInitialized &&
        ctrl.value.duration >= VoicePlaybackController.minReliableDuration) {
      return ctrl.value.duration;
    }
    if (widget.item.durationSeconds != null &&
        widget.item.durationSeconds! > 0) {
      return Duration(seconds: widget.item.durationSeconds!);
    }
    final cached = _voice.durationCache[_voiceUrl];
    if (cached != null &&
        cached >= VoicePlaybackController.minReliableDuration) {
      return cached;
    }
    return null;
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _voice.activeVoiceUrl.removeListener(_onActiveVoiceChanged);
    _controller?.removeListener(_onControllerUpdate);

    if (_voice.activeVoiceUrl.value == _voiceUrl) {
      _voice.pauseActive();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isMe = item.senderId == SupabaseProvider.id;
    final position = _controller?.value.position ?? Duration.zero;
    final duration = _effectiveDuration ?? Duration.zero;

    final avatarUrl =
        isMe
            ? (widget.currentUserAvatar ?? item.senderAvatar)
            : item.senderAvatar;
    final hasAvatar = (avatarUrl ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child:
                hasAvatar
                    ? CachedCloudinaryImage(
                      secureUrl: avatarUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorWidget: (_, __) => const _AvatarFallbackBackground(),
                    )
                    : const _AvatarFallbackBackground(),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 170,
                      height: 170,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child:
                          hasAvatar
                              ? CachedCloudinaryImage(
                                secureUrl: avatarUrl!,
                                fit: BoxFit.cover,
                              )
                              : _AvatarFallbackCircle(name: item.senderName),
                    ),
                    Positioned(
                      bottom: 3,
                      right: 3,
                      child: AnimatedMicBadge(isPlaying: _isPlaying),
                    ),
                  ],
                ),
                const Gap(20),
                Text(
                  isMe ? 'You' : item.senderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(6),
                Text(
                  FormattedDate.getFormattedDate(item.createdAt.toString()),
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const Spacer(flex: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _isLoading
                              ? const SizedBox(
                                width: 42,
                                height: 42,
                                child: CustomLoadingIndicator(
                                  color: Colors.white,
                                ),
                              )
                              : GlassIconButton(
                                icon:
                                    _isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                size: 42,
                                iconSize: 24,
                                onTap: _togglePlayback,
                              ),
                          const Gap(12),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: WaveformProgressBar(
                                seed: _voiceUrl,
                                position: position,
                                duration: duration,
                                activeColor: Colors.white,
                                inactiveColor: Colors.white.withValues(
                                  alpha: 0.28,
                                ),
                                height: 40,
                                barWidth: 3.6,
                                gap: 2.6,
                                onSeek:
                                    _isInitialized && _controller != null
                                        ? (target) =>
                                            _controller!.seekTo(target)
                                        : null,
                              ),
                            ),
                          ),
                          const Gap(12),
                          GestureDetector(
                            onTap: _cycleSpeed,
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_currentSpeed == _currentSpeed.truncateToDouble() ? _currentSpeed.toInt() : _currentSpeed}x',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 54),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _fmt(position),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              duration > Duration.zero
                                  ? _fmt(duration)
                                  : '--:--',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallbackBackground extends StatelessWidget {
  const _AvatarFallbackBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryColor.withValues(alpha: 0.9), Colors.black],
        ),
      ),
    );
  }
}

class _AvatarFallbackCircle extends StatelessWidget {
  final String name;
  const _AvatarFallbackCircle({required this.name});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryColor.withValues(alpha: 0.3),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 56,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
