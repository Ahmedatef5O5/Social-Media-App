class GroupInviteState {
  final String inviteHash;
  final DateTime? expiresAt;
  final int joinCount;

  const GroupInviteState({
    required this.inviteHash,
    this.expiresAt,
    this.joinCount = 0,
  });

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  factory GroupInviteState.fromMap(Map<String, dynamic> map) {
    return GroupInviteState(
      inviteHash: map['invite_hash'] as String,
      expiresAt:
          map['invite_expires_at'] != null
              ? DateTime.parse(map['invite_expires_at'] as String).toLocal()
              : null,
      joinCount: (map['invite_join_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupInviteState &&
          other.inviteHash == inviteHash &&
          other.expiresAt == expiresAt &&
          other.joinCount == joinCount);

  @override
  int get hashCode => Object.hash(inviteHash, expiresAt, joinCount);
}
