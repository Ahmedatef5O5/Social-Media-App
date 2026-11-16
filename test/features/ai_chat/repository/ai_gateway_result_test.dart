import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/features/ai_chat/repository/ai_gateway_client.dart';

void main() {
  group('AiGatewayResult.fromJson', () {
    test('parses token usage and latency from the instrumented gateway', () {
      final r = AiGatewayResult.fromJson({
        'success': true,
        'result': 'hi',
        'provider': 'gemini',
        'model': 'gemini-3.6-flash',
        'degraded': false,
        'request_id': 'r-1',
        'tokens': {
          'prompt_tokens': 120,
          'completion_tokens': 30,
          'total_tokens': 150,
        },
        'latency_ms': 842,
        'quota': {'user_remaining': 14},
      });

      expect(r.success, isTrue);
      expect(r.promptTokens, 120);
      expect(r.completionTokens, 30);
      expect(r.totalTokens, 150);
      expect(r.latencyMs, 842);
      expect(r.provider, 'gemini');
      expect(r.requestId, 'r-1');
    });

    test('stays backward compatible with the v51 payload (no tokens/latency)', () {
      final r = AiGatewayResult.fromJson({
        'success': true,
        'result': 'hi',
        'provider': 'groq',
        'model': 'llama-3.3-70b-versatile',
      });

      expect(r.success, isTrue);
      expect(r.promptTokens, isNull);
      expect(r.completionTokens, isNull);
      expect(r.totalTokens, isNull);
      expect(r.latencyMs, isNull);
      expect(r.degraded, isFalse);
    });

    test('tolerates doubles and malformed token blocks', () {
      final doubles = AiGatewayResult.fromJson({
        'success': true,
        'tokens': {'prompt_tokens': 10.0, 'completion_tokens': 'x'},
        'latency_ms': 5.0,
      });
      expect(doubles.promptTokens, 10);
      expect(doubles.completionTokens, isNull);
      expect(doubles.latencyMs, 5);

      final bad = AiGatewayResult.fromJson({'success': true, 'tokens': 'oops'});
      expect(bad.totalTokens, isNull);
    });

    test('failure payload keeps reason and quota', () {
      final r = AiGatewayResult.fromJson({
        'success': false,
        'reason': 'user_quota_exceeded',
        'quota': {'user_remaining': 0},
      });
      expect(r.success, isFalse);
      expect(r.reason, 'user_quota_exceeded');
      expect(r.quota!['user_remaining'], 0);
    });
  });
}
