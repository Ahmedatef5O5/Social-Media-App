import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/chats/services/chat_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/fcm_services.dart';
import '../model/call_model.dart';
import '../services/call_signaling_service.dart';
import 'call_state.dart';

class CallCubit extends Cubit<CallState> {
  final CallSignalingService signalingService;
  final _chatServices = ChatServices();
  final _fcmService = FcmService.instance;

  StreamSubscription? _callSubscription;
  StreamSubscription? _authSubscription;
  StreamSubscription? _statusSubscription;

  DateTime? _callAcceptedAt;
  CallModel? _activeCall;

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
    _activeCall = call;
    _callAcceptedAt = null;

    emit(CallDialingState(call));

    await signalingService.sendCallRequest(call);

    await _sendCallFcm(call);

    _statusSubscription?.cancel();
    _statusSubscription = signalingService.callStatusStream(call.callId).listen(
      (data) {
        if (isClosed) return;
        if (data.isEmpty) return;

        final updatedCall = CallModel.fromMap(data.first);

        switch (updatedCall.status) {
          case CallStatus.accepted:
            _callAcceptedAt = DateTime.now();
            _activeCall = updatedCall;
            emit(CallConnectedState(updatedCall));
            break;

          case CallStatus.rejected:
            _handleCallEnded(updatedCall);
            emit(CallEndedState());
            break;

          case CallStatus.ended:
            _handleCallEnded(updatedCall);
            emit(CallEndedState());
            break;

          default:
            break;
        }
      },
    );
  }

  Future<void> acceptCall(CallModel call) async {
    _callAcceptedAt = DateTime.now();
    _activeCall = call;
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
    _handleCallEnded(_activeCall);
    emit(CallEndedState());
  }

  Future<void> _sendCallFcm(CallModel call) async {
    try {
      final data =
          await Supabase.instance.client
              .from('users')
              .select('fcm_token')
              .eq('id', call.receiverId)
              .maybeSingle();

      final token = data?['fcm_token'] as String?;
      if (token == null || token.isEmpty) return;

      await _fcmService.sendCallNotification(
        receiverFcmToken: token,
        callerId: call.callerId,
        callerName: call.callerName,
        callerAvatar: call.callerAvatar,
        callId: call.callId,
        callType: call.type == CallType.video ? 'video' : 'audio',
      );
    } catch (_) {}
  }

  Future<void> _handleCallEnded(CallModel? call) async {
    if (call == null) return;

    final duration =
        _callAcceptedAt != null
            ? DateTime.now().difference(_callAcceptedAt!)
            : null;

    final durationStr = duration != null ? _formatDuration(duration) : '';
    final callType = call.type == CallType.video ? 'video' : 'audio';

    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final otherUserId =
        call.callerId == currentUserId ? call.receiverId : call.callerId;

    final status = duration != null ? 'completed' : 'missed';

    if (_isCaller(call)) {
      await _logCallToChat(
        receiverId: otherUserId,
        status: status,
        callType: callType,
        duration: durationStr,
      );
    }

    _callAcceptedAt = null;
    _activeCall = null;
  }

  bool _isCaller(CallModel call) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return call.callerId == currentUserId;
  }

  Future<void> _logCallToChat({
    required String receiverId,
    required String status,
    required String callType,
    required String duration,
  }) async {
    try {
      final senderId = Supabase.instance.client.auth.currentUser?.id ?? '';

      final callInfoJson = jsonEncode({
        'status': status,
        'call_type': callType,
        'duration': duration,
      });

      await _chatServices.sendMessage(
        senderId: senderId,
        receiverId: receiverId,
        text: callInfoJson,
        messageType: 'call',
      );
    } catch (_) {}
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Future<void> close() {
    _callSubscription?.cancel();
    _authSubscription?.cancel();
    _statusSubscription?.cancel();
    return super.close();
  }
}
