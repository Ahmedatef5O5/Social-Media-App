import 'ai_active_provider.dart';
import 'ai_result.dart';

class AiUsageSnapshot {
  static const int assumedBaseDailyLimit = 15;
  static const int _stabilityStep = 5;
  final AiActiveProvider activeProvider;
  final String? activeModelId;
  final int usedToday;
  final int dailyLimit;
  final int bonusGranted;
  final bool isPlaceholder;

  const AiUsageSnapshot({
    required this.activeProvider,
    this.activeModelId,
    required this.usedToday,
    required this.dailyLimit,
    required this.bonusGranted,
    this.isPlaceholder = false,
  });

  factory AiUsageSnapshot.unknown() => const AiUsageSnapshot(
    activeProvider: AiActiveProvider.unknown,
    activeModelId: null,
    usedToday: 0,
    dailyLimit: assumedBaseDailyLimit,
    bonusGranted: 0,
    isPlaceholder: true,
  );

  AiUsageSnapshot mergeQuota(
    AiQuotaInfo quota, {
    String? provider,
    String? modelId,
  }) {
    final serverLimit = quota.effectiveUserLimit ?? dailyLimit;
    final serverRemaining = quota.userRemaining ?? (serverLimit - usedToday);
    final trueUsedToday = (serverLimit - serverRemaining).clamp(0, serverLimit);
    final rawBonus = quota.bonusGranted ?? bonusGranted;

    return AiUsageSnapshot(
      activeProvider:
          provider != null
              ? AiActiveProviderX.fromWireValue(provider)
              : activeProvider,
      activeModelId: modelId ?? activeModelId,
      usedToday: trueUsedToday,
      dailyLimit: _stabilize(previous: dailyLimit, incoming: serverLimit),
      bonusGranted: _stabilize(previous: bonusGranted, incoming: rawBonus),
      isPlaceholder: false,
    );
  }

  static int _stabilize({required int previous, required int incoming}) {
    int ceilToStep(int v) =>
        ((v + _stabilityStep - 1) ~/ _stabilityStep) * _stabilityStep;
    final roundedIncoming = ceilToStep(incoming);
    final roundedPrevious = ceilToStep(previous);
    return roundedIncoming == roundedPrevious ? previous : roundedIncoming;
  }

  Map<String, dynamic> toJson() => {
    'active_provider': activeProvider.wireValue,
    'active_model_id': activeModelId, // [NEW]
    'used_today': usedToday,
    'daily_limit': dailyLimit,
    'bonus_granted': bonusGranted,
    'cached_at_utc_date': _utcDateKey(DateTime.now().toUtc()),
  };

  factory AiUsageSnapshot.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return AiUsageSnapshot.unknown();

    final cachedDateKey = json['cached_at_utc_date'] as String?;
    final todayKey = _utcDateKey(DateTime.now().toUtc());
    if (cachedDateKey != todayKey) return AiUsageSnapshot.unknown();

    return AiUsageSnapshot(
      activeProvider: AiActiveProviderX.fromWireValue(
        json['active_provider'] as String?,
      ),
      activeModelId: json['active_model_id'] as String?,
      usedToday: json['used_today'] as int? ?? 0,
      dailyLimit: json['daily_limit'] as int? ?? assumedBaseDailyLimit,
      bonusGranted: json['bonus_granted'] as int? ?? 0,
      isPlaceholder: false,
    );
  }

  static String _utcDateKey(DateTime utc) =>
      '${utc.year.toString().padLeft(4, '0')}-'
      '${utc.month.toString().padLeft(2, '0')}-'
      '${utc.day.toString().padLeft(2, '0')}';
}
