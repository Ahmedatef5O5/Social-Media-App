import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/group_calls/services/group_call_signaling_service.dart';
import '../../../features/single_calls/cubits/single_call_cubit/call_cubit.dart';
import '../../services/active_call/active_call_session_data.dart';
import '../../services/active_call/call_navigation_helper.dart';
import '../../services/active_call/call_termination_service.dart';
import '../../services/active_call/cubit/active_call_session_cubit.dart';
import '../../services/active_call/pip/call_pip_cubit.dart';
import '../custom_loading_indicator.dart';
import 'call_header_avatar_with_badge.dart';
import 'call_header_dismiss_button.dart';
import 'call_header_title_and_duration.dart';

class ActiveCallHeaderContent extends StatefulWidget {
  final ActiveCallSessionData session;
  final VoidCallback onDismiss;
  const ActiveCallHeaderContent({
    super.key,
    required this.session,
    required this.onDismiss,
  });

  @override
  State<ActiveCallHeaderContent> createState() =>
      _ActiveCallHeaderContentState();
}

class _ActiveCallHeaderContentState extends State<ActiveCallHeaderContent> {
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
  void didUpdateWidget(covariant ActiveCallHeaderContent oldWidget) {
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
    final session = widget.session;
    CallNavigationHelper.expandActiveCall(
      context.read<CallPipCubit>(),
      session,
    );
  }

  Future<void> _handleEndCall() async {
    if (_isEnding) return;
    setState(() => _isEnding = true);

    final session = widget.session;
    final durationText = _durationText;

    if (session.isGroup) {
      await CallTerminationService.endActiveCall(
        pipCubit: context.read<CallPipCubit>(),
        sessionCubit: context.read<ActiveCallSessionCubit>(),
        signalEnd:
            () => context.read<GroupCallSignalingService>().endCall(
              session.callId,
              duration: durationText,
            ),
      );
    } else {
      await CallTerminationService.endActiveCall(
        pipCubit: context.read<CallPipCubit>(),
        sessionCubit: context.read<ActiveCallSessionCubit>(),
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
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.06),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _handleExpand,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  CallHeaderAvatarWithBadge(
                                    widget: widget,
                                    accent: accent,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: CallHeaderTitleAndDuration(
                                      widget: widget,
                                      durationText: _durationText,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.open_in_full_rounded,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _buildEndCallButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 4),
            CallHeaderDismissButton(widget: widget),
          ],
        ),
      ),
    );
  }

  Widget _buildEndCallButton() {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: _handleEndCall,
      child: Container(
        width: 31,
        height: 31,
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
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child:
            _isEnding
                ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CustomLoadingIndicator(
                    color: Colors.red.withValues(alpha: 0.25),
                  ),
                )
                : const Icon(
                  Icons.call_end_rounded,
                  color: Colors.white,
                  size: 18,
                ),
      ),
    );
  }
}
