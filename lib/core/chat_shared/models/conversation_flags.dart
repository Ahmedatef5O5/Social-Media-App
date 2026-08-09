const _unsetFlag = Object();

class ConversationFlags {
  final bool isPinned;
  final bool isFavorite;
  final bool isArchived;
  final bool? muteOverride;
  final bool autoMutedByArchive;
  final DateTime? pinnedAt;
  final DateTime? archivedAt;

  const ConversationFlags({
    this.isPinned = false,
    this.isFavorite = false,
    this.isArchived = false,
    this.muteOverride,
    this.autoMutedByArchive = false,
    this.pinnedAt,
    this.archivedAt,
  });

  static const none = ConversationFlags();

  ConversationFlags copyWith({
    bool? isPinned,
    bool? isFavorite,
    bool? isArchived,
    Object? muteOverride = _unsetFlag,
    bool? autoMutedByArchive,
    Object? pinnedAt = _unsetFlag,
    Object? archivedAt = _unsetFlag,
  }) {
    return ConversationFlags(
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      muteOverride:
          identical(muteOverride, _unsetFlag)
              ? this.muteOverride
              : muteOverride as bool?,
      autoMutedByArchive: autoMutedByArchive ?? this.autoMutedByArchive,
      pinnedAt:
          identical(pinnedAt, _unsetFlag)
              ? this.pinnedAt
              : pinnedAt as DateTime?,
      archivedAt:
          identical(archivedAt, _unsetFlag)
              ? this.archivedAt
              : archivedAt as DateTime?,
    );
  }

  Map<String, dynamic> toJson() => {
    'p': isPinned,
    'f': isFavorite,
    'a': isArchived,
    'mo': muteOverride,
    'am': autoMutedByArchive,
    'pAt': pinnedAt?.toIso8601String(),
    'aAt': archivedAt?.toIso8601String(),
  };

  factory ConversationFlags.fromJson(Map<String, dynamic> map) {
    return ConversationFlags(
      isPinned: map['p'] as bool? ?? false,
      isFavorite: map['f'] as bool? ?? false,
      isArchived: map['a'] as bool? ?? false,
      muteOverride: map['mo'] as bool?,
      autoMutedByArchive: map['am'] as bool? ?? false,
      pinnedAt:
          map['pAt'] != null ? DateTime.tryParse(map['pAt'] as String) : null,
      archivedAt:
          map['aAt'] != null ? DateTime.tryParse(map['aAt'] as String) : null,
    );
  }
}
