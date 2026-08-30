import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/cache/constants/hive_box_names.dart';
import '../../../core/cache/constants/hive_type_ids.dart';
import '../cubits/ai_chat_sessions_cubit/ai_chat_sessions_cubit.dart';
import '../cubits/ai_model_selector_cubit/ai_model_selector_cubit.dart';
import '../cubits/ai_usage_cubit/ai_usage_cubit.dart';
import '../models/ai_chat_message_record.dart';
import '../models/ai_chat_session.dart';
import '../models/ai_model_preference_store.dart';
import '../repository/ai_chat_repository.dart';
import '../repository/ai_gateway_client.dart';
import '../services/ai_gateway_service.dart';

class AiChatDependencies {
  final AiChatRepository repository;
  final AiGatewayService gatewayService;
  final AiModelSelectorCubit modelSelectorCubit;
  final AiUsageCubit usageCubit;
  final AiChatSessionsCubit sessionsCubit;

  AiChatDependencies._({
    required this.repository,
    required this.gatewayService,
    required this.modelSelectorCubit,
    required this.usageCubit,
    required this.sessionsCubit,
  });

  String? lastActiveSessionId;

  static Future<AiChatDependencies>? _cached;

  static Future<AiChatDependencies> instance() {
    return _cached ??= _create();
  }

  static void resetForTesting() => _cached = null;

  static Future<AiChatDependencies> _create() async {
    _registerAdapters();

    final sessionsBox = await _openBoxSafely<AiChatSession>(
      HiveBoxNames.aiChatSessions,
    );
    final messagesBox = await _openBoxSafely<AiChatMessageRecord>(
      HiveBoxNames.aiChatMessages,
    );
    final preferenceBox = await _openBoxSafely<dynamic>(
      AiModelPreferenceStore.boxName,
    );

    final supabase = Supabase.instance.client;

    final repository = AiChatRepository(
      supabase: supabase,
      sessionsBox: sessionsBox,
      messagesBox: messagesBox,
    );

    final modelSelectorCubit = AiModelSelectorCubit(
      AiModelPreferenceStore(preferenceBox),
    );
    final usageCubit = AiUsageCubit();
    final sessionsCubit = AiChatSessionsCubit(repository);

    final gatewayService = AiGatewayService(
      client: AiGatewayClient(supabase),
      modelSelectorCubit: modelSelectorCubit,
      usageCubit: usageCubit,
    );

    return AiChatDependencies._(
      repository: repository,
      gatewayService: gatewayService,
      modelSelectorCubit: modelSelectorCubit,
      usageCubit: usageCubit,
      sessionsCubit: sessionsCubit,
    );
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(HiveTypeIds.aiChatSession)) {
      Hive.registerAdapter(AiChatSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.aiChatMessage)) {
      Hive.registerAdapter(AiChatMessageRecordAdapter());
    }
  }

  static Future<Box<T>> _openBoxSafely<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(boxName);
      return await Hive.openBox<T>(boxName);
    }
  }
}
