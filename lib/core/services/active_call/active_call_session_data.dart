import '../../../features/group_calls/models/group_call_model.dart';
import '../../../features/single_calls/models/call_model.dart';

class ActiveCallSessionData {
  final bool isGroup;
  final String callId;
  final String title;
  final String? avatarUrl;
  final bool isVideo;
  final DateTime startedAt;
  final CallModel? call;
  final GroupCallModel? groupCall;
  final String? currentUserId;
  final String? currentUserName;

  const ActiveCallSessionData({
    required this.isGroup,
    required this.callId,
    required this.title,
    required this.isVideo,
    required this.startedAt,
    this.avatarUrl,
    this.call,
    this.groupCall,
    this.currentUserId,
    this.currentUserName,
  });

  ActiveCallSessionData copyWith({
    bool? isGroup,
    String? callId,
    String? title,
    String? avatarUrl,
    bool? isVideo,
    DateTime? startedAt,
    CallModel? call,
    GroupCallModel? groupCall,
    String? currentUserId,
    String? currentUserName,
  }) {
    return ActiveCallSessionData(
      isGroup: isGroup ?? this.isGroup,
      callId: callId ?? this.callId,
      title: title ?? this.title,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVideo: isVideo ?? this.isVideo,
      startedAt: startedAt ?? this.startedAt,
      call: call ?? this.call,
      groupCall: groupCall ?? this.groupCall,
      currentUserId: currentUserId ?? this.currentUserId,
      currentUserName: currentUserName ?? this.currentUserName,
    );
  }
}
