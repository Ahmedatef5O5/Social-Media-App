import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/group_calls/models/group_call_model.dart';
import '../../../../features/single_calls/model/call_model.dart';
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
    if (state != null) {
      emit(null);
    }
  }

  bool get hasActiveSession => state != null;
}
