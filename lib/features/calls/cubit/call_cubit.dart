import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/call_model.dart';
import '../services/call_signaling_service.dart';
import 'call_state.dart';

class CallCubit extends Cubit<CallState> {
  final CallSignalingService signalingService;
  StreamSubscription? _callSubscription;
  StreamSubscription? _authSubscription;
  StreamSubscription? _statusSubscription;

  CallCubit(this.signalingService) : super(CallInitial()) {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.session != null) {
        _initIncomingListener();
      } else {
        _callSubscription?.cancel();
      }
    });
    if (Supabase.instance.client.auth.currentUser != null) {
      _initIncomingListener();
    }
  }

  void _initIncomingListener() {
    _callSubscription?.cancel();
    _callSubscription = signalingService.incomingCallsStream.listen((data) {
      if (isClosed) return;
      if (data.isNotEmpty) {
        final call = CallModel.fromMap(data.first);
        emit(CallIncomingState(call));
      }
    });
  }

  Future<void> makeAudioCall(CallModel call) async {
    emit(CallDialingState(call));
    await signalingService.sendCallRequest(call);

    _statusSubscription?.cancel();
    _statusSubscription = signalingService.callStatusStream(call.callId).listen(
      (data) {
        if (isClosed) return;
        if (data.isNotEmpty) {
          final updatedCall = CallModel.fromMap(data.first);
          if (updatedCall.status == CallStatus.accepted) {
            emit(CallConnectedState(updatedCall));
          } else if (updatedCall.status == CallStatus.rejected ||
              updatedCall.status == CallStatus.ended) {
            emit(CallEndedState());
          }
        }
      },
    );
  }

  Future<void> acceptCall(CallModel call) async {
    await signalingService.updateCallStatus(call.callId, CallStatus.accepted);
    emit(CallConnectedState(call));
  }

  Future<void> rejectCall(CallModel call) async {
    await signalingService.updateCallStatus(call.callId, CallStatus.rejected);
    emit(CallInitial());
  }

  Future<void> endCall(String callId) async {
    _statusSubscription?.cancel();
    await signalingService.updateCallStatus(callId, CallStatus.ended);
    emit(CallEndedState());
  }

  @override
  Future<void> close() {
    _callSubscription?.cancel();
    _authSubscription?.cancel();
    _statusSubscription?.cancel();
    return super.close();
  }
}
