import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../../core/secrets/app_secrets.dart';
import '../../../core/services/active_call/cubit/active_call_session_cubit.dart';
import '../../../core/services/active_call/call_termination_service.dart';
import '../../../core/services/call_foreground_task_handler.dart';
import '../../../core/services/notification_services.dart';
import '../../../core/services/zego_token_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../models/group_call_model.dart';
import '../services/group_call_signaling_service.dart';
import '../widget/group_call_members_sheet.dart';

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
  DateTime? _callStartTime;
  bool _isEnding = false;
  late final ActiveCallSessionCubit _sessionCubit;

  @override
  void initState() {
    super.initState();
    _signaling = context.read<GroupCallSignalingService>();
    _sessionCubit = context.read<ActiveCallSessionCubit>();
    _loadZegoToken();
    _callStartTime = DateTime.now();

    _sessionCubit.startGroupCallSession(
      callId: widget.call.callId,
      title: widget.call.groupName,
      avatarUrl: widget.call.groupAvatarUrl,
      isVideo: widget.call.type == GroupCallType.video,
      startedAt: _callStartTime!,
      onSoloTimeout: _terminateCall,
    );

    FlutterForegroundTask.startService(
      serviceId: 102,
      notificationTitle: widget.call.groupName,
      notificationText: 'Ongoing Group Call',
      callback: startCallServiceCallback,
    );
  }

  Future<void> _loadZegoToken() async {
    try {
      final token = await ZegoTokenService.instance.generateToken(
        userId: widget.currentUserId,
      );
      if (mounted) setState(() => _zegoToken = token);
    } catch (e) {
      if (mounted) {
        context.read<ActiveCallSessionCubit>().endSession();
        Navigator.of(context).pop();
      }
    }
  }

  /// Runs the real termination sequence and is **guaranteed** to reach
  /// `Navigator.pop()` no matter what fails along the way.
  ///
  /// Previously this duplicated CallTerminationService's steps inline, with
  /// `FlutterForegroundTask.stopService()` NOT wrapped in its own try/catch.
  /// Since that call sat inside this method's `finally` block, a thrown
  /// PlatformException from it (which foreground-service plugins can and do
  /// throw, e.g. if the service is already in an unexpected state) aborted
  /// the *rest* of that same `finally` block — meaning `_sessionCubit
  /// .endSession()` and `Navigator.of(context).pop()` never ran. Supabase
  /// signaling (`_signaling.endCall`) had already completed by then and
  /// removed the caller for every other participant, so the room correctly
  /// showed everyone else leaving while this exact user's own screen stayed
  /// stuck — matching the reported bug precisely.
  ///
  /// CallTerminationService already existed for exactly this reason (see
  /// its own doc comment) but ZegoGroupCallView had never been migrated to
  /// use it. Every step inside it is independently try/caught, so nothing
  /// it does can prevent the pop below from running.
  Future<void> _terminateCall() async {
    if (_isEnding) return;
    _isEnding = true;

    final duration =
        _callStartTime != null
            ? _formatDuration(DateTime.now().difference(_callStartTime!))
            : null;

    await CallTerminationService.endActiveCall(
      signalEnd:
          () => _signaling.endCall(
            widget.call.callId,
            duration: duration,
            participantCount: widget.call.participantCount,
          ),
    );

    _sessionCubit.endSession();

    if (mounted) Navigator.of(context).pop();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
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

    config.topMenuBar
      ..isVisible = true
      ..buttons =
          [] // clears the SDK's default top-bar buttons — this is
      ..extendButtons = [_buildMinimizeButton(context)]
      ..backgroundColor = Colors.black.withValues(alpha: 0.25)
      ..padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
      ..margin = const EdgeInsets.only(top: 8, left: 8, right: 8);

    config.bottomMenuBarConfig = ZegoBottomMenuBarConfig(
      buttons: config.bottomMenuBarConfig.buttons,
      extendButtons: [_buildMembersButton(context)],
      hideAutomatically: true,
      hideByClick: true,
      backgroundColor: Colors.black.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(vertical: 10),
      margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
    );

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
      return Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4, right: 32),
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
            if (_isEnding) {
              defaultAction.call();
              return;
            }
            _isEnding = true;

            final duration =
                _callStartTime != null
                    ? _formatDuration(
                      DateTime.now().difference(_callStartTime!),
                    )
                    : null;

            // Every step below (leaveRoom, Supabase signaling, stopping the
            // foreground service, hiding the minimize overlay) is
            // independently try/caught inside CallTerminationService, so a
            // failure in any one of them can no longer prevent the ones
            // after it — including the pop below — from running. This is
            // the actual fix for "End Call removes the other participant
            // but leaves my own screen stuck".
            await CallTerminationService.endActiveCall(
              signalEnd:
                  () => _signaling.endCall(
                    widget.call.callId,
                    duration: duration,
                  ),
            );

            _sessionCubit.endSession();
            defaultAction.call();

            if (context.mounted) {
              Navigator.of(context).pop();
            }
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

  Widget _buildMinimizeButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleMinimize(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: const Icon(
          Icons.close_fullscreen_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  void _handleMinimize(BuildContext context) {
    // 1) Hand the live audio/video session off to the (invisible) mini
    //    overlay page mounted globally in app.dart — this is what flips
    //    `isMinimizingNotifier` to true and makes ActiveCallHeaderWidget
    //    start rendering.
    final navContext = navigatorKey.currentState?.context ?? context;
    ZegoUIKitPrebuiltCallController().minimize.minimize(navContext);

    // 2) `minimize()` does NOT navigate on its own — per Zego's own SDK
    //    docs, closing the full-screen call route is the caller's
    //    responsibility (same contract as their `onCallEnd` callback).
    //    Without this, the full-screen ZegoUIKitPrebuiltCall route stays
    //    on top of the stack while the header renders behind it.
    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
  }

  Widget _buildMembersButton(BuildContext context) {
    return GestureDetector(
      onTap: () => GroupCallMembersSheet.show(context, widget.call),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}
