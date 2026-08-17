part of 'ai_model_selector_cubit.dart';

class AiModelSelectorState {
  final String? preferredProvider;
  final String? lastActiveProvider;
  final String? lastActiveModel;
  final bool isFallbackActive;

  const AiModelSelectorState({
    required this.preferredProvider,
    this.lastActiveProvider,
    this.lastActiveModel,
    this.isFallbackActive = false,
  });

  String? get displayedProvider => lastActiveProvider ?? preferredProvider;

  AiModelSelectorState copyWith({
    String? preferredProvider,
    String? lastActiveProvider,
    String? lastActiveModel,
    bool? isFallbackActive,
  }) {
    return AiModelSelectorState(
      preferredProvider: preferredProvider ?? this.preferredProvider,
      lastActiveProvider: lastActiveProvider ?? this.lastActiveProvider,
      lastActiveModel: lastActiveModel ?? this.lastActiveModel,
      isFallbackActive: isFallbackActive ?? this.isFallbackActive,
    );
  }
}
