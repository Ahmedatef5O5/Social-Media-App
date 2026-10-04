import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/group_calls/models/group_call_model.dart';
import '../../../../features/single_calls/models/call_model.dart';
import '../../incoming_call_navigation_guard.dart';
import '../active_call_session_data.dart';

class ActiveCallSessionCubit extends Cubit<ActiveCallSessionData?> {
  ActiveCallSessionCubit() : super(null);

  void startSingleCallSession({
    required String callId,
    required String title,
    String? avatarUrl,
    required bool isVideo,
    required DateTime startedAt,
    CallModel? call,
    String? currentUserId,
    String? currentUserName,
  }) {
    // Synchronous, tree-independent "I am busy" marker (also mirrored to the
    // FCM background isolate) — set BEFORE emitting so listeners that react to
    // the new state already see a consistent guard.
    IncomingCallNavigationGuard.setActiveCallSession(callId);
    emit(
      ActiveCallSessionData(
        isGroup: false,
        callId: callId,
        title: title,
        avatarUrl: avatarUrl,
        isVideo: isVideo,
        startedAt: startedAt,
        call: call,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
      ),
    );
  }

  void startGroupCallSession({
    required String callId,
    required String title,
    String? avatarUrl,
    required bool isVideo,
    required DateTime startedAt,
    GroupCallModel? groupCall,
    String? currentUserId,
    String? currentUserName,
  }) {
    IncomingCallNavigationGuard.setActiveCallSession(callId);
    emit(
      ActiveCallSessionData(
        isGroup: true,
        callId: callId,
        title: title,
        avatarUrl: avatarUrl,
        isVideo: isVideo,
        startedAt: startedAt,
        groupCall: groupCall,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
      ),
    );
  }

  void endSession() {
    IncomingCallNavigationGuard.setActiveCallSession(null);
    if (state != null) {
      emit(null);
    }
  }

  bool get hasActiveSession => state != null;

  @override
  Future<void> close() {
    IncomingCallNavigationGuard.setActiveCallSession(null);
    return super.close();
  }
}
