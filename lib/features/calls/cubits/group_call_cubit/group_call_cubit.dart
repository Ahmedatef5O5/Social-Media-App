import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../group_chat/models/group_call_model.dart';
import '../../../group_chat/services/group_call_signaling_service.dart';
import 'group_call_state.dart';

class GroupCallCubit extends Cubit<GroupCallState> {
  final GroupCallSignalingService _service;

  StreamSubscription? _activeCallSub;
  StreamSubscription? _incomingSub;
  Timer? _ringtimeoutTimer;

  static const Duration _ringTimeout = Duration(seconds: 45);

  String get _currentUserId => Supabase.instance.client.auth.currentUser!.id;

  GroupCallCubit(this._service) : super(GroupCallInitial());

  void watchActiveCall(String groupId) {
    _activeCallSub?.cancel();
    _activeCallSub = _service.activeCallStream(groupId).listen((call) {
      if (isClosed) return;

      if (call == null) {
        _ringtimeoutTimer?.cancel();
        if (state is! GroupCallInitial) {
          emit(GroupCallEnded());
        }
      } else if (call.status == GroupCallStatus.accepted ||
          call.status == GroupCallStatus.ongoing) {
        _ringtimeoutTimer?.cancel();
        emit(GroupCallActive(call));
      } else if (call.status == GroupCallStatus.missed) {
        _ringtimeoutTimer?.cancel();
        emit(GroupCallMissed(call));
      }
    });
  }

  Future<void> startCall({
    required String groupId,
    required String groupName,
    String? groupAvatarUrl,
    required String currentUserName,
    required GroupCallType type,
  }) async {
    try {
      emit(
        GroupCallOutgoing(
          groupId: groupId,
          groupName: groupName,
          groupAvatarUrl: groupAvatarUrl,
          type: type,
          initiatorName: currentUserName,
        ),
      );

      final call = await _service.initiateCall(
        groupId: groupId,
        groupName: groupName,
        groupAvatarUrl: groupAvatarUrl,
        currentUserId: _currentUserId,
        currentUserName: currentUserName,
        type: type,
      );

      if (isClosed) return;

      if (call.status == GroupCallStatus.accepted ||
          call.status == GroupCallStatus.ongoing) {
        final joined = await _service.acceptCall(call.callId);
        emit(GroupCallActive(joined));
        return;
      }

      emit(GroupCallRinging(call));
      _startRingTimeout(call);
    } catch (e) {
      if (!isClosed) emit(GroupCallError(e.toString()));
    }
  }

  Future<void> acceptIncomingCall(GroupCallModel call) async {
    try {
      _ringtimeoutTimer?.cancel();
      final accepted = await _service.acceptCall(call.callId);
      if (!isClosed) emit(GroupCallActive(accepted));
    } catch (e) {
      if (!isClosed) emit(GroupCallError(e.toString()));
    }
  }

  Future<void> rejectIncomingCall(GroupCallModel call) async {
    _ringtimeoutTimer?.cancel();
    await _service.rejectCall(call.callId);
    if (!isClosed) emit(GroupCallInitial());
  }

  Future<void> joinOngoingCall(GroupCallModel call) async {
    try {
      final joined = await _service.acceptCall(call.callId);
      if (!isClosed) emit(GroupCallActive(joined));
    } catch (e) {
      if (!isClosed) emit(GroupCallError(e.toString()));
    }
  }

  Future<void> endCall(
    String callId, {
    String? duration,
    int? participantCount,
  }) async {
    _ringtimeoutTimer?.cancel();
    await _service.endCall(
      callId,
      duration: duration,
      participantCount: participantCount,
    );
    if (!isClosed) emit(GroupCallEnded());
  }

  Future<void> cancelOutgoingCall(String callId) async {
    _ringtimeoutTimer?.cancel();
    await _service.markAsMissed(callId);
    if (!isClosed) emit(GroupCallMissedByInitiator());
  }

  void watchIncomingCalls(List<String> myGroupIds) {
    _incomingSub?.cancel();
    _incomingSub = _service.incomingGroupCallsStream(_currentUserId).listen((
      calls,
    ) {
      if (isClosed) return;
      if (calls.isNotEmpty) {
        if (state is GroupCallActive || state is GroupCallRinging) return;
        emit(GroupCallIncoming(calls.first));
      }
    });
  }

  void _startRingTimeout(GroupCallModel call) {
    _ringtimeoutTimer?.cancel();
    _ringtimeoutTimer = Timer(_ringTimeout, () async {
      if (isClosed) return;
      final current = await _service.getActiveCall(call.groupId);
      if (current?.status == GroupCallStatus.ringing) {
        await _service.markAsMissed(call.callId);
        if (!isClosed) emit(GroupCallMissedByInitiator());
      }
    });
  }

  @override
  Future<void> close() {
    _ringtimeoutTimer?.cancel();
    _activeCallSub?.cancel();
    _incomingSub?.cancel();
    return super.close();
  }
}
