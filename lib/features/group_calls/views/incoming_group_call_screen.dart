import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../../core/widgets/calls/calls.dart';
import '../models/group_call_model.dart';
import '../services/group_call_signaling_service.dart';
import 'zego_group_call_view.dart';

class IncomingGroupCallScreen extends StatefulWidget {
  final GroupCallModel call;

  const IncomingGroupCallScreen({super.key, required this.call});

  @override
  State<IncomingGroupCallScreen> createState() =>
      _IncomingGroupCallScreenState();
}

class _IncomingGroupCallScreenState extends State<IncomingGroupCallScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();

  String _currentUserName = 'Loading...';
  StreamSubscription? _statusSubscription;
  StreamSubscription? _membershipSubscription;
  late final GroupCallSignalingService _signaling;
  late final AnimationController _titleController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  @override
  void initState() {
    super.initState();
    _signaling = context.read<GroupCallSignalingService>();
    _fetchMyName();
    _playRingtone();
    _initAnimations();
    _listenToCallStatus();
    _listenToMembership();
  }

  void _initAnimations() {
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _titleController.forward();
    });
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

  Future<void> _fetchMyName() async {
    final user = SupabaseProvider.user!;
    final data =
        await SupabaseProvider.client
            .from('users')
            .select('name')
            .eq('id', user.id)
            .maybeSingle();
    if (mounted) {
      setState(() => _currentUserName = (data?['name'] as String?) ?? 'Me');
    }
  }

  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/incoming_ring.mp3'));
    } catch (_) {}
  }

  void _cleanup() => _audioPlayer.stop();

  // if I get removed/leave while this dialog is on screen, dismiss it.
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

  @override
  void dispose() {
    _cleanup();
    _statusSubscription?.cancel();
    _membershipSubscription?.cancel();
    _audioPlayer.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _acceptCall(BuildContext context) async {
    _cleanup();
    final updatedCall = await _signaling.acceptCall(widget.call.callId);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => ZegoGroupCallView(
              call: updatedCall,
              currentUserId: SupabaseProvider.id,
              currentUserName: _currentUserName,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isVideo = widget.call.type == GroupCallType.video;

    return Scaffold(
      body: Stack(
        children: [
          CallGradientBackground(baseColor: primary),
          CallAmbientBackground(
            style: CallAmbientStyle.drift,
            isVideo: isVideo,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final shortest = constraints.biggest.shortestSide;
                final avatarDiameter =
                    (shortest.clamp(280.0, 460.0) * 0.34).toDouble();
                final buttonSize =
                    (shortest.clamp(280.0, 460.0) * 0.19).toDouble();
                final isCompact = constraints.maxHeight < 620;

                return Column(
                  children: [
                    SizedBox(height: isCompact ? 16 : 28),

                    CallStatusPill(
                      icon:
                          isVideo
                              ? Icons.videocam_rounded
                              : Icons.phone_callback_rounded,
                      label:
                          isVideo
                              ? 'Incoming Group Video'
                              : 'Incoming Group Voice',
                      showLiveDot: true,
                    ),

                    Expanded(
                      child: Center(
                        child: _buildGroupInfoSection(avatarDiameter),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GlassCallActionButton(
                            icon: Icons.call_end_rounded,
                            label: 'Decline',
                            color: Colors.red.shade600,
                            size: buttonSize,
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
                            color: Colors.green.shade500,
                            size: buttonSize,
                            emphasized: true,
                            onTap: () => _acceptCall(context),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isCompact ? 24 : 56),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfoSection(double avatarDiameter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RippleAvatar(
          avatarDiameter: avatarDiameter,
          rippleColor: Colors.greenAccent,
          avatar: CallAvatarImage(
            imageUrl: widget.call.groupAvatarUrl,
            fallbackLabel: widget.call.groupName,
            diameter: avatarDiameter,
            borderColor: Colors.greenAccent,
          ),
        ),
        const SizedBox(height: 32),
        FadeTransition(
          opacity: _titleFade,
          child: SlideTransition(
            position: _titleSlide,
            child: Column(
              children: [
                Text(
                  widget.call.groupName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 6, height: 6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.call.initiatorName} is calling',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
