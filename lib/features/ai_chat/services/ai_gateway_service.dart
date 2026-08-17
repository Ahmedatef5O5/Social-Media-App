import '../cubit/ai_model_selector_cubit/ai_model_selector_cubit.dart';
import '../cubit/ai_usage_cubit/ai_usage_cubit.dart';
import '../repository/ai_gateway_client.dart';

class AiGatewayService {
  final AiGatewayClient _client;
  final AiModelSelectorCubit _modelSelectorCubit;
  final AiUsageCubit _usageCubit;

  AiGatewayService({
    required AiGatewayClient client,
    required AiModelSelectorCubit modelSelectorCubit,
    required AiUsageCubit usageCubit,
  }) : _client = client,
       _modelSelectorCubit = modelSelectorCubit,
       _usageCubit = usageCubit;

  Future<AiGatewayResult> call({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final result = await _client.callAction(
      action: action,
      payload: payload,
      preferredProvider: _modelSelectorCubit.effectiveRequestProvider,
    );

    if (result.quota != null) {
      _usageCubit.updateFromQuotaMap(
        result.quota!,
        provider: result.success ? result.provider : null,
        model: result.success ? result.model : null,
      );
    }

    if (result.success && result.provider != null && result.model != null) {
      _modelSelectorCubit.onGatewayResponse(
        provider: result.provider!,
        model: result.model!,
        degraded: result.degraded,
      );
    }

    return result;
  }
}
