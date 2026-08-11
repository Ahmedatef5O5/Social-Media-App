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

  const VoiceFullScreenView({
    super.key,
    required this.item,
    this.isActive = true,
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

  Future<void> _togglePlayback() async {
    if (_isInitialized && _controller != null) {
      if (_isPlaying) {
        _controller!.pause();
        _voice.markStopped(_voiceUrl);
        setState(() => _isPlaying = false);
      } else {
        _voice.setActive(_voiceUrl);
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

    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }

    controller.addListener(_onControllerUpdate);
    _voice.register(_voiceUrl, controller);
    _voice.setActive(_voiceUrl);
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
    if (_voice.activeVoiceUrl.value == _voiceUrl) {
      _voice.pauseActive();
    }
    _voice.activeVoiceUrl.removeListener(_onActiveVoiceChanged);
    _controller?.removeListener(_onControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isMe = item.senderId == SupabaseProvider.id;
    final position = _controller?.value.position ?? Duration.zero;
    final duration = _effectiveDuration ?? Duration.zero;
    final hasAvatar = (item.senderAvatar ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child:
                hasAvatar
                    ? CachedCloudinaryImage(
                      secureUrl: item.senderAvatar!,
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
                                secureUrl: item.senderAvatar!,
                                fit: BoxFit.cover,
                              )
                              : _AvatarFallbackCircle(name: item.senderName),
                    ),
                    Positioned(
                      bottom: -6,
                      right: -6,
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
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 58,
                                  height: 58,
                                  child: CustomLoadingIndicator(
                                    color: Colors.white,
                                  ),
                                )
                                : GlassIconButton(
                                  icon:
                                      _isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                  size: 58,
                                  iconSize: 30,
                                  onTap: _togglePlayback,
                                ),
                      ),
                      const Gap(24),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: WaveformProgressBar(
                          seed: _voiceUrl,
                          position: position,
                          duration: duration,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white.withValues(alpha: 0.28),
                          height: 40,
                          barWidth: 3.6,
                          gap: 2.6,
                          onSeek:
                              _isInitialized && _controller != null
                                  ? (target) => _controller!.seekTo(target)
                                  : null,
                        ),
                      ),
                      const Gap(8),
                      Row(
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
                            duration > Duration.zero ? _fmt(duration) : '--:--',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
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
