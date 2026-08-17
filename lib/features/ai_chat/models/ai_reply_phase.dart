enum AiReplyPhase {
  thinking,
  analyzing,
  generating;

  String get label {
    switch (this) {
      case AiReplyPhase.thinking:
        return 'Thinking...';
      case AiReplyPhase.analyzing:
        return 'Analyzing...';
      case AiReplyPhase.generating:
        return 'Generating...';
    }
  }
}
