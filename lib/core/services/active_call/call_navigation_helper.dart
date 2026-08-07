import 'package:flutter/material.dart';
import '../../../features/group_calls/views/livekit_group_call_view.dart';
import '../notification_services.dart';
import '../../router/app_routes.dart';
import 'active_call_session_data.dart';
import 'pip/call_pip_cubit.dart';

class CallNavigationHelper {
  const CallNavigationHelper._();

  static void expandActiveCall(
    CallPipCubit pip,
    ActiveCallSessionData session,
  ) {
    if (session.isGroup) {
      if (session.groupCall == null ||
          session.currentUserId == null ||
          session.currentUserName == null) {
        return;
      }
      pip.restore();
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder:
              (_) => LiveKitGroupCallView(
                call: session.groupCall!,
                currentUserId: session.currentUserId!,
                currentUserName: session.currentUserName!,
              ),
        ),
      );
      return;
    }

    if (session.call == null ||
        session.currentUserId == null ||
        session.currentUserName == null) {
      return;
    }
    pip.restore();
    navigatorKey.currentState?.pushNamed(
      AppRoutes.callRoute,
      arguments: {
        'call': session.call,
        'userId': session.currentUserId,
        'userName': session.currentUserName,
      },
    );
  }
}
