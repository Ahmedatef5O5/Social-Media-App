import 'package:flutter/foundation.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../models/app_notification_model.dart';

class NotificationRepository {
  NotificationRepository._();
  static final NotificationRepository instance = NotificationRepository._();

  final _db = SupabaseProvider.client;

  Future<void> _insert(Map<String, dynamic> row) async {
    try {
      await _db.from('notifications').insert(row);
    } catch (e) {
      // Silent – never crash the caller
    }
  }

  Future<void> notifyChatMessage({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String senderImageUrl,
    required String messageBody,
    required String messageType,
    required String chatReferenceId,
    String? fileName,
  }) async {
    final String body = _chatBody(messageBody, messageType, fileName: fileName);
    await _insert({
      'receiver_id': receiverId,
      'sender_id': senderId,
      'type': 'chat',
      'title': senderName,
      'body': body,
      'sender_image_url': senderImageUrl,
      'reference_id': chatReferenceId,
      'is_read': false,
    });
  }

  Future<void> notifyGroupMessage({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String senderImageUrl,
    required String groupId,
    required String groupName,
    required String messageBody,
    required String messageType,
    String? fileName,
  }) async {
    final String body = _chatBody(messageBody, messageType, fileName: fileName);
    await _insert({
      'receiver_id': receiverId,
      'sender_id': senderId,
      'type': 'group_message',
      'title': groupName,
      'body': '$senderName: $body',
      'sender_image_url': senderImageUrl,
      'reference_id': groupId,
      'is_read': false,
    });
  }

  Future<void> notifyMissedCall({
    required String receiverId,
    required String callerId,
    required String callerName,
    required String callerImageUrl,
    required String callType,
    required String callId,
  }) async {
    final icon = callType == 'video' ? '🎥' : '📞';
    await _insert({
      'receiver_id': receiverId,
      'sender_id': callerId,
      'type': 'call',
      'title': callerName,
      'body': '$icon Missed ${callType == 'video' ? 'video' : 'voice'} call',
      'sender_image_url': callerImageUrl,
      'reference_id': callId,
      'is_read': false,
    });
  }

  Future<void> notifyLike({
    required String receiverId,
    required String likerId,
    required String likerName,
    required String likerImageUrl,
    required String postId,
    String emoji = '❤️',
  }) async {
    await _insert({
      'receiver_id': receiverId,
      'sender_id': likerId,
      'type': 'like',
      'title': likerName,
      'body': '$emoji reacted to your post',
      'sender_image_url': likerImageUrl,
      'reference_id': postId,
      'is_read': false,
    });
  }

  Future<void> notifyCommentReaction({
    required String receiverId,
    required String reactorId,
    required String reactorName,
    required String reactorImageUrl,
    required String postId,
    String emoji = '❤️',
  }) async {
    await _insert({
      'receiver_id': receiverId,
      'sender_id': reactorId,
      'type': 'comment',
      'title': reactorName,
      'body': '$emoji reacted to your comment',
      'sender_image_url': reactorImageUrl,
      'reference_id': postId,
      'is_read': false,
    });
  }

  Future<void> notifyComment({
    required String receiverId,
    required String commenterId,
    required String commenterName,
    required String commenterImageUrl,
    required String postId,
    required String commentPreview,
    bool isReply = false,
  }) async {
    final preview =
        commentPreview.length > 50
            ? '${commentPreview.substring(0, 50)}…'
            : commentPreview;
    await _insert({
      'receiver_id': receiverId,
      'sender_id': commenterId,
      'type': 'comment',
      'title': commenterName,
      'body': isReply ? '↩️ replied: $preview' : '💬 commented: $preview',
      'sender_image_url': commenterImageUrl,
      'reference_id': postId,
      'is_read': false,
    });
  }

  Future<void> notifyShare({
    required String receiverId,
    required String sharerId,
    required String sharerName,
    required String sharerImageUrl,
    required String postId,
  }) async {
    await _insert({
      'receiver_id': receiverId,
      'sender_id': sharerId,
      'type': 'share',
      'title': sharerName,
      'body': '🔁 shared your post',
      'sender_image_url': sharerImageUrl,
      'reference_id': postId,
      'is_read': false,
    });
  }

  Future<void> notifyFollow({
    required String receiverId,
    required String followerId,
    required String followerName,
    required String followerImageUrl,
  }) async {
    await _removeNotification(
      receiverId: receiverId,
      senderId: followerId,
      type: 'follow',
    );
    await _insert({
      'receiver_id': receiverId,
      'sender_id': followerId,
      'type': 'follow',
      'title': followerName,
      'body': '👥 started following you',
      'sender_image_url': followerImageUrl,
      'reference_id': followerId,
      'is_read': false,
    });
  }

  Future<void> removeFollowNotification({
    required String receiverId,
    required String senderId,
  }) => _removeNotification(
    receiverId: receiverId,
    senderId: senderId,
    type: 'follow',
  );

  Future<void> notifyFriendRequest({
    required String receiverId,
    required String requesterId,
    required String requesterName,
    required String requesterImageUrl,
    required String friendshipId,
  }) async {
    await _removeNotification(
      receiverId: receiverId,
      senderId: requesterId,
      type: 'friend_request',
    );

    await _insert({
      'receiver_id': receiverId,
      'sender_id': requesterId,
      'type': 'friend_request',
      'title': requesterName,
      'body': '👤 sent you a friend request',
      'sender_image_url': requesterImageUrl,
      'reference_id': friendshipId,
      'is_read': false,
    });
  }

  Future<void> removeFriendRequestNotification({
    required String receiverId,
    required String senderId,
  }) => _removeNotification(
    receiverId: receiverId,
    senderId: senderId,
    type: 'friend_request',
  );

  Future<void> notifyFriendAccept({
    required String receiverId,
    required String accepterId,
    required String accepterName,
    required String accepterImageUrl,
  }) async {
    await _insert({
      'receiver_id': receiverId,
      'sender_id': accepterId,
      'type': 'friend_accept',
      'title': accepterName,
      'body': '🤝 accepted your friend request',
      'sender_image_url': accepterImageUrl,
      'reference_id': accepterId,
      'is_read': false,
    });
  }

  Future<void> _removeNotification({
    required String receiverId,
    required String senderId,
    required String type,
  }) async {
    try {
      await _db
          .from('notifications')
          .delete()
          .eq('receiver_id', receiverId)
          .eq('sender_id', senderId)
          .eq('type', type);
    } catch (_) {
      /// Silent - never crash the caller
    }
  }

  String _chatBody(String text, String type, {String? fileName}) {
    final cleanText = text.trim();
    final cleanFileName = fileName?.trim();
    final hasFileName = cleanFileName != null && cleanFileName.isNotEmpty;
    final hasText = cleanText.isNotEmpty;

    switch (type) {
      case 'image':
        return hasText ? '📷 $cleanText' : '📷 Photo';
      case 'video':
        return hasText ? '🎥 $cleanText' : '🎥 Video';
      case 'voice':
        return '🎤 Voice message';
      case 'gif':
        return '🖼️ GIF';
      case 'sticker':
        return '🏷️ Sticker';
      case 'file':
      case 'document':
        final hasDistinctCaption =
            hasText && cleanText != cleanFileName && cleanText != 'File';
        if (hasFileName && hasDistinctCaption) {
          return '📄 $cleanFileName • $cleanText';
        } else if (hasFileName) {
          return '📄 $cleanFileName';
        } else if (hasText) {
          return '📄 $cleanText';
        }
        return '📄 File';
      case 'call':
        return '📞 Missed call';
      default:
        return hasText ? cleanText : '📎 Attachment';
    }
  }

  bool _needsMessageBodyHydration(String? rawBody) {
    final b = (rawBody ?? '').trim();
    if (b.isEmpty) return true;
    final content =
        b.contains(': ') ? b.substring(b.indexOf(': ') + 2).trim() : b;
    return content.isEmpty ||
        content == '📄 Sent an attachment' ||
        content == 'Sent an attachment' ||
        content == '📎 Attachment' ||
        content == '📄 File' ||
        content == '📄 Sent a file';
  }

  String? _resolveFileNameFromMessageRow(Map<String, dynamic> msg) {
    final explicitName = (msg['file_name'] as String?)?.trim();
    if (explicitName != null &&
        explicitName.isNotEmpty &&
        explicitName.toLowerCase() != 'file') {
      return explicitName;
    }
    final textName = (msg['message_text'] as String?)?.trim();
    if (textName != null &&
        textName.isNotEmpty &&
        textName.toLowerCase() != 'file') {
      return textName;
    }
    final fileUrl = (msg['file_url'] as String?)?.trim();
    if (fileUrl != null && fileUrl.isNotEmpty) {
      final uri = Uri.tryParse(fileUrl);
      final lastSeg =
          uri != null && uri.pathSegments.isNotEmpty
              ? uri.pathSegments.last
              : fileUrl.split('/').last;
      if (lastSeg.isNotEmpty) return Uri.decodeComponent(lastSeg);
    }
    return null;
  }

  Future<List<AppNotification>> fetchNotifications({int limit = 60}) async {
    final userId = SupabaseProvider.id;
    final data = await _db
        .from('notifications')
        .select()
        .eq('receiver_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    final rows =
        (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    if (rows.isEmpty) return [];

    final senderIds =
        rows
            .map((r) => r['sender_id'] as String?)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

    final Map<String, Map<String, dynamic>> usersById = {};
    if (senderIds.isNotEmpty) {
      try {
        final usersData = await _db
            .from('users')
            .select('id, name, image_url')
            .inFilter('id', senderIds);
        for (final u in (usersData as List)) {
          final map = u as Map<String, dynamic>;
          final id = map['id'] as String?;
          if (id != null) {
            usersById[id] = map;
          }
        }
      } catch (e) {
        debugPrint('[NotificationsRepository] user hydration failed: $e');
      }
    }

    final groupIds =
        rows
            .where((r) => r['type'] == 'group_message')
            .map((r) => r['reference_id'] as String?)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

    final Map<String, Map<String, dynamic>> groupsById = {};
    if (groupIds.isNotEmpty) {
      try {
        final groupsData = await _db
            .from('groups')
            .select('id, name')
            .inFilter('id', groupIds);
        for (final g in (groupsData as List)) {
          final map = g as Map<String, dynamic>;
          final id = map['id'] as String?;
          if (id != null) {
            groupsById[id] = map;
          }
        }
      } catch (e) {
        debugPrint('[NotificationsRepository] group hydration failed: $e');
      }
    }

    final chatSendersToHydrate =
        rows
            .where(
              (r) =>
                  r['type'] == 'chat' &&
                  _needsMessageBodyHydration(r['body'] as String?),
            )
            .map((r) => r['sender_id'] as String?)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

    final Map<String, List<Map<String, dynamic>>> chatMessagesBySender = {};
    if (chatSendersToHydrate.isNotEmpty) {
      try {
        final msgData = await _db
            .from('messages')
            .select(
              'id, sender_id, message_text, message_type, file_name, file_url, caption, created_at',
            )
            .eq('receiver_id', userId)
            .inFilter('sender_id', chatSendersToHydrate)
            .order('created_at', ascending: false)
            .limit(100);

        for (final m in (msgData as List)) {
          final map = m as Map<String, dynamic>;
          final sId = map['sender_id'] as String?;
          if (sId != null) {
            chatMessagesBySender.putIfAbsent(sId, () => []).add(map);
          }
        }
      } catch (e) {
        debugPrint(
          '[NotificationsRepository] chat message hydration failed: $e',
        );
      }
    }

    for (final row in rows) {
      final senderId = row['sender_id'] as String?;
      final user = senderId != null ? usersById[senderId] : null;
      final type = row['type'] as String? ?? 'general';

      if (type == 'chat' &&
          senderId != null &&
          _needsMessageBodyHydration(row['body'] as String?)) {
        final candidates = chatMessagesBySender[senderId];
        if (candidates != null && candidates.isNotEmpty) {
          final notifTime =
              DateTime.tryParse(row['created_at'] as String? ?? '') ??
              DateTime.now();
          Map<String, dynamic>? bestMatch;
          int? smallestDiffMs;

          for (final msg in candidates) {
            final msgTime = DateTime.tryParse(
              msg['created_at'] as String? ?? '',
            );
            if (msgTime == null) continue;
            final diffMs = notifTime.difference(msgTime).inMilliseconds.abs();
            if (smallestDiffMs == null || diffMs < smallestDiffMs) {
              smallestDiffMs = diffMs;
              bestMatch = msg;
            }
          }

          bestMatch ??= candidates.first;
          final msgType = bestMatch['message_type'] as String? ?? 'text';
          final resolvedFileName = _resolveFileNameFromMessageRow(bestMatch);
          final captionOrText =
              (bestMatch['caption'] as String?)?.trim().isNotEmpty == true
                  ? (bestMatch['caption'] as String)
                  : (bestMatch['message_text'] as String? ?? '');

          final hydratedBody = _chatBody(
            captionOrText,
            msgType,
            fileName: resolvedFileName,
          );
          row['body'] = hydratedBody;

          final notifId = row['id'] as String?;
          if (notifId != null && notifId.isNotEmpty) {
            _db
                .from('notifications')
                .update({'body': hydratedBody})
                .eq('id', notifId)
                .then((_) {}, onError: (_) {});
          }
        }
      }

      if (user != null) {
        final liveImageUrl = user['image_url'] as String?;
        final liveName = (user['name'] as String?)?.trim();

        row['sender_image_url'] = liveImageUrl;

        if (liveName != null && liveName.isNotEmpty) {
          if (type == 'group_message') {
            final oldBody = row['body'] as String? ?? '';
            final colonIdx = oldBody.indexOf(': ');
            if (colonIdx != -1) {
              row['body'] = '$liveName${oldBody.substring(colonIdx)}';
            }
          } else {
            row['title'] = liveName;
          }
        }
      }

      if (type == 'group_message') {
        final groupId = row['reference_id'] as String?;
        final group = groupId != null ? groupsById[groupId] : null;
        final liveGroupName = (group?['name'] as String?)?.trim();
        if (liveGroupName != null && liveGroupName.isNotEmpty) {
          row['title'] = liveGroupName;
        }
      }
    }

    return rows.map(AppNotification.fromMap).toList();
  }

  Future<void> markAsRead(String id) async {
    try {
      await _db.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (e) {
      debugPrint(
        '[NotificationsRepository] failed to mark notification as read: $e',
      );
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _db.from('notifications').delete().eq('id', id);
    } catch (e) {
      debugPrint('[NotificationsRepository] failed to delete notification: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = SupabaseProvider.id;
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('receiver_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint(
        '[NotificationsRepository] failed to mark all notifications as read: $e',
      );
    }
  }
}
