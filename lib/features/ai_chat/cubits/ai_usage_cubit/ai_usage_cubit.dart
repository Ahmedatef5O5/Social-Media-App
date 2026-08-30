import 'package:flutter_bloc/flutter_bloc.dart';
part 'ai_usage_state.dart';

class AiUsageCubit extends Cubit<AiUsageState> {
  AiUsageCubit() : super(const AiUsageState());

  void updateFromQuotaMap(
    Map<String, dynamic> quota, {
    String? provider,
    String? model,
  }) {
    emit(
      state.copyWith(
        userRemaining: quota['user_remaining'] as int?,
        globalRemaining: quota['global_remaining'] as int?,
        effectiveUserLimit: quota['effective_user_limit'] as int?,
        bonusGranted: quota['bonus_granted'] as int?,
        activeProvider: provider,
        activeModel: model,
      ),
    );
  }
}
