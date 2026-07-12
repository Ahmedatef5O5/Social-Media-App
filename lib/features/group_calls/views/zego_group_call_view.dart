import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../../core/secrets/app_secrets.dart';
import '../../../core/services/zego_token_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../models/group_call_model.dart';
import '../services/group_call_signaling_service.dart';

class ZegoGroupCallView extends StatefulWidget {
  final GroupCallModel call;
  final String currentUserId;
  final String currentUserName;

  const ZegoGroupCallView({
    super.key,
    required this.call,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<ZegoGroupCallView> createState() => _ZegoGroupCallViewState();
}

class _ZegoGroupCallViewState extends State<ZegoGroupCallView> {
  late final GroupCallSignalingService _signaling;
  String? _zegoToken;
  StreamSubscription? _participantSub;
  DateTime? _callStartTime;
  bool _callHasStarted = false;
  bool _isEnding = false;

  @override
  void initState() {
    super.initState();
    _signaling = context.read<GroupCallSignalingService>();
    _loadZegoToken();
    _callStartTime = DateTime.now();
    _monitorParticipants();
  }

  Future<void> _loadZegoToken() async {
    try {
      final token = await ZegoTokenService.instance.generateToken(
        userId: widget.currentUserId,
      );
      if (mounted) setState(() => _zegoToken = token);
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _monitorParticipants() {
    _participantSub = _signaling.activeCallStream(widget.call.groupId).listen((
      activeCall,
    ) {
      if (activeCall == null || _isEnding) return;

      final count = activeCall.participantCount;

      if (count >= 2) {
        _callHasStarted = true;
      }

      if (_callHasStarted && count < 2) {
        _terminateCall();
      }
    });
  }

  Future<void> _terminateCall() async {
    if (_isEnding) return;
    _isEnding = true;

    try {
      final duration =
          _callStartTime != null
              ? _formatDuration(DateTime.now().difference(_callStartTime!))
              : null;

      await _signaling.endCall(
        widget.call.callId,
        duration: duration,
        participantCount: widget.call.participantCount,
      );

      await ZegoUIKit().leaveRoom();
    } catch (_) {}

    if (mounted) Navigator.of(context).pop();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _participantSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_zegoToken == null) {
      return const Scaffold(body: Center(child: CustomLoadingIndicator()));
    }

    final isVideo = widget.call.type == GroupCallType.video;
    final primary = Theme.of(context).primaryColor;

    final config =
        isVideo
            ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
            : ZegoUIKitPrebuiltCallConfig.groupVoiceCall();

    config.avatarBuilder = (
      BuildContext context,
      Size size,
      ZegoUIKitUser? user,
      Map extraInfo,
    ) {
      if (user == null) return const SizedBox.shrink();

      final double diameter =
          size.width < size.height ? size.width : size.height;

      return SizedBox(
        width: diameter,
        height: diameter,
        child: FutureBuilder(
          future:
              SupabaseProvider.client
                  .from('users')
                  .select('image_url')
                  .eq('id', user.id)
                  .maybeSingle(),
          builder: (context, snapshot) {
            final imageUrl = snapshot.data?['image_url'] as String?;
            if (imageUrl != null && imageUrl.isNotEmpty) {
              return ClipOval(
                child: CachedCloudinaryImage(
                  secureUrl: imageUrl,
                  width: diameter,
                  height: diameter,
                  fit: BoxFit.cover,
                  isAvatar: true,
                  placeholder:
                      (context) => Container(
                        width: diameter,
                        height: diameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: 0.3),
                        ),
                      ),
                  errorWidget:
                      (context, error) =>
                          _buildDefaultAvatar(user.name, primary, diameter),
                ),
              );
            }
            return _buildDefaultAvatar(user.name, primary, diameter);
          },
        ),
      );
    };

    config.audioVideoView.showUserNameOnView = false;
    config.audioVideoView.showSoundWavesInAudioMode = true;

    config.audioVideoView.foregroundBuilder = (
      BuildContext context,
      Size size,
      ZegoUIKitUser? user,
      Map extraInfo,
    ) {
      if (user == null) return const SizedBox.shrink();
      return Positioned(
        bottom: 4,
        right: 32,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    };

    config.topMenuBar.title = widget.call.groupName;

    if (!isVideo) {
      config.audioVideoView.backgroundBuilder = (ctx, size, user, extra) {
        final darker =
            HSLColor.fromColor(primary)
                .withLightness(
                  (HSLColor.fromColor(primary).lightness - 0.15).clamp(
                    0.0,
                    1.0,
                  ),
                )
                .toColor();
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, darker],
            ),
          ),
        );
      };
    }

    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: AppSecrets.zegoAppId,
        token: _zegoToken!,
        userID: widget.currentUserId,
        userName: widget.currentUserName,
        callID: widget.call.callId,
        config: config,
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) async {
            if (!_isEnding) {
              _isEnding = true;
              final duration =
                  _callStartTime != null
                      ? _formatDuration(
                        DateTime.now().difference(_callStartTime!),
                      )
                      : null;
              await _signaling.endCall(widget.call.callId, duration: duration);
            }
            if (mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name, Color primary, double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: diameter * 0.38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
