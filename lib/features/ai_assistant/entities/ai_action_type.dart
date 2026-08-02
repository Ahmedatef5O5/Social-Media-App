enum AiActionType {
  autocompleteCaption,
  spellCheck,
  replySuggestion,
  commentSuggestions,
  chatSummaryShort,
  chatSummaryDetailed,
  chatSummaryTopic,
}

extension AiActionTypeApi on AiActionType {
  String get wireValue {
    switch (this) {
      case AiActionType.autocompleteCaption:
        return 'autocomplete_caption';
      case AiActionType.spellCheck:
        return 'spell_check';
      case AiActionType.replySuggestion:
        return 'reply_suggestion';
      case AiActionType.commentSuggestions:
        return 'comment_suggestions';
      case AiActionType.chatSummaryShort:
        return 'chat_summary_short';
      case AiActionType.chatSummaryDetailed:
        return 'chat_summary_detailed';
      case AiActionType.chatSummaryTopic:
        return 'chat_summary_topic';
    }
  }
}
