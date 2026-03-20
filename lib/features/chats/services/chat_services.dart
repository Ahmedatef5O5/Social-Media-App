import 'package:social_media_app/core/utilities/app_tables_names.dart';
import 'package:social_media_app/features/chats/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatServices {
  final _supabase = Supabase.instance.client;

  Stream<List<MessageModel>> getMessagesStream({
    required String senderId,
    required String receiverId,
  }) {
    return _supabase
        .from(AppTablesNames.messages)
        .stream(primaryKey: [MessagesColumns.id])
        .order(MessagesColumns.createdAt, ascending: false)
        .map(
          (data) =>
              data
                  .map((map) => MessageModel.fromJson(map))
                  .where(
                    (msg) =>
                        (msg.senderId == senderId &&
                            msg.receiverId == receiverId) ||
                        (msg.senderId == receiverId &&
                            msg.receiverId == senderId),
                  )
                  .toList(),
        );
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    await _supabase.from(AppTablesNames.messages).insert({
      MessagesColumns.senderId: senderId,
      MessagesColumns.receiverId: receiverId,
      MessagesColumns.messageText: text,
    });
  }
}
