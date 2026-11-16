import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/infrastructure/service_health_coordinator.dart';
import '../../settings/repository/settings_repository.dart';

class AiGatewayResult {
  AiGatewayResult({
    required this.success,
    this.result,
    this.provider,
    this.model,
    this.degraded = false,
    this.requestId,
    this.reason,
    this.quota,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.latencyMs,
  });

  final bool success;
  final dynamic
  result; // String for most actions, List<dynamic> for comment_suggestions
  final String? provider;
  final String? model;
  final bool degraded;

  final String? requestId;

  final String? reason;
  final Map<String, dynamic>? quota;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final int? latencyMs;
  static int? _asInt(dynamic v) => v is num ? v.toInt() : null;

  factory AiGatewayResult.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'];
    final tokenMap = tokens is Map ? Map<String, dynamic>.from(tokens) : null;

    return AiGatewayResult(
      success: json['success'] as bool? ?? false,
      result: json['result'],
      provider: json['provider'] as String?,
      model: json['model'] as String?,
      degraded: json['degraded'] as bool? ?? false,
      requestId: json['request_id'] as String?,
      reason: json['reason'] as String?,
      quota: json['quota'] as Map<String, dynamic>?,
      promptTokens: _asInt(tokenMap?['prompt_tokens']),
      completionTokens: _asInt(tokenMap?['completion_tokens']),
      totalTokens: _asInt(tokenMap?['total_tokens']),
      latencyMs: _asInt(json['latency_ms']),
    );
  }
}

class AiGatewayClient {
  AiGatewayClient(this._supabase);

  final SupabaseClient _supabase;

  Future<AiGatewayResult> callAction({
    required String action,
    required Map<String, dynamic> payload,
    String? preferredProvider,
  }) async {
    final body = {
      'action': action,
      'payload': {
        ...payload,
        if (preferredProvider != null) 'preferred_provider': preferredProvider,
      },
    };

    final healthTimer = Stopwatch()..start();
    try {
      final response = await _supabase.functions.invoke(
        'ai-gateway',
        body: body,
        // Lets the assistant default to the user's chosen UI language.
        headers: {'x-user-language': SettingsRepository.instance.languageCode},
      );
      final data = response.data as Map<String, dynamic>;
      final result = AiGatewayResult.fromJson(data);
      // `degraded` = the primary provider failed and a fallback answered.
      ServiceHealthCoordinator.instance.reportAiGateway(
        success: result.success,
        duration: healthTimer.elapsed,
        degraded: result.degraded,
        provider: result.provider,
        reason: result.reason,
      );
      return result;
    } catch (e) {
      // A 4xx from the gateway (quota, auth, bad request) is the gateway
      // doing its job; only transport failures and 5xx mean it is unhealthy.
      final answeredOnPurpose =
          e is FunctionException && e.status >= 400 && e.status < 500;
      ServiceHealthCoordinator.instance.reportAiGateway(
        success: false,
        duration: healthTimer.elapsed,
        expectedFailure: answeredOnPurpose,
        error: e,
      );
      rethrow;
    }
  }
}
