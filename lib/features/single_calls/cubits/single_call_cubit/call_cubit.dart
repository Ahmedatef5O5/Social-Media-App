import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/profile/services/user_services.dart';
import 'package:social_media_app/features/single_chats/services/chat_services.dart';
import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/helpers/safe_emit_mixin.dart';
import '../../../../core/services/current_user_name_resolver.dart';
import '../../../../core/notifications/helpers/notification_app_state_helper.dart';
import '../../../../core/services/fcm_services.dart';
import '../../../../core/services/incoming_call_navigation_guard.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/toast/app_toast.dart';
import '../../../settings/repository/settings_repository.dart';
import '../../../group_calls/models/group_call_model.dart';
import '../../../group_calls/services/group_call_signaling_service.dart';
import '../../../notifications/repository/notifications_repository.dart';
import '../../models/call_model.dart';
import '../../services/call_signaling_service.dart';
part 'call_state.dart';

class CallCubit extends Cubit<CallState> with SafeEmitMixin<CallState> {
  final CallSignalingService signalingService;
  final ChatServices _chatServices;
  final UserService _userService;
  final _fcmService = FcmService.instance;

  late final GroupCallSignalingService _groupSignaling =
      GroupCallSignalingService();

  StreamSubscription? _callSubscription;
  StreamSubscription? _authSubscription;
  StreamSubscription? _statusSubscription;

  DateTime? _callAcceptedAt;
  CallModel? _activeCall;

  final Set<String> _autoRejectedCallIds = <String>{};

  bool get isBusy => state is CallDialingState || state is CallConnectedState;

  String? get activeCallId {
    final s = state;
    if (s is CallDialingState) return s.call.callId;
    if (s is CallConnectedState) return s.call.callId;
    return null;
  }

  @override
  void onChange(Change<CallState> change) {
    super.onChange(change);
    final next = change.nextState;
    if (next is CallDialingState) {
      IncomingCallNavigationGuard.setSingleCallInProgress(next.call.callId);
    } else if (next is CallConnectedState) {
      IncomingCallNavigationGuard.setSingleCallInProgress(next.call.callId);
    } else if (next is CallEndedState || next is CallInitial) {
      IncomingCallNavigationGuard.setSingleCallInProgress(null);
    }
  }

  CallCubit({
    required this.signalingService,
    required ChatServices chatServices,
    UserService? userService,
  }) : _chatServices = chatServices,
       _userService = userService ?? UserService(),
       super(CallInitial()) {
    _initAfterBootstrap();
  }

  Future<void> _initAfterBootstrap() async {
    await waitForCoreServicesReady();
    if (isClosed) return;

    _authSubscription = SupabaseProvider.authChanges.listen((data) {
      if (data.session != null) {
        _initIncomingListener();
      } else {
        _callSubscription?.cancel();
      }
    });

    if (SupabaseProvider.user != null) {
      unawaited(
        signalingService.cleanupStaleCallsForUser(SupabaseProvider.user!.id),
      );
      _initIncomingListener();
    }
  }

  void _initIncomingListener() {
    _callSubscription?.cancel();
    _callSubscription = signalingService.incomingCallsStream.listen((data) {
      if (isClosed) return;
      if (data.isNotEmpty) {
        final call = CallModel.fromMap(data.first);
        if (call.callerId == SupabaseProvider.idOrNull) return;

        if (isBusy ||
            IncomingCallNavigationGuard.isUserBusyWithAnotherCall(
              call.callId,
            )) {
          _autoRejectWhileBusy(call);
          return;
        }

        if (!isAppInForeground() &&
            !SettingsRepository.instance.callNotifications) {
          return;
        }

        emit(CallIncomingState(call));
      }
    });
  }

  void _autoRejectWhileBusy(CallModel call) {
    if (!_autoRejectedCallIds.add(call.callId)) return;
    unawaited(
      signalingService
          .updateCallStatus(call.callId, CallStatus.rejected)
          .catchError((Object e) {
            debugPrint('[CallCubit] busy auto-reject failed: $e');
          }),
    );
  }

  Future<void> makeAudioCall(CallModel call) async {
    // One call at a time: starting a second call would overwrite `_activeCall`
    // and tear down the one in progress.
    if (isBusy || IncomingCallNavigationGuard.isUserBusyWithAnotherCall()) {
      AppToast.warning('Please end your current call before starting another.');
      return;
    }

    _activeCall = call;
    _callAcceptedAt = null;

    emit(CallDialingState(call));

    await signalingService.sendCallRequest(call);

    unawaited(
      _chatServices.upsertCallMessage(
        callId: call.callId,
        senderId: call.callerId,
        receiverId: call.receiverId,
        status: 'ringing',
        callType: call.type == CallType.video ? 'video' : 'audio',
      ),
    );

    await _sendCallFcm(call);

    _statusSubscription?.cancel();
    _statusSubscription = signalingService.callStatusStream(call.callId).listen(
      (data) async {
        if (isClosed) return;
        if (data.isEmpty) return;
        final updatedCall = CallModel.fromMap(data.first);

        if (updatedCall.status == CallStatus.accepted) {
          _callAcceptedAt = DateTime.now();
          _activeCall = updatedCall;
          unawaited(
            _chatServices.upsertCallMessage(
              callId: call.callId,
              senderId: call.callerId,
              receiverId: call.receiverId,
              status: 'ongoing',
              callType: call.type == CallType.video ? 'video' : 'audio',
            ),
          );
          final currentUserName = await _fetchCurrentUserName();
          if (isClosed) return;
          emit(CallConnectedState(updatedCall, currentUserName));
        } else if (updatedCall.status == CallStatus.rejected) {
          _statusSubscription?.cancel();
          // Never answered: clear the per-call bookkeeping so the caller is
          // not left with a stale `_activeCall`.
          _activeCall = null;
          _callAcceptedAt = null;
          unawaited(
            _chatServices.upsertCallMessage(
              callId: call.callId,
              senderId: call.callerId,
              receiverId: call.receiverId,
              status: 'missed',
              callType: call.type == CallType.video ? 'video' : 'audio',
            ),
          );
          emit(CallEndedState());
          emit(CallInitial());
        } else if (updatedCall.status == CallStatus.ended) {
          _statusSubscription?.cancel();
          _handleCallEnded(call);
          emit(CallEndedState());
          emit(CallInitial());
        }
      },
    );
  }

  Future<void> acceptCall(CallModel call) async {
    _callAcceptedAt = DateTime.now();
    _activeCall = call;

    // The RECEIVER must watch the call row too. Previously only the caller
    // (makeAudioCall) subscribed, so when the caller hung up the receiver
    // only found out via LiveKit's slow disconnect detection (10â€“15 s).
    _listenForRemoteEnd(call);

    await signalingService.updateCallStatus(call.callId, CallStatus.accepted);
    final currentUserName = await _fetchCurrentUserName();
    if (!isClosed) emit(CallConnectedState(call, currentUserName));
  }

  void _listenForRemoteEnd(CallModel call) {
    _statusSubscription?.cancel();
    _statusSubscription = signalingService
        .callStatusStream(call.callId)
        .listen(
          (data) {
            if (isClosed || data.isEmpty) return;
            final updatedCall = CallModel.fromMap(data.first);

            if (updatedCall.status == CallStatus.ended ||
                updatedCall.status == CallStatus.rejected) {
              _statusSubscription?.cancel();
              _handleCallEnded(_activeCall ?? call);
              emit(CallEndedState());
              emit(CallInitial());
            }
          },
          onError: (Object e) {
            debugPrint('[CallCubit] receiver status stream error: $e');
          },
        );
  }

  Future<void> rejectCall(CallModel call) async {
    await signalingService.updateCallStatus(call.callId, CallStatus.rejected);
    if (!isClosed) emit(CallInitial());
  }

  Future<void> endCall(String callId) async {
    _statusSubscription?.cancel();

    final endingCall = _activeCall;
    final wasNeverAnswered =
        endingCall != null && _callAcceptedAt == null && _isCaller(endingCall);

    await signalingService.updateCallStatus(callId, CallStatus.ended);

    if (wasNeverAnswered) {
      unawaited(_sendCancelFcm(endingCall));
    }

    _handleCallEnded(endingCall);
    if (!isClosed) {
      emit(CallEndedState());
      emit(CallInitial());
    }
  }

  Future<String> _fetchCurrentUserName() async {
    return CurrentUserNameResolver.resolve(userService: _userService);
  }

  Future<void> _sendCallFcm(CallModel call) async {
    try {
      final data =
          await SupabaseProvider.client
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
    } catch (e) {
      debugPrint('[CallCubit] failed to show incoming call notification: $e');
    }
  }

  Future<void> _sendCancelFcm(CallModel call) async {
    try {
      final data =
          await SupabaseProvider.client
              .from('users')
              .select('fcm_token')
              .eq('id', call.receiverId)
              .maybeSingle();

      final token = data?['fcm_token'] as String?;
      if (token == null || token.isEmpty) return;

      await _fcmService.sendCallCancelledNotification(
        receiverFcmToken: token,
        callId: call.callId,
      );
    } catch (e) {
      debugPrint('[CallCubit] failed to send cancel notification: $e');
    }
  }

  /// Rings [memberId] into a group call that is already running.
  ///
  /// The ring is attributed to the CURRENT user (the member who tapped
  /// "Ring"), never to `call.initiatorId`: the original initiator may have
  /// left, and a ring whose caller equals the receiver is dropped by every
  /// incoming-call guard.
  Future<void> ringOfflineMember(GroupCallModel call, String memberId) async {
    try {
      final ringerId = SupabaseProvider.idOrNull;
      if (ringerId == null || ringerId.isEmpty) return;
      final ringerName = await CurrentUserNameResolver.resolve();

      await _groupSignaling.ringGroupMember(
        call: call,
        targetMemberId: memberId,
        ringerUserId: ringerId,
        ringerUserName: ringerName,
      );
    } catch (e) {
      debugPrint('[CallCubit] ringOfflineMember error: $e');
    }
  }

  Future<void> _handleCallEnded(CallModel? call) async {
    if (call == null) return;

    final duration =
        _callAcceptedAt != null
            ? DateTime.now().difference(_callAcceptedAt!)
            : null;

    final durationStr = duration != null ? _formatDuration(duration) : '';
    final callType = call.type == CallType.video ? 'video' : 'audio';

    final currentUserId = SupabaseProvider.id;
    final otherUserId =
        call.callerId == currentUserId ? call.receiverId : call.callerId;

    final status = duration != null ? 'completed' : 'missed';

    if (_isCaller(call)) {
      await _logCallToChat(
        callId: call.callId,
        receiverId: otherUserId,
        status: status,
        callType: callType,
        duration: durationStr,
      );
      if (duration == null && _activeCall != null) {
        final otherUserId =
            _isCaller(_activeCall!)
                ? _activeCall!.receiverId
                : _activeCall!.callerId;

        await NotificationRepository.instance.notifyMissedCall(
          receiverId: otherUserId,
          callerId: _activeCall!.callerId,
          callerName: _activeCall!.callerName,
          callerImageUrl: _activeCall!.callerAvatar,
          callType: _activeCall!.type == CallType.video ? 'video' : 'audio',
          callId: _activeCall!.callId,
        );
      }
    }

    _callAcceptedAt = null;
    _activeCall = null;
  }

  bool _isCaller(CallModel call) {
    final currentUserId = SupabaseProvider.id;
    return call.callerId == currentUserId;
  }

  Future<void> _logCallToChat({
    required String callId,
    required String receiverId,
    required String status,
    required String callType,
    required String duration,
  }) async {
    try {
      final senderId = SupabaseProvider.id;
      await _chatServices.upsertCallMessage(
        callId: callId,
        senderId: senderId,
        receiverId: receiverId,
        status: status,
        callType: callType,
        duration: duration,
      );
    } catch (e) {
      debugPrint('_logCallToChat error: $e');
    }
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
