part of 'ai_usage_cubit.dart';

class AiUsageState {
  final int? userRemaining;
  final int? globalRemaining;
  final int? effectiveUserLimit;
  final int? bonusGranted;
  final String? activeProvider;
  final String? activeModel;

  const AiUsageState({
    this.userRemaining,
    this.globalRemaining,
    this.effectiveUserLimit,
    this.bonusGranted,
    this.activeProvider,
    this.activeModel,
  });

  int? get used =>
      (effectiveUserLimit != null && userRemaining != null)
          ? effectiveUserLimit! - userRemaining!
          : null;

  double? get usedFraction {
    final limit = effectiveUserLimit;
    final u = used;
    if (limit == null || limit <= 0 || u == null) return null;
    return u / limit;
  }

  AiUsageState copyWith({
    int? userRemaining,
    int? globalRemaining,
    int? effectiveUserLimit,
    int? bonusGranted,
    String? activeProvider,
    String? activeModel,
  }) {
    return AiUsageState(
      userRemaining: userRemaining ?? this.userRemaining,
      globalRemaining: globalRemaining ?? this.globalRemaining,
      effectiveUserLimit: effectiveUserLimit ?? this.effectiveUserLimit,
      bonusGranted: bonusGranted ?? this.bonusGranted,
      activeProvider: activeProvider ?? this.activeProvider,
      activeModel: activeModel ?? this.activeModel,
    );
  }
}
