import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/services/active_call/active_call_session_data.dart';
import '../../services/active_call/cubit/active_call_session_cubit.dart';
import '../../services/active_call/pip/call_pip_cubit.dart';
import '../../services/active_call/pip/call_pip_state.dart';
import 'active_call_header_content.dart';

class ActiveCallHeaderWidget extends StatefulWidget {
  const ActiveCallHeaderWidget({super.key});

  @override
  State<ActiveCallHeaderWidget> createState() => _ActiveCallHeaderWidgetState();
}

class _ActiveCallHeaderWidgetState extends State<ActiveCallHeaderWidget> {
  bool _isDismissedByUser = false;

  void _handleDismiss() {
    if (!_isDismissedByUser) setState(() => _isDismissedByUser = true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveCallSessionCubit, ActiveCallSessionData?>(
      builder: (context, session) {
        if (session == null) return const SizedBox.shrink();
        return BlocConsumer<CallPipCubit, CallPipState>(
          listenWhen:
              (previous, current) =>
                  !previous.isMinimized && current.isMinimized,
          listener: (context, pip) {
            if (_isDismissedByUser) {
              setState(() => _isDismissedByUser = false);
            }
          },
          builder: (context, pip) {
            final shouldShow = pip.isMinimized && !_isDismissedByUser;
            return _buildSwitcher(shouldShow, session, _handleDismiss);
          },
        );
      },
    );
  }
}

Widget _buildSwitcher(
  bool shouldShow,
  ActiveCallSessionData session,
  VoidCallback onDismiss,
) {
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 250),
    transitionBuilder:
        (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.2),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
    child:
        !shouldShow
            ? const SizedBox.shrink(key: ValueKey('hidden'))
            : Material(
              key: const ValueKey('header'),
              type: MaterialType.transparency,
              child: ActiveCallHeaderContent(
                session: session,
                onDismiss: onDismiss,
              ),
            ),
  );
}
