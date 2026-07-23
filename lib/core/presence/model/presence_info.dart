import '../services/presence_service.dart';

class PresenceInfo {
  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? updatedAt;

  const PresenceInfo({
    required this.userId,
    required this.isOnline,
    required this.lastSeen,
    required this.updatedAt,
  });

  factory PresenceInfo.fromMap(Map<String, dynamic> map) {
    DateTime? parseUtc(dynamic raw) =>
        raw == null ? null : DateTime.parse(raw.toString());

    return PresenceInfo(
      userId: map['user_id'] as String,
      isOnline: map['is_online'] as bool? ?? false,
      lastSeen: parseUtc(map['last_seen']),
      updatedAt: parseUtc(map['updated_at']),
    );
  }

  bool get isEffectivelyOnline => PresenceService.isConsideredOnline(
    isOnline: isOnline,
    updatedAt: updatedAt,
  );
}
