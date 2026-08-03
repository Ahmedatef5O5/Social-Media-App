import 'package:social_media_app/features/group_chats/services/group_chat_services.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';
import 'package:social_media_app/features/single_chats/models/message_model.dart';
import 'package:social_media_app/features/single_chats/services/chat_services.dart';
import '../models/shared_media_item.dart';

abstract class SharedMediaDataSource {
  Future<List<SharedMediaItem>> loadPreview({int limit = 6});
  Future<List<SharedMediaItem>> loadMediaByType(
    String messageType, {
    int limit = 100,
  });
  Future<List<SharedMediaItem>> loadLinks({int limit = 100});
}

class GroupChatMediaDataSource implements SharedMediaDataSource {
  final GroupChatServices services;
  final String groupId;

  GroupChatMediaDataSource({required this.services, required this.groupId});

  @override
  Future<List<SharedMediaItem>> loadPreview({int limit = 6}) async {
    final items = await services.getGroupMediaPreview(
      groupId: groupId,
      limit: limit,
    );
    return items.map((m) => m.toSharedMediaItem()).toList();
  }

  @override
  Future<List<SharedMediaItem>> loadMediaByType(
    String messageType, {
    int limit = 100,
  }) async {
    final items = await services.getGroupMediaMessages(
      groupId: groupId,
      messageType: messageType,
      limit: limit,
    );
    return items.map((m) => m.toSharedMediaItem()).toList();
  }

  @override
  Future<List<SharedMediaItem>> loadLinks({int limit = 100}) async {
    final items = await services.getGroupLinkMessages(
      groupId: groupId,
      limit: limit,
    );
    return items.map((m) => m.toSharedMediaItem()).toList();
  }
}

class SingleChatMediaDataSource implements SharedMediaDataSource {
  final ChatServices services;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserAvatar;
  final ChatUserModel receiverUser;

  SingleChatMediaDataSource({
    required this.services,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatar,
    required this.receiverUser,
  });

  SharedMediaItem _map(MessageModel message) => message.toSharedMediaItem(
    currentUserId: currentUserId,
    currentUserName: currentUserName,
    currentUserAvatar: currentUserAvatar,
    receiverName: receiverUser.name,
    receiverAvatar: receiverUser.imageUrl,
  );

  @override
  Future<List<SharedMediaItem>> loadPreview({int limit = 6}) async {
    final items = await services.getMediaPreview(
      senderId: currentUserId,
      receiverId: receiverUser.id,
      limit: limit,
    );
    return items.map(_map).toList();
  }

  @override
  Future<List<SharedMediaItem>> loadMediaByType(
    String messageType, {
    int limit = 100,
  }) async {
    final items = await services.getMediaMessages(
      senderId: currentUserId,
      receiverId: receiverUser.id,
      messageType: messageType,
      limit: limit,
    );
    return items.map(_map).toList();
  }

  @override
  Future<List<SharedMediaItem>> loadLinks({int limit = 100}) async {
    final items = await services.getLinkMessages(
      senderId: currentUserId,
      receiverId: receiverUser.id,
      limit: limit,
    );
    return items.map(_map).toList();
  }
}
