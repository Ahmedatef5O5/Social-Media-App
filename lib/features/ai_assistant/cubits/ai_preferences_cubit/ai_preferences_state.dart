part of 'ai_preferences_cubit.dart';

class AiPreferencesState {
  final bool isLoaded;
  final bool autoCompleteEnabled;
  final bool autoDetectEnabled;
  final bool commentSuggestionsEnabled;
  final AiAutoCompleteLanguage language;
  final AiReplyTone replyTone;
  final AiReplyLength replyLength;
  final AiUsageSnapshot usage;

  const AiPreferencesState({
    required this.isLoaded,
    required this.autoCompleteEnabled,
    required this.autoDetectEnabled,
    required this.commentSuggestionsEnabled,
    required this.language,
    required this.replyTone,
    required this.replyLength,
    required this.usage,
  });

  factory AiPreferencesState.initial() => AiPreferencesState(
    isLoaded: false,
    autoCompleteEnabled: true,
    autoDetectEnabled: false,
    commentSuggestionsEnabled: true,
    language: AiAutoCompleteLanguage.auto,
    replyTone: AiReplyTone.standard,
    replyLength: AiReplyLength.standard,
    usage: AiUsageSnapshot.unknown(),
  );

  AiPreferencesState copyWith({
    bool? isLoaded,
    bool? autoCompleteEnabled,
    bool? autoDetectEnabled,
    bool? commentSuggestionsEnabled,
    AiAutoCompleteLanguage? language,
    AiReplyTone? replyTone,
    AiReplyLength? replyLength,
    AiUsageSnapshot? usage,
  }) {
    return AiPreferencesState(
      isLoaded: isLoaded ?? this.isLoaded,
      autoCompleteEnabled: autoCompleteEnabled ?? this.autoCompleteEnabled,
      autoDetectEnabled: autoDetectEnabled ?? this.autoDetectEnabled,
      commentSuggestionsEnabled:
          commentSuggestionsEnabled ?? this.commentSuggestionsEnabled,
      language: language ?? this.language,
      replyTone: replyTone ?? this.replyTone,
      replyLength: replyLength ?? this.replyLength,
      usage: usage ?? this.usage,
    );
  }
}