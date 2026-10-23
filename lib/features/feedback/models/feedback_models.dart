import 'package:flutter/cupertino.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

enum FeedbackCategory {
  bug('bug', 'Bug / Issue', CupertinoIcons.ant_fill),
  feature('feature', 'Feature Request', CupertinoIcons.lightbulb_fill),
  inquiry('inquiry', 'Inquiry', CupertinoIcons.question_circle_fill),
  rating('rating', 'Rating & Review', CupertinoIcons.star_fill),
  appreciation('appreciation', 'Appreciation', CupertinoIcons.heart_fill),
  other('other', 'Other', CupertinoIcons.ellipsis_circle_fill);

  final String value;
  final String label;
  final IconData icon;
  const FeedbackCategory(this.value, this.label, this.icon);

  String localizedName(BuildContext context) => switch (this) {
    FeedbackCategory.bug => context.l10n.feedbackCatBug,
    FeedbackCategory.feature => context.l10n.feedbackCatFeature,
    FeedbackCategory.inquiry => context.l10n.feedbackCatInquiry,
    FeedbackCategory.rating => context.l10n.feedbackCatRating,
    FeedbackCategory.appreciation => context.l10n.feedbackCatAppreciation,
    FeedbackCategory.other => context.l10n.feedbackCatOther,
  };

  static FeedbackCategory fromValue(String? v) => FeedbackCategory.values
      .firstWhere((c) => c.value == v, orElse: () => FeedbackCategory.other);
}

enum FeedbackStatus {
  pending('pending', 'Pending Review'),
  inProgress('in_progress', 'In Progress'),
  resolved('resolved', 'Resolved & Answered'),
  closed('closed', 'Closed');

  final String value;
  final String label;
  const FeedbackStatus(this.value, this.label);

  String localizedName(BuildContext context) => switch (this) {
    FeedbackStatus.pending => context.l10n.feedbackStatusPending,
    FeedbackStatus.inProgress => context.l10n.feedbackStatusInProgress,
    FeedbackStatus.resolved => context.l10n.feedbackStatusResolved,
    FeedbackStatus.closed => context.l10n.feedbackStatusClosed,
  };

  static FeedbackStatus fromValue(String? v) => FeedbackStatus.values
      .firstWhere((s) => s.value == v, orElse: () => FeedbackStatus.pending);
}

class UserFeedback {
  final String id;
  final FeedbackCategory category;
  final String message;
  final int? rating;
  final String? imageUrl;
  final String? audioUrl;
  final int? audioDurationSeconds;
  final String? contactMethod;
  final FeedbackStatus status;
  final String? adminResponse;
  final DateTime? respondedAt;
  final DateTime createdAt;

  const UserFeedback({
    required this.id,
    required this.category,
    required this.message,
    required this.status,
    required this.createdAt,
    this.rating,
    this.imageUrl,
    this.audioUrl,
    this.audioDurationSeconds,
    this.contactMethod,
    this.adminResponse,
    this.respondedAt,
  });

  String get shortId => id.length >= 8 ? id.substring(0, 8) : id;
  bool get hasReply => (adminResponse ?? '').trim().isNotEmpty;

  factory UserFeedback.fromMap(Map<String, dynamic> m) => UserFeedback(
    id: m['id'] as String,
    category: FeedbackCategory.fromValue(m['category'] as String?),
    message: (m['message'] as String?) ?? '',
    rating: m['rating'] as int?,
    imageUrl: m['image_url'] as String?,
    audioUrl: m['audio_url'] as String?,
    audioDurationSeconds: m['audio_duration_seconds'] as int?,
    contactMethod: m['contact_method'] as String?,
    status: FeedbackStatus.fromValue(m['status'] as String?),
    adminResponse: m['admin_response'] as String?,
    respondedAt: _date(m['responded_at']),
    createdAt: _date(m['created_at']) ?? DateTime.now(),
  );

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v as String)?.toLocal();
}

/// 24h rolling quota (max 3 submissions), as returned by `get_my_feedback_quota`.
class FeedbackQuota {
  static const int maxPer24h = 3;

  final int used;
  final int limit;
  final DateTime? resetsAt;

  const FeedbackQuota({required this.used, required this.limit, this.resetsAt});

  const FeedbackQuota.unknown() : used = 0, limit = maxPer24h, resetsAt = null;

  bool get isExhausted => used >= limit;
  int get remaining => (limit - used).clamp(0, limit);

  factory FeedbackQuota.fromMap(Map<String, dynamic> m) => FeedbackQuota(
    used: (m['used'] as num?)?.toInt() ?? 0,
    limit: (m['limit'] as num?)?.toInt() ?? maxPer24h,
    resetsAt:
        m['resets_at'] == null
            ? null
            : DateTime.tryParse(m['resets_at'] as String)?.toLocal(),
  );
}
