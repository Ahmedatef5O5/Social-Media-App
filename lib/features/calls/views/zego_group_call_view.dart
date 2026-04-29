import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../../core/secrets/app_secrets.dart';
import '../../group_chat/models/group_call_model.dart';
import '../../group_chat/services/group_call_signaling_service.dart';

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
  final _signaling = GroupCallSignalingService();
  StreamSubscription? _participantSub;
  DateTime? _callStartTime;
  bool _callHasStarted = false;
  bool _isEnding = false;

  @override
  void initState() {
    super.initState();
    _callStartTime = DateTime.now();
    _monitorParticipants();
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

      return FutureBuilder(
        future:
            Supabase.instance.client
                .from('users')
                .select('image_url')
                .eq('id', user.id)
                .maybeSingle(),
        builder: (context, snapshot) {
          final imageUrl = snapshot.data?['image_url'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            return ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) =>
                        Container(color: primary.withValues(alpha: 0.3)),
                errorWidget:
                    (context, url, error) =>
                        _buildDefaultAvatar(user.name, primary),
              ),
            );
          }
          return _buildDefaultAvatar(user.name, primary);
        },
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
        appSign: AppSecrets.zegoAppSign,
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

  Widget _buildDefaultAvatar(String name, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
