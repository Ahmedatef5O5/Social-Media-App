import '../../../core/presence/services/presence_service.dart';
import '../../single_chats/models/chat_user_model.dart';

class StoryViewerModel {
  final String viewerId;
  final String userName;
  final String? userImageUrl;
  final String? reaction;
  final DateTime viewedAt;
  final bool isOnline;
  final DateTime? lastSeen;

  const StoryViewerModel({
    required this.viewerId,
    required this.userName,
    this.userImageUrl,
    this.reaction,
    required this.viewedAt,
    required this.isOnline,
    this.lastSeen,
  });

  bool get hasReacted => reaction != null && reaction!.isNotEmpty;

  bool get isActuallyOnline => PresenceService.isConsideredOnline(
    isOnline: isOnline,
    updatedAt: lastSeen,
  );

  factory StoryViewerModel.fromMap(Map<String, dynamic> map) {
    return StoryViewerModel(
      viewerId: map['viewer_id'] as String? ?? '',
      userName: map['user_name'] as String? ?? 'Unknown User',
      userImageUrl: map['user_image_url'] as String?,
      reaction: map['reaction'] as String?,
      viewedAt:
          DateTime.tryParse(map['viewed_at']?.toString() ?? '') ??
          DateTime.now(),
      isOnline: map['is_online'] as bool? ?? false,
      lastSeen:
          map['last_seen'] != null
              ? DateTime.tryParse(map['last_seen'].toString())
              : null,
    );
  }

  ChatUserModel toChatUserModel() {
    return ChatUserModel(
      id: viewerId,
      name: userName,
      imageUrl: userImageUrl,
      lastSeen: lastSeen,
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'viewer_id': viewerId,
    'user_name': userName,
    'user_image_url': userImageUrl,
    'reaction': reaction,
    'viewed_at': viewedAt.toIso8601String(),
    'is_online': isOnline,
    'last_seen': lastSeen?.toIso8601String(),
  };
}
