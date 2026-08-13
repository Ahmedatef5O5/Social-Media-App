import 'package:flutter_bloc/flutter_bloc.dart';
import '../../entities/ai_autocomplete_language.dart';
import '../../entities/ai_reply_length.dart';
import '../../entities/ai_reply_tone.dart';
import '../../entities/ai_result.dart';
import '../../entities/ai_usage_snapshot.dart';
import '../../services/ai_preferences_store.dart';
part 'ai_preferences_state.dart';

class AiPreferencesCubit extends Cubit<AiPreferencesState> {
  final AiPreferencesStore _store;

  AiPreferencesCubit({AiPreferencesStore? store})
    : _store = store ?? AiPreferencesStore.instance,
      super(AiPreferencesState.initial());

  Future<void> init() async {
    final autoComplete = await _store.getAutoCompleteEnabled();
    final autoDetect = await _store.getAutoDetectEnabled();
    final commentSuggestions = await _store.getCommentSuggestionsEnabled();
    final language = await _store.getLanguage();
    final replyTone = await _store.getReplyTone();
    final replyLength = await _store.getReplyLength();
    final usage = await _store.getCachedUsage();

    emit(
      state.copyWith(
        isLoaded: true,
        autoCompleteEnabled: autoComplete,
        autoDetectEnabled: autoDetect,
        commentSuggestionsEnabled: commentSuggestions,
        language: language,
        replyTone: replyTone,
        replyLength: replyLength,
        usage: usage,
      ),
    );
  }

  Future<void> toggleAutoComplete(bool value) async {
    emit(state.copyWith(autoCompleteEnabled: value));
    await _store.setAutoCompleteEnabled(value);
  }

  Future<void> toggleAutoDetect(bool value) async {
    emit(state.copyWith(autoDetectEnabled: value));
    await _store.setAutoDetectEnabled(value);
  }

  Future<void> toggleCommentSuggestions(bool value) async {
    emit(state.copyWith(commentSuggestionsEnabled: value));
    await _store.setCommentSuggestionsEnabled(value);
  }

  Future<void> setLanguage(AiAutoCompleteLanguage value) async {
    emit(state.copyWith(language: value));
    await _store.setLanguage(value);
  }

  Future<void> setReplyTone(AiReplyTone value) async {
    emit(state.copyWith(replyTone: value));
    await _store.setReplyTone(value);
  }

  Future<void> setReplyLength(AiReplyLength value) async {
    emit(state.copyWith(replyLength: value));
    await _store.setReplyLength(value);
  }

  Future<void> recordUsageFromQuota(
    AiQuotaInfo quota, {
    String? provider,
    String? modelId,
  }) async {
    final snapshot = state.usage.mergeQuota(
      quota,
      provider: provider,
      modelId: modelId,
    );
    emit(state.copyWith(usage: snapshot));
    await _store.setCachedUsage(snapshot);
  }
}
