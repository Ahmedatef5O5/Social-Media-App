import 'package:supabase_flutter/supabase_flutter.dart';

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

  factory AiGatewayResult.fromJson(Map<String, dynamic> json) {
    return AiGatewayResult(
      success: json['success'] as bool? ?? false,
      result: json['result'],
      provider: json['provider'] as String?,
      model: json['model'] as String?,
      degraded: json['degraded'] as bool? ?? false,
      requestId: json['request_id'] as String?,
      reason: json['reason'] as String?,
      quota: json['quota'] as Map<String, dynamic>?,
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

    final response = await _supabase.functions.invoke('ai-gateway', body: body);
    final data = response.data as Map<String, dynamic>;
    return AiGatewayResult.fromJson(data);
  }
}
