import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/ai_model_preference_store.dart';
part 'ai_model_selector_state.dart';

class AiModelSelectorCubit extends Cubit<AiModelSelectorState> {
  final AiModelPreferenceStore _store;

  AiModelSelectorCubit(this._store)
    : super(AiModelSelectorState(preferredProvider: _store.preferredProvider));

  Future<void> setPreferredProvider(String provider) async {
    await _store.setPreferredProvider(provider);
    emit(state.copyWith(preferredProvider: provider, isFallbackActive: false));
  }

  void onGatewayResponse({
    required String provider,
    required String model,
    required bool degraded,
  }) {
    final preferred = state.preferredProvider;
    final fellBack = preferred != null && preferred != provider;

    if (fellBack) {
      reportProviderCooldown(preferred);
    }

    emit(
      state.copyWith(
        lastActiveProvider: provider,
        lastActiveModel: model,
        isFallbackActive: fellBack,
      ),
    );
  }

  void reportProviderCooldown(
    String provider, {
    Duration duration = const Duration(minutes: 5),
  }) {
    _store.markCooldown(provider, duration);
  }

  String? get effectiveRequestProvider {
    final preferred = state.preferredProvider;
    if (preferred != null && !_store.isInCooldown(preferred)) return preferred;

    final lastActive = state.lastActiveProvider;
    if (lastActive != null && !_store.isInCooldown(lastActive)) {
      return lastActive;
    }

    return null;
  }
}
