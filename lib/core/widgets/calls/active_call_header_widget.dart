import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:social_media_app/core/services/notification_services.dart';
import 'package:social_media_app/core/services/active_call/active_call_session_data.dart';
import 'package:social_media_app/core/services/active_call/call_termination_service.dart';
import 'package:social_media_app/core/widgets/app_avatar.dart';
import 'package:social_media_app/features/single_calls/cubits/single_call_cubit/call_cubit.dart';
import 'package:social_media_app/features/group_calls/services/group_call_signaling_service.dart';

import '../../services/active_call/cubit/active_call_session_cubit.dart';

/// Sticky, non-floating replacement for Zego's default draggable mini
/// player.
///
/// Renders **nothing** unless there is currently an active call
/// ([ActiveCallSessionCubit]) **and** that call is minimized
/// (`ZegoUIKitPrebuiltCallController().minimize.isMinimizingNotifier`).
/// Fully standalone and reusable — drop it as the first child of a
/// `Column`, above any scrollable content, on any screen.
class ActiveCallHeaderWidget extends StatelessWidget {
  const ActiveCallHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveCallSessionCubit, ActiveCallSessionData?>(
      builder: (context, session) {
        if (session == null) return const SizedBox.shrink();

        return ValueListenableBuilder<bool>(
          valueListenable:
              ZegoUIKitPrebuiltCallController().minimize.isMinimizingNotifier,
          builder: (context, isMinimizing, _) {
            if (!isMinimizing) return const SizedBox.shrink();

            // This widget is mounted inside app.dart's root Stack — a
            // SIBLING of the routed `MaterialApp` content, not a
            // descendant of any screen's `Scaffold`. That means it sits
            // outside every `Material` ancestor the app normally
            // provides, so every `Text`/`Icon`/`InkWell` below used to
            // fall back to Flutter's "No Material widget found" error
            // rendering (the double yellow underline under each word).
            //
            // `MaterialType.transparency` gives this subtree a real
            // Material ancestor — default text style, ink splashes,
            // etc. — without painting any surface color of its own, so
            // it stays fully invisible and doesn't fight with the
            // glass/blur look below it.
            return Material(
              type: MaterialType.transparency,
              child: _ActiveCallHeaderContent(session: session),
            );
          },
        );
      },
    );
  }
}

class _ActiveCallHeaderContent extends StatefulWidget {
  final ActiveCallSessionData session;
  const _ActiveCallHeaderContent({required this.session});

  @override
  State<_ActiveCallHeaderContent> createState() =>
      _ActiveCallHeaderContentState();
}

class _ActiveCallHeaderContentState extends State<_ActiveCallHeaderContent> {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _isEnding = false;

  @override
  void initState() {
    super.initState();
    _refreshElapsed();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshElapsed(),
    );
  }

  @override
  void didUpdateWidget(covariant _ActiveCallHeaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.callId != widget.session.callId) {
      _refreshElapsed();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _refreshElapsed() {
    if (!mounted) return;
    final diff = DateTime.now().difference(widget.session.startedAt);
    setState(() => _elapsed = diff.isNegative ? Duration.zero : diff);
  }

  String get _durationText {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _handleExpand() {
    final navContext = navigatorKey.currentState?.context;
    if (navContext == null) return;
    ZegoUIKitPrebuiltCallController().minimize.restore(navContext);
  }

  Future<void> _handleEndCall() async {
    if (_isEnding) return;
    setState(() => _isEnding = true);

    final session = widget.session;
    final durationText = _durationText;

    if (session.isGroup) {
      await CallTerminationService.endActiveCall(
        signalEnd:
            () => context.read<GroupCallSignalingService>().endCall(
              session.callId,
              duration: durationText,
            ),
      );
    } else {
      await CallTerminationService.endActiveCall(
        signalEnd: () => context.read<CallCubit>().endCall(session.callId),
      );
    }

    if (!mounted) return;
    context.read<ActiveCallSessionCubit>().endSession();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).primaryColor;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.06),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Everything except the end-call button expands the call.
                  // Kept as a SIBLING of the end-call button (not a parent
                  // wrapping it) to avoid nested-GestureDetector ambiguity —
                  // a single outer tap target around the whole row would
                  // fire alongside the inner end-call tap.
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _handleExpand,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            _buildAvatarWithBadge(accent),
                            const SizedBox(width: 10),
                            Expanded(child: _buildTitleAndDuration()),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.open_in_full_rounded,
                              color: Colors.white.withValues(alpha: 0.75),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildEndCallButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWithBadge(Color accent) {
    final session = widget.session;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppAvatar(
          imageUrl: session.avatarUrl,
          size: 36,
          borderColor: accent,
          borderWidth: 1.6,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.25),
                width: 1.4,
              ),
            ),
            child: Icon(
              session.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
              size: 9,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleAndDuration() {
    final session = widget.session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _durationText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: _handleEndCall,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.red.shade400, Colors.red.shade700],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child:
            _isEnding
                ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                : const Icon(
                  Icons.call_end_rounded,
                  color: Colors.white,
                  size: 17,
                ),
      ),
    );
  }
}
