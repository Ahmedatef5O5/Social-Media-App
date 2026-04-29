enum GroupCallStatus { ringing, accepted, ongoing, ended, missed }

enum GroupCallType { audio, video }

class GroupCallModel {
  final String callId;
  final String groupId;
  final String groupName;
  final String? groupAvatarUrl;
  final String initiatorId;
  final String initiatorName;
  final GroupCallStatus status;
  final GroupCallType type;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int participantCount;
  final String? duration;

  const GroupCallModel({
    required this.callId,
    required this.groupId,
    required this.groupName,
    this.groupAvatarUrl,
    required this.initiatorId,
    required this.initiatorName,
    required this.status,
    required this.type,
    required this.startedAt,
    this.endedAt,
    this.participantCount = 0,
    this.duration,
  });

  bool get isActive =>
      status == GroupCallStatus.ringing ||
      status == GroupCallStatus.accepted ||
      status == GroupCallStatus.ongoing;

  bool get isMissed => status == GroupCallStatus.missed;
  bool get isEnded => status == GroupCallStatus.ended;

  GroupCallModel copyWith({
    String? callId,
    String? groupId,
    String? groupName,
    String? groupAvatarUrl,
    String? initiatorId,
    String? initiatorName,
    GroupCallStatus? status,
    GroupCallType? type,
    DateTime? startedAt,
    DateTime? endedAt,
    int? participantCount,
    String? duration,
  }) {
    return GroupCallModel(
      callId: callId ?? this.callId,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupAvatarUrl: groupAvatarUrl ?? this.groupAvatarUrl,
      initiatorId: initiatorId ?? this.initiatorId,
      initiatorName: initiatorName ?? this.initiatorName,
      status: status ?? this.status,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      participantCount: participantCount ?? this.participantCount,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toMap() => {
    'call_id': callId,
    'group_id': groupId,
    'group_name': groupName,
    'group_avatar_url': groupAvatarUrl,
    'initiator_id': initiatorId,
    'initiator_name': initiatorName,
    'status': status.name,
    'type': type.name,
    'started_at': startedAt.toIso8601String(),
    if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
    'participant_count': participantCount,
    if (duration != null) 'duration': duration,
  };

  factory GroupCallModel.fromMap(Map<String, dynamic> map) => GroupCallModel(
    callId: map['call_id'] as String,
    groupId: map['group_id'] as String,
    groupName: map['group_name'] as String? ?? '',
    groupAvatarUrl: map['group_avatar_url'] as String?,
    initiatorId: map['initiator_id'] as String,
    initiatorName: map['initiator_name'] as String? ?? '',
    status: GroupCallStatus.values.byName(map['status'] as String),
    type: GroupCallType.values.byName(map['type'] as String),
    startedAt: DateTime.parse(map['started_at'] as String),

    endedAt:
        map['ended_at'] != null
            ? DateTime.tryParse(map['ended_at'] as String)
            : null,
    participantCount: (map['participant_count'] as int?) ?? 0,
    duration: map['duration'] as String?,
  );

  String get lastMessagePreview {
    final typeIcon = type == GroupCallType.video ? '🎥' : '📞';

    final typeLabel =
        type == GroupCallType.video ? 'Group Video Call' : 'Group Voice Call';

    return switch (status) {
      GroupCallStatus.missed => '$typeIcon $typeLabel Missed',
      GroupCallStatus.ringing => '$typeIcon $typeLabel Ongoing…',
      GroupCallStatus.accepted || GroupCallStatus.ongoing =>
        participantCount > 0
            ? '$typeIcon $typeLabel • $participantCount Participants'
            : '$typeIcon $typeLabel Ongoing',

      GroupCallStatus.ended =>
        duration != null
            ? '$typeIcon $typeLabel • $participantCount • $duration'
            : '$typeIcon $typeLabel Ended',
    };
  }
}
