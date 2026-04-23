String buildLastMessageGroupPreview({
  required String text,
  required String messageType,
}) {
  switch (messageType) {
    case 'image':
      return '📷 Photo';

    case 'video':
      return '🎥 Video';

    case 'voice':
      return '🎤 Voice message';

    case 'call':
      return '📞 Call';

    default:
      return text;
  }
}
