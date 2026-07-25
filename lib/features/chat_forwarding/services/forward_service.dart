import '../../single_chats/services/chat_services.dart';
import '../../group_chats/services/group_chat_services.dart';
import '../models/forward_target_selection.dart';
import '../models/forwardable_message.dart';

/// Orchestrates the actual forward: for every selected message, creates a
/// brand-new message row for each selected target (person or group),
/// carrying the original payload plus forwarded_from_* metadata. Lives in
/// chat_forwarding (not single_chats or group_chats) because it depends on
/// both — a single Forward action can target people and groups at once.
class ForwardService {
  final ChatServices _chatServices;
  final GroupChatServices _groupChatServices;

  ForwardService({
    ChatServices? chatServices,
    GroupChatServices? groupChatServices,
  }) : _chatServices = chatServices ?? ChatServices(),
       _groupChatServices = groupChatServices ?? GroupChatServices();

  Future<void> forwardMessages({
    required List<ForwardableMessage> messages,
    required ForwardTargetSelection targets,
    required String currentUserId,
  }) async {
    final futures = <Future>[];

    for (final userId in targets.userIds) {
      for (final message in messages) {
        futures.add(
          _chatServices.sendMessage(
            senderId: currentUserId,
            receiverId: userId,
            text: message.text,
            messageType: message.messageType,
            imageUrl: message.imageUrl,
            videoUrl: message.videoUrl,
            voiceUrl: message.voiceUrl,
            durationSeconds: message.durationSeconds,
            fileUrl: message.fileUrl,
            fileName: message.fileName,
            fileSizeBytes: message.fileSizeBytes,
            caption: message.caption,
            forwardedFromUserId: message.originalSenderId,
            forwardedFromUserName: message.originalSenderName,
            forwardedFromUserAvatar: message.originalSenderAvatar,
          ),
        );
      }
    }

    for (final entry in targets.groups.entries) {
      for (final message in messages) {
        futures.add(
          _groupChatServices.sendGroupMessage(
            groupId: entry.key,
            groupName: entry.value,
            text: message.text,
            messageType: message.messageType,
            imageUrl: message.imageUrl,
            videoUrl: message.videoUrl,
            voiceUrl: message.voiceUrl,
            durationSeconds: message.durationSeconds,
            fileUrl: message.fileUrl,
            fileName: message.fileName,
            fileSizeBytes: message.fileSizeBytes,
            caption: message.caption,
            forwardedFromUserId: message.originalSenderId,
            forwardedFromUserName: message.originalSenderName,
            forwardedFromUserAvatar: message.originalSenderAvatar,
          ),
        );
      }
    }

    await Future.wait(futures);
  }
}
