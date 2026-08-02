class AiQuotaInfo {
  final int? userRemaining;
  final int? globalRemaining;

  const AiQuotaInfo({this.userRemaining, this.globalRemaining});

  factory AiQuotaInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AiQuotaInfo();
    return AiQuotaInfo(
      userRemaining: json['user_remaining'] as int?,
      globalRemaining: json['global_remaining'] as int?,
    );
  }
}

abstract class AiFailureReason {
  static const userQuotaExceeded = 'user_quota_exceeded';
  static const globalQuotaExceeded = 'global_quota_exceeded';
  static const unauthenticated = 'unauthenticated';
  static const error = 'error';
}

class AiResult {
  final bool success;
  final String? text;
  final List<String>? suggestions;
  final String? failureReason;
  final AiQuotaInfo? quota;

  const AiResult({
    required this.success,
    this.text,
    this.suggestions,
    this.failureReason,
    this.quota,
  });

  bool get isQuotaExceeded =>
      failureReason == AiFailureReason.userQuotaExceeded ||
      failureReason == AiFailureReason.globalQuotaExceeded;

  factory AiResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;

    if (!success) {
      return AiResult(
        success: false,
        failureReason: json['reason'] as String? ?? AiFailureReason.error,
        quota: AiQuotaInfo.fromJson(json['quota'] as Map<String, dynamic>?),
      );
    }

    final result = json['result'];
    final quota = AiQuotaInfo.fromJson(json['quota'] as Map<String, dynamic>?);

    if (result is List) {
      return AiResult(
        success: true,
        suggestions: result.map((e) => e.toString()).toList(),
        quota: quota,
      );
    }

    return AiResult(success: true, text: result?.toString(), quota: quota);
  }
}
