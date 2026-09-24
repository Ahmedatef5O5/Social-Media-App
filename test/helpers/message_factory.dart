import 'package:social_media_app/features/single_chats/models/message_model.dart';

/// Fixed clock for every test in the suite. Using `DateTime.now()` inside
/// a fixture is the single most common source of flaky ordering tests —
/// two messages built in the same statement can land on the same
/// millisecond on a fast CI runner and then sort non-deterministically.
final DateTime kEpoch = DateTime.utc(2026, 1, 1, 12, 0, 0);

DateTime at(int secondsAfterEpoch) =>
    kEpoch.add(Duration(seconds: secondsAfterEpoch));

/// Builds a [MessageModel] with only the fields a reconciliation test
/// cares about. Everything else takes the model's own defaults, so this
/// factory does not have to be updated every time a field is added.
MessageModel message({
  required String id,
  String? clientMessageId,
  String senderId = 'me',
  String receiverId = 'them',
  String text = 'hello',
  DateTime? createdAt,
  Map<String, String> reactions = const {},
  Map<String, String>? reactionsCreatedAt,
  bool isRead = false,
  String messageType = 'text',
}) {
  return MessageModel(
    id: id,
    clientMessageId: clientMessageId,
    senderId: senderId,
    receiverId: receiverId,
    text: text,
    createdAt: createdAt ?? kEpoch,
    reactions: reactions,
    reactionsCreatedAt: reactionsCreatedAt,
    isRead: isRead,
    messageType: messageType,
  );
}

extension MessageListIds on List<MessageModel> {
  List<String> get ids => map((m) => m.id).toList();
  List<String> get texts => map((m) => m.text).toList();
}
