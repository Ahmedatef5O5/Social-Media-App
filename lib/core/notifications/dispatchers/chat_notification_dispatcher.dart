import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/core/helpers/chat_helper.dart';
import 'package:social_media_app/core/notifications/channels/notification_channel_setup.dart';
import 'package:social_media_app/core/notifications/helpers/notification_avatar_builder.dart';
import 'package:social_media_app/core/notifications/helpers/notification_id_helper.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/features/group_chats/services/group_chat_services.dart';
import 'package:social_media_app/features/settings/repository/settings_repository.dart';
import 'package:social_media_app/features/single_chats/services/chat_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class _StoredMessage {
  final String text;
  final String senderName;
  final int timestamp;

  const _StoredMessage({
    required this.text,
    required this.senderName,
    required this.timestamp,
  });
}

class ChatNotificationDispatcher {
  ChatNotificationDispatcher._();
  static final ChatNotificationDispatcher instance =
      ChatNotificationDispatcher._();

  final NotificationAvatarBuilder _avatarBuilder = NotificationAvatarBuilder();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> showNotificationFromMessage(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;

    final String type = data['notificationType'] ?? 'chat';
    final bool isGroup = type == 'group_message';

    await _hydrateMessageCache(data, isGroup);

    final String conversationId =
        isGroup ? (data['groupId'] ?? '') : (data['senderId'] ?? '');

    final String senderName =
        data['senderName'] ?? notification?.title ?? 'New Message';

    final String conversationTitle =
        isGroup ? (data['groupName'] ?? 'Group') : senderName;
    final bool isForwarded = data['is_forwarded'] == 'true';

    final String rawBody =
        SettingsRepository.instance.messagePreviews
            ? _buildStyleBody(
              data['messageType'] ?? 'text',
              data['messageBody'] ?? notification?.body ?? '',
              fileName: data['fileName'] as String?,
            )
            : 'New message';

    final String body = isForwarded ? '↪️ Forwarded: $rawBody' : rawBody;
    final String? avatarUrl = data['senderImageUrl'];

    Future<Uint8List> getGroupAvatarBitmap(
      String groupName,
      String? groupImageUrl,
    ) async {
      if (groupImageUrl != null && groupImageUrl.isNotEmpty) {
        final bytes = await _avatarBuilder.fetchBitmap(groupImageUrl);
        if (bytes != null) return bytes;
      }

      return await _avatarBuilder.buildLetterAvatar(groupName);
    }

    final stored = await _appendToMessageHistory(
      conversationId,
      _StoredMessage(
        text: body,
        senderName: senderName,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    final Uint8List senderBitmap = await _avatarBuilder.getAvatarBitmap(
      avatarUrl,
    );
    final Uint8List headerBitmap =
        isGroup
            ? await getGroupAvatarBitmap(
              conversationTitle,
              data['groupImageUrl'],
            )
            : senderBitmap;

    final ByteArrayAndroidIcon headerIcon = ByteArrayAndroidIcon(headerBitmap);
    final ByteArrayAndroidIcon senderIcon = ByteArrayAndroidIcon(senderBitmap);

    const Person me = Person(name: 'Me', important: true);

    final Person remotePerson =
        isGroup
            ? Person(name: conversationTitle, icon: headerIcon)
            : Person(name: senderName, icon: senderIcon);

    final List<Message> styleMessages =
        stored
            .map(
              (m) => Message(
                isGroup ? '${m.senderName}: ${m.text}' : m.text,
                DateTime.fromMillisecondsSinceEpoch(m.timestamp),
                remotePerson,
              ),
            )
            .toList();

    final messagingStyle = MessagingStyleInformation(
      me,
      conversationTitle: isGroup ? conversationTitle : null,
      groupConversation: isGroup,
      messages: styleMessages,
    );

    final androidDetails = AndroidNotificationDetails(
      NotificationChannelSetup.messageChannel.id,
      NotificationChannelSetup.messageChannel.name,
      channelDescription: NotificationChannelSetup.messageChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      icon: '@drawable/ic_notification',
      largeIcon: ByteArrayAndroidBitmap(headerBitmap),
      styleInformation: messagingStyle,
      autoCancel: true,
      ongoing: false,
      color: const Color(0xFF2196F3),
      actions: [
        const AndroidNotificationAction(
          'mute_action',
          'Mute',
          showsUserInterface: false,
          cancelNotification: true,
        ),

        // if (!isGroup)
        const AndroidNotificationAction(
          'mark_read_action',
          'Mark as Read',
          showsUserInterface: false,
          cancelNotification: true,
        ),

        AndroidNotificationAction(
          'reply_action',
          'Reply',
          inputs: const [
            AndroidNotificationActionInput(label: 'Type a message...'),
          ],
          showsUserInterface: false,
          cancelNotification: false,
          allowGeneratedReplies: false,
        ),
      ],
    );

    final String? latestMessageId = data['messageId'] as String?;
    final String? groupImageUrl = data['groupImageUrl'] as String?;

    await _localNotifications.show(
      createNotificationId(conversationId),
      conversationTitle,
      body,
      NotificationDetails(android: androidDetails),

      payload:
          isGroup
              ? 'group|$conversationId|$conversationTitle|${latestMessageId ?? ''}|${groupImageUrl ?? ''}'
              : '$conversationId|$senderName|${avatarUrl ?? ''}|${latestMessageId ?? ''}',
    );
  }

  Future<void> cancelNotificationsForSender(String senderId) async {
    await _localNotifications.cancel(createNotificationId(senderId));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notif_style_history_$senderId');
    unawaited(
      LocalSnapshotStore.instance.clear('notif_style_history_$senderId'),
    );
  }

  Future<void> cancelNotificationSilently(String conversationId) async {
    await _localNotifications.cancel(createNotificationId(conversationId));
  }

  Future<void> stripActionsInstantly(
    String conversationId,
    String title,
  ) async {
    try {
      await _localNotifications.show(
        createNotificationId(conversationId),
        title,
        'Updating...',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_messages_channel',
            'Chat Messages',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            onlyAlertOnce: true,
            actions: [],
          ),
        ),
      );
    } catch (e) {
      debugPrint('[BackgroundChatAction] strip actions failed: $e');
    }
  }

  Future<void> handleMarkAsReadAction({
    required bool isGroup,
    required String conversationId,
    required String currentUserId,
  }) async {
    try {
      if (isGroup) {
        await GroupChatServices().markGroupMessagesRead(conversationId);
      } else {
        await Supabase.instance.client
            .from('messages')
            .update({'is_read': true})
            .eq('sender_id', conversationId)
            .eq('receiver_id', currentUserId)
            .eq('is_read', false);
      }
      debugPrint(
        '[BackgroundChatAction] mark_read_action → DB write OK (isGroup=$isGroup)',
      );
    } catch (e) {
      debugPrint(
        '[BackgroundChatAction] mark_read_action → DB write FAILED: $e',
      );
    } finally {
      await cancelNotificationsForSender(conversationId);
    }
  }

  Future<void> handleMuteAction({
    required bool isGroup,
    required String conversationId,
    required String currentUserId,
  }) async {
    try {
      if (isGroup) {
        await Supabase.instance.client
            .from('group_members')
            .update({'is_muted': true})
            .eq('group_id', conversationId)
            .eq('user_id', currentUserId);
      } else {
        await Supabase.instance.client.from('chat_mutes').upsert({
          'owner_id': currentUserId,
          'peer_id': conversationId,
          'is_muted': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
      debugPrint(
        '[BackgroundChatAction] mute_action → DB write OK (isGroup=$isGroup)',
      );
    } catch (e) {
      debugPrint('[BackgroundChatAction] mute_action → DB write FAILED: $e');
    } finally {
      await cancelNotificationsForSender(conversationId);
    }
  }

  Future<void> handleReplyAction({
    required NotificationResponse response,
    required List<String> parts,
    required bool isGroup,
    required String conversationId,
    required String conversationTitle,
    required String latestMessageId,
    required String currentUserId,
  }) async {
    final replyText = response.input?.trim();
    if (replyText == null || replyText.isEmpty) {
      await cancelNotificationSilently(conversationId);
      return;
    }

    final avatarUrl =
        isGroup
            ? (parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null)
            : (parts.length > 2 ? parts[2] : null);

    try {
      final String newMessageId;

      final userFuture =
          Supabase.instance.client
              .from('users')
              .select('image_url')
              .eq('id', currentUserId)
              .maybeSingle();
      if (isGroup) {
        final result = await GroupChatServices().sendGroupMessage(
          groupId: conversationId,
          groupName: conversationTitle,
          text: replyText,
          clientMessageId: const Uuid().v4(),
        );
        newMessageId = result.message.id;
      } else {
        newMessageId =
            (await ChatServices().sendMessage(
              senderId: currentUserId,
              receiverId: conversationId,
              text: replyText,
              clientMessageId: const Uuid().v4(),
              replyToMessageId:
                  latestMessageId.isEmpty ? null : latestMessageId,
            )).id;
      }

      final userData = await userFuture;
      final myAvatarUrl = userData?['image_url'] as String?;

      await updateNotificationAfterReply(
        conversationId: conversationId,
        isGroup: isGroup,
        conversationTitle: conversationTitle,
        replyText: replyText,
        avatarUrl: avatarUrl,
        newMessageId: newMessageId,
        myAvatarUrl: myAvatarUrl,
      );
    } catch (e, st) {
      debugPrint('[BackgroundChatAction] reply_action → send FAILED: $e\n$st');
      await cancelNotificationSilently(conversationId);
    }
  }

  Future<void> updateNotificationAfterReply({
    required String conversationId,
    required bool isGroup,
    required String conversationTitle,
    required String replyText,
    required String? avatarUrl,
    required String newMessageId,
    String? myAvatarUrl,
  }) async {
    final stored = await _appendToMessageHistory(
      conversationId,
      _StoredMessage(
        text: replyText,
        senderName: 'You',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    final Uint8List senderBitmap = await _avatarBuilder.getAvatarBitmap(
      avatarUrl,
    );

    final Uint8List headerBitmap =
        isGroup
            ? ((avatarUrl != null && avatarUrl.isNotEmpty)
                ? (await _avatarBuilder.fetchBitmap(avatarUrl) ??
                    await _avatarBuilder.buildLetterAvatar(conversationTitle))
                : await _avatarBuilder.buildLetterAvatar(conversationTitle))
            : senderBitmap;

    final Uint8List myBitmap = await _avatarBuilder.getAvatarBitmap(
      myAvatarUrl,
    );

    final Person me = Person(
      name: 'You',
      important: true,
      icon: ByteArrayAndroidIcon(myBitmap),
    );

    final Person remotePerson = Person(
      name: conversationTitle,
      icon: ByteArrayAndroidIcon(headerBitmap),
    );

    final List<Message> styleMessages =
        stored.map((m) {
          final isMine = m.senderName == 'You';
          final text =
              (isGroup && !isMine) ? '${m.senderName}: ${m.text}' : m.text;
          return Message(
            text,
            DateTime.fromMillisecondsSinceEpoch(m.timestamp),
            isMine ? null : remotePerson,
          );
        }).toList();

    final messagingStyle = MessagingStyleInformation(
      me,
      conversationTitle: isGroup ? conversationTitle : null,
      groupConversation: isGroup,
      messages: styleMessages,
    );

    final androidDetails = AndroidNotificationDetails(
      NotificationChannelSetup.messageChannel.id,
      NotificationChannelSetup.messageChannel.name,
      channelDescription: NotificationChannelSetup.messageChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      icon: '@drawable/ic_notification',
      largeIcon: ByteArrayAndroidBitmap(headerBitmap),
      styleInformation: messagingStyle,
      autoCancel: true,
      ongoing: false,
      color: const Color(0xFF2196F3),
    );

    await _localNotifications.show(
      createNotificationId(conversationId),
      conversationTitle,
      replyText,
      NotificationDetails(android: androidDetails),
      payload:
          isGroup
              ? 'group|$conversationId|$conversationTitle|$newMessageId|${avatarUrl ?? ''}'
              : '$conversationId|$conversationTitle|${avatarUrl ?? ''}|$newMessageId',
    );
  }

  Future<List<_StoredMessage>> _appendToMessageHistory(
    String conversationId,
    _StoredMessage message,
  ) async {
    final key = 'notif_style_history_$conversationId';

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final rawString = prefs.getString(key);
    List<dynamic> raw = [];
    if (rawString != null) {
      try {
        raw = jsonDecode(rawString) as List<dynamic>;
      } catch (e) {
        debugPrint(
          '[NotificationServices] failed to decode cached list, using empty fallback: $e',
        );
      }
    }

    final history =
        raw
            .map(
              (m) => _StoredMessage(
                text: m['text'] as String? ?? '',
                senderName: m['senderName'] as String? ?? '',
                timestamp:
                    (m['timestamp'] as num?)?.toInt() ??
                    DateTime.now().millisecondsSinceEpoch,
              ),
            )
            .toList();

    history.add(message);

    if (history.length > 7) history.removeAt(0);

    await prefs.setString(
      key,
      jsonEncode(
        history
            .map(
              (m) => {
                'text': m.text,
                'senderName': m.senderName,
                'timestamp': m.timestamp,
              },
            )
            .toList(),
      ),
    );

    return history;
  }

  Future<void> _hydrateMessageCache(
    Map<String, dynamic> data,
    bool isGroup,
  ) async {
    try {
      final String type = data['notificationType'] ?? 'chat';
      if (type != 'chat' && type != 'group_message') return;

      final String? messageId = data['messageId'] as String?;
      if (messageId == null || messageId.isEmpty) return;

      final String? clientMessageId = _s(data['clientMessageId']);
      if (clientMessageId == null) return;

      final String messageType = data['messageType'] ?? 'text';
      final String? attachmentUrl = _s(data['attachmentUrl']);
      final String createdAt = DateTime.now().toIso8601String();

      final String key;
      final Map<String, dynamic> shadowMessage;

      if (isGroup) {
        final String groupId = data['groupId'] ?? '';
        if (groupId.isEmpty) return;
        key = 'group_messages_snapshot_$groupId';

        shadowMessage = {
          'id': messageId,
          GroupMessageColumns.clientMessageId: clientMessageId,
          GroupMemberColumns.groupId: groupId,
          'sender_id': data['senderId'] ?? '',
          'sender_name': data['senderName'] ?? 'Unknown',
          'sender_avatar': _s(data['senderImageUrl']),
          'message_text': data['messageBody'] ?? '',
          'created_at': createdAt,
          'message_type': messageType,
          'image_url': messageType == 'image' ? attachmentUrl : null,
          'video_url': messageType == 'video' ? attachmentUrl : null,
          'voice_url': messageType == 'voice' ? attachmentUrl : null,
          MessagesColumns.durationSeconds: int.tryParse(
            data['durationSeconds'] ?? '',
          ),
          'file_url': messageType == 'file' ? attachmentUrl : null,
          MessagesColumns.fileName: _s(data['fileName']),
          MessagesColumns.fileSizeBytes: int.tryParse(
            data['fileSizeBytes'] ?? '',
          ),
          MessagesColumns.caption: _s(data['caption']),
          'reply_to_message_id': _s(data['replyToMessageId']),
          'reply_to_text': _s(data['replyToText']),
          'reply_to_sender_id': _s(data['replyToSenderId']),
          'reply_to_sender_name': null,
          'reply_to_message_type': _s(data['replyToMessageType']),
          'reply_to_media_url': _s(data['replyToMediaUrl']),
          'forwarded_from_user_id': _s(data['forwardedFromUserId']),
          'forwarded_from_user_name': _s(data['forwardedFromUserName']),
          'forwarded_from_user_avatar': _s(data['forwardedFromUserAvatar']),
          'mentions': const [],
          'reactions': const {},
          'reactionsCreatedAt': const {},
          'read_by': const [],
          'is_edited': false,
          'deleted_for': const [],
          'system_event_data': null,
          'target_id': null,
          'target_name': null,
        };
      } else {
        final String? senderId = data['senderId'] as String?;
        final String? currentUserId =
            Supabase.instance.client.auth.currentUser?.id;
        if (senderId == null || senderId.isEmpty || currentUserId == null) {
          return;
        }
        final conversationId = ChatHelper.buildConversationId(
          currentUserId,
          senderId,
        );
        key = 'chat_messages_snapshot_$conversationId';

        shadowMessage = {
          MessagesColumns.id: messageId,
          MessagesColumns.clientMessageId: clientMessageId,
          MessagesColumns.senderId: senderId,
          MessagesColumns.receiverId: currentUserId,
          MessagesColumns.messageText: data['messageBody'] ?? '',
          MessagesColumns.createdAt: createdAt,
          MessagesColumns.isRead: false,
          MessagesColumns.isEdited: false,
          MessagesColumns.messageType: messageType,
          MessagesColumns.imageUrl:
              messageType == 'image' ? attachmentUrl : null,
          MessagesColumns.videoUrl:
              messageType == 'video' ? attachmentUrl : null,
          MessagesColumns.voiceUrl:
              messageType == 'voice' ? attachmentUrl : null,
          MessagesColumns.durationSeconds: int.tryParse(
            data['durationSeconds'] ?? '',
          ),
          MessagesColumns.fileName: _s(data['fileName']),
          MessagesColumns.fileSizeBytes: int.tryParse(
            data['fileSizeBytes'] ?? '',
          ),
          MessagesColumns.caption: _s(data['caption']),
          MessagesColumns.replyToMessageId: _s(data['replyToMessageId']),
          MessagesColumns.replyToText: _s(data['replyToText']),
          MessagesColumns.replyToMessageType: _s(data['replyToMessageType']),
          MessagesColumns.replyToSenderId: _s(data['replyToSenderId']),
          MessagesColumns.replyToMediaUrl: _s(data['replyToMediaUrl']),
          MessagesColumns.replyToStoryId: _s(data['replyToStoryId']),
          MessagesColumns.replyToStoryAuthorId: _s(
            data['replyToStoryAuthorId'],
          ),
          MessagesColumns.replyToStoryType: _s(data['replyToStoryType']),
          MessagesColumns.replyToStoryMediaUrl: _s(
            data['replyToStoryMediaUrl'],
          ),
          MessagesColumns.replyToStoryText: _s(data['replyToStoryText']),
          MessagesColumns.replyToStoryBgColor: _s(data['replyToStoryBgColor']),
          MessagesColumns.replyToStoryDurationSeconds: int.tryParse(
            data['replyToStoryDurationSeconds'] ?? '',
          ),
          MessagesColumns.forwardedFromUserId: _s(data['forwardedFromUserId']),
          MessagesColumns.forwardedFromUserName: _s(
            data['forwardedFromUserName'],
          ),
          MessagesColumns.forwardedFromUserAvatar: _s(
            data['forwardedFromUserAvatar'],
          ),
          'reactionsCreatedAt': const {},
          MessagesColumns.deletedFor: const <String>[],
        };
      }

      final existing = LocalSnapshotStore.instance.readList(key);
      if (existing.any((m) => m['id'] == messageId)) return;

      await LocalSnapshotStore.instance.saveList(key, [
        shadowMessage,
        ...existing,
      ]);
    } catch (e) {
      debugPrint('⚠️ _hydrateMessageCache silent error: $e');
    }
  }

  static String? _s(dynamic v) => (v == null || v == '') ? null : v as String;

  String _buildStyleBody(String type, String body, {String? fileName}) {
    switch (type) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'voice':
        return '🎤 Voice message';
      case 'gif':
        return '🖼️ GIF';
      case 'sticker':
        return '🏷️ Sticker';
      case 'file':
      case 'document':
        if (fileName != null && fileName.trim().isNotEmpty) {
          return '📄 ${fileName.trim()}';
        }
        return '📄 File';
      default:
        return body;
    }
  }
}
