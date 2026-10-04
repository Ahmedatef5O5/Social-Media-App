import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/notifications/dispatchers/group_call_dispatcher.dart';
import '../../../core/services/current_user_name_resolver.dart';
import '../../../core/services/permissions/app_permissions_service.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../../core/widgets/calls/call_avatar_backdrop.dart';
import '../../../core/widgets/calls/call_layout_metrics.dart';
import '../../../core/widgets/calls/calls.dart';
import '../models/group_call_model.dart';
import '../services/group_call_signaling_service.dart';
import 'livekit_group_call_view.dart';

class IncomingGroupCallScreen extends StatefulWidget {
  final GroupCallModel call;
  final bool autoAccept;

  const IncomingGroupCallScreen({
    super.key,
    required this.call,
    this.autoAccept = false,
  });

  @override
  State<IncomingGroupCallScreen> createState() =>
      _IncomingGroupCallScreenState();
}

class _IncomingGroupCallScreenState extends State<IncomingGroupCallScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();

  late final Future<String> _nameFuture;
  bool _isAccepting = false;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _membershipSubscription;
  late final GroupCallSignalingService _signaling;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _signaling = context.read<GroupCallSignalingService>();
    // Start resolving the real display name right away so it is ready by the
    // time Accept is tapped.
    _nameFuture = CurrentUserNameResolver.resolve();
    _playRingtone();
    _initAnimations();
    _listenToCallStatus();
    _listenToMembership();

    if (widget.autoAccept) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_acceptCall(context));
      });
    }
  }

  void _initAnimations() {
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _shakeAnim = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _listenToCallStatus() {
    _statusSubscription = _signaling
        .activeCallStream(widget.call.groupId)
        .listen((activeCall) {
          if (!mounted) return;
          if (activeCall == null ||
              activeCall.status == GroupCallStatus.ended ||
              activeCall.status == GroupCallStatus.missed) {
            _cleanup();
            Navigator.pop(context);
          }
        });
  }

  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/incoming_ring.mp3'));
    } catch (e) {
      debugPrint('[IncomingGroupCall] failed to play ringtone: $e');
    }
  }

  void _cleanup() {
    _audioPlayer.stop();
    unawaited(
      GroupCallDispatcher.instance.cancelIncomingGroupCallNotification(
        widget.call.callId,
      ),
    );
  }

  void _listenToMembership() {
    final myId = SupabaseProvider.id;
    _membershipSubscription = SupabaseProvider.client
        .from(SupabaseConstants.groupMembers)
        .stream(primaryKey: ['id'])
        .eq(GroupMemberColumns.groupId, widget.call.groupId)
        .listen((data) {
          if (!mounted) return;
          final myRow = data.firstWhere(
            (row) => row[GroupMemberColumns.userId] == myId,
            orElse: () => <String, dynamic>{},
          );
          final isMember =
              myRow.isNotEmpty &&
              myRow[GroupMemberColumns.membershipStatus] == 'active';
          if (!isMember) {
            _cleanup();
            Navigator.pop(context);
          }
        });
  }

  Future<void> _acceptCall(BuildContext context) async {
    if (_isAccepting) return;
    _isAccepting = true;
    try {
      // Permissions first: the OS dialog must not appear over a connecting
      // call, and a denial keeps the ringing screen so the user can retry
      // or decline.
      final granted = await AppPermissionsService.instance
          .ensureCallPermissions(
            isVideo: widget.call.type == GroupCallType.video,
            context: context,
          );
      if (!granted || !context.mounted) return;

      _cleanup();
      final userName = await _nameFuture;
      final updatedCall = await _signaling.acceptCall(widget.call.callId);
      if (!context.mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => LiveKitGroupCallView(
                call: updatedCall,
                currentUserId: SupabaseProvider.id,
                currentUserName: userName,
              ),
        ),
      );
    } finally {
      _isAccepting = false;
    }
  }

  @override
  void dispose() {
    _cleanup();
    _statusSubscription?.cancel();
    _membershipSubscription?.cancel();
    _audioPlayer.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isVideo = widget.call.type == GroupCallType.video;

    return Scaffold(
      body: Stack(
        children: [
          CallAvatarBackdrop(
            avatarUrl: widget.call.groupAvatarUrl,
            baseColor: primary,
          ),
          CallAmbientBackground(
            style: CallAmbientStyle.orbit,
            isVideo: isVideo,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final metrics = CallLayoutMetrics.of(constraints);

                return Column(
                  children: [
                    SizedBox(height: metrics.topGap),

                    CallStatusPill(
                      icon:
                          isVideo
                              ? Icons.videocam_rounded
                              : Icons.phone_callback_rounded,
                      label:
                          isVideo
                              ? 'Incoming Group Video'
                              : 'Incoming Group Voice',
                      shake: _shakeAnim,
                    ),

                    SizedBox(height: metrics.midGap),

                    RippleAvatar(
                      avatarDiameter: metrics.avatarDiameter,
                      rippleColor: Colors.greenAccent,
                      avatar: CallAvatarImage(
                        imageUrl: widget.call.groupAvatarUrl,
                        fallbackLabel: widget.call.groupName,
                        diameter: metrics.avatarDiameter,
                        borderColor: Colors.greenAccent,
                        isGroup: true,
                      ),
                    ),

                    SizedBox(height: metrics.midGap),

                    Text(
                      widget.call.groupName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${widget.call.initiatorName} is calling...',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const Spacer(),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GlassCallActionButton(
                            icon: Icons.call_end_rounded,
                            label: 'Decline',
                            color: Colors.redAccent.shade700,
                            size: metrics.buttonSize,
                            onTap: () {
                              _cleanup();
                              _signaling.rejectCall(widget.call.callId);
                              Navigator.pop(context);
                            },
                          ),
                          GlassCallActionButton(
                            icon:
                                isVideo
                                    ? Icons.videocam_rounded
                                    : Icons.call_rounded,
                            label: 'Accept',
                            color: Colors.green.shade600,
                            size: metrics.buttonSize,
                            emphasized: true,
                            onTap: () => _acceptCall(context),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: metrics.bottomGap),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
