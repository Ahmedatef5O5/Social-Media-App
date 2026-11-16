// NOTE: written against the signatures seen in the repo export. It needs
// `mocktail` in dev_dependencies and may need small adjustments to the stubbed
// repository return types (AiChatMessageRecord factory). See docs/05.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:social_media_app/features/ai_chat/cubits/ai_chat_cubit/ai_chat_cubit.dart';
import 'package:social_media_app/features/ai_chat/repository/ai_chat_repository.dart';
import 'package:social_media_app/features/ai_chat/repository/ai_gateway_client.dart';
import 'package:social_media_app/features/ai_chat/services/ai_gateway_service.dart';

class _MockRepo extends Mock implements AiChatRepository {}

class _MockGateway extends Mock implements AiGatewayService {}

void main() {
  late _MockRepo repo;
  late _MockGateway gateway;
  Map<String, dynamic>? captured;

  setUp(() {
    repo = _MockRepo();
    gateway = _MockGateway();
    captured = null;

    // Fail the gateway call so the cubit stops right after building the payload.
    when(
      () => gateway.call(
        action: any(named: 'action'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((inv) async {
      captured = inv.namedArguments[#payload] as Map<String, dynamic>;
      return AiGatewayResult(success: false, reason: 'test_stop');
    });
    // appendMessage must be stubbed with a real AiChatMessageRecord in your
    // project (e.g. AiChatMessageRecord.fromJson(...)); see docs/05.
  });

  test('retry sends is_retry: true', () async {
    final cubit = AiChatCubit(
      repository: repo,
      gatewayService: gateway,
      sessionId: 's1',
      isExisting: false,
    );
    await cubit.sendMessage(text: 'hello', isRetry: true);
    expect(captured?['is_retry'], isTrue);
  });

  test('normal send does NOT include is_retry', () async {
    final cubit = AiChatCubit(
      repository: repo,
      gatewayService: gateway,
      sessionId: 's1',
      isExisting: false,
    );
    await cubit.sendMessage(text: 'hello');
    expect(captured?.containsKey('is_retry'), isFalse);
  });
}
