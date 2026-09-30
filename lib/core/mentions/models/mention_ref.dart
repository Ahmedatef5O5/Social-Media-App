class MentionRef {
  final String mentionedUserId;
  final int startIndex;
  final int endIndex;
  final DateTime? createdAt;

  const MentionRef({
    required this.mentionedUserId,
    required this.startIndex,
    required this.endIndex,
    this.createdAt,
  });

  factory MentionRef.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['created_at'];
    return MentionRef(
      mentionedUserId: map['mentioned_user_id'] as String,
      startIndex: map['start_index'] as int,
      endIndex: map['end_index'] as int,
      createdAt:
          rawCreatedAt is String ? DateTime.tryParse(rawCreatedAt) : null,
    );
  }

  Map<String, dynamic> toRpcMap() => {
    'user_id': mentionedUserId,
    'start': startIndex,
    'end': endIndex,
  };

  Map<String, dynamic> toCacheJson() => {
    'mentioned_user_id': mentionedUserId,
    'start_index': startIndex,
    'end_index': endIndex,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };

  factory MentionRef.fromCacheJson(Map<String, dynamic> map) =>
      MentionRef.fromMap(map);

  static List<MentionRef> keepLatestBatch(List<MentionRef> refs) {
    if (refs.length <= 1) return refs;

    DateTime? maxCreatedAt;
    for (final r in refs) {
      final ts = r.createdAt?.toUtc();
      if (ts != null && (maxCreatedAt == null || ts.isAfter(maxCreatedAt))) {
        maxCreatedAt = ts;
      }
    }

    Iterable<MentionRef> candidates = refs;
    if (maxCreatedAt != null) {
      candidates = refs.where((r) {
        final ts = r.createdAt?.toUtc();
        if (ts == null) return true;
        return maxCreatedAt!.difference(ts).inMilliseconds.abs() <= 1500;
      });
    }

    final sortedByNewest = List<MentionRef>.from(candidates)..sort((a, b) {
      final aTs = a.createdAt?.toUtc();
      final bTs = b.createdAt?.toUtc();
      if (aTs != null && bTs != null) {
        final cmp = bTs.compareTo(aTs);
        if (cmp != 0) return cmp;
      }
      return a.startIndex.compareTo(b.startIndex);
    });

    final accepted = <MentionRef>[];
    for (final candidate in sortedByNewest) {
      final overlapsExisting = accepted.any(
        (existing) =>
            candidate.startIndex < existing.endIndex &&
            candidate.endIndex > existing.startIndex,
      );
      if (!overlapsExisting) {
        accepted.add(candidate);
      }
    }

    accepted.sort((a, b) => a.startIndex.compareTo(b.startIndex));
    return accepted;
  }
}
