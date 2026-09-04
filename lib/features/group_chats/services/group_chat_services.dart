import 'dart:io';

import 'package:social_media_app/core/mentions/mentions.dart';

import '../../../core/presence/models/chat_action_type.dart';
import '../../../core/services/cloudinary_storage_services.dart';
import '../../../core/services/cloudinary_upload_result.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../models/group_add_members_result.dart';
import '../models/group_header_stats.dart';
import '../models/group_invite_preview.dart';
import '../models/group_invite_state.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../models/group_presence_entry.dart';
import '../models/groupe_message_model.dart';
import 'group_invite_service.dart';
import 'group_membership_service.dart';
import 'group_messaging_service.dart';
import 'group_presence_service.dart';

/// Public facade over the group-chat domain, kept for backward
/// compatibility with every existing call site
/// - [GroupMembershipService] — group CRUD, roster, audit trail
/// - [GroupInviteService]     — invite links
/// - [GroupMessagingService]  — message content
/// - [GroupPresenceService]   — typing/recording presence

class GroupChatServices {
  GroupChatServices({
    GroupMembershipService? membershipService,
    GroupInviteService? inviteService,
    GroupMessagingService? messagingService,
    GroupPresenceService? presenceService,
  }) : _membership = membershipService ?? GroupMembershipService(),
       _messaging = messagingService ?? GroupMessagingService(),
       _presence = presenceService ?? GroupPresenceService() {
    _invite =
        inviteService ?? GroupInviteService(membershipService: _membership);
  }

  final GroupMembershipService _membership;
  late final GroupInviteService _invite;
  final GroupMessagingService _messaging;
  final GroupPresenceService _presence;

  String get currentUserId => SupabaseProvider.id;

  CloudinaryStorageServices get storage => CloudinaryStorageServices.instance;

  // ── Group CRUD & roster (GroupMembershipService) ──────────────────

  Future<GroupModel> createGroup({
    required String name,
    String? avatarUrl,
    String? avatarPublicId,
    required List<String> memberIds,
  }) => _membership.createGroup(
    name: name,
    avatarUrl: avatarUrl,
    avatarPublicId: avatarPublicId,
    memberIds: memberIds,
  );

  Future<List<GroupModel>> getMyGroups() => _membership.getMyGroups();

  Future<List<GroupModel>> searchMyGroups({
    required String query,
    int limit = 20,
    int offset = 0,
  }) => _membership.searchMyGroups(query: query, limit: limit, offset: offset);

  Future<({List<GroupMemberModel> members, int totalCount})>
  getGroupMembersPaginated(String groupId, {int page = 0, int pageSize = 20}) =>
      _membership.getGroupMembersPaginated(
        groupId,
        page: page,
        pageSize: pageSize,
      );

  Future<List<String>> getGroupMemberIds(String groupId) =>
      _membership.getGroupMemberIds(groupId);

  Future<bool> checkIsActiveMember({
    required String groupId,
    required String userId,
  }) => _membership.checkIsActiveMember(groupId: groupId, userId: userId);

  Future<Map<String, List<GroupMemberModel>>> getMembersForGroups(
    List<String> groupIds,
  ) => _membership.getMembersForGroups(groupIds);

  Future<void> promoteToAdmin(String groupId, String targetUserId) =>
      _membership.promoteToAdmin(groupId, targetUserId);

  Future<void> demoteAdmin(String groupId, String targetUserId) =>
      _membership.demoteAdmin(groupId, targetUserId);

  Future<void> addMember(String groupId, String userId) =>
      _membership.addMember(groupId, userId);

  Future<GroupAddMembersResult> addMembers(
    String groupId,
    List<String> userIds,
  ) => _membership.addMembers(groupId, userIds);

  Future<void> removeMember(
    String groupId,
    String userId, {
    required String actorId,
  }) => _membership.removeMember(groupId, userId, actorId: actorId);

  Future<void> leaveGroup(String groupId) => _membership.leaveGroup(groupId);

  Future<void> blockGroup(String groupId, {required bool wasMember}) =>
      _membership.blockGroup(groupId, wasMember: wasMember);

  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? avatarUrl,
  }) => _membership.updateGroup(
    groupId: groupId,
    name: name,
    avatarUrl: avatarUrl,
  );

  Future<void> deleteGroupPermanently(String groupId) =>
      _membership.deleteGroupPermanently(groupId);

  Future<CloudinaryUploadResult> uploadGroupAvatar(
    File file, {
    void Function(double progress)? onProgress,
  }) => _membership.uploadGroupAvatar(file, onProgress: onProgress);

  Future<void> updateGroupAvatarUrl(
    String groupId,
    String newAvatarUrl,
    String? avatarPublicId,
  ) => _membership.updateGroupAvatarUrl(groupId, newAvatarUrl, avatarPublicId);

  Future<void> updateGroupTitle(String groupId, String? title) =>
      _membership.updateGroupTitle(groupId, title);

  Future<void> removeGroupAvatar(String groupId) =>
      _membership.removeGroupAvatar(groupId);

  Future<bool> getMyMuteStatus(String groupId) =>
      _membership.getMyMuteStatus(groupId);

  Future<void> toggleMute(String groupId, bool muted) =>
      _membership.toggleMute(groupId, muted);

  Stream<void> getGroupsListStream() => _membership.getGroupsListStream();

  Stream<GroupHeaderStats> watchGroupHeaderStats(String groupId) =>
      _membership.watchGroupHeaderStats(groupId);

  Future<Map<String, String?>> getUserInfo(String userId) =>
      _membership.getUserInfo(userId);

  // ── Invite links (GroupInviteService) ──────────────────────────────

  bool hasCachedInviteState(String groupId) =>
      _invite.hasCachedInviteState(groupId);

  GroupInviteState? getCachedInviteState(String groupId) =>
      _invite.getCachedInviteState(groupId);

  Future<GroupInviteState?> getGroupInviteState(String groupId) =>
      _invite.getGroupInviteState(groupId);

  Future<GroupInviteState> generateGroupInviteLink(
    String groupId, {
    Duration? expiresIn,
  }) => _invite.generateGroupInviteLink(groupId, expiresIn: expiresIn);

  Future<void> revokeGroupInviteLink(String groupId) =>
      _invite.revokeGroupInviteLink(groupId);

  Future<GroupInvitePreview> getGroupInvitePreview(String inviteHash) =>
      _invite.getGroupInvitePreview(inviteHash);

  Future<GroupModel> joinGroupViaInvite(String inviteHash) =>
      _invite.joinGroupViaInvite(inviteHash);

  // ── Message content (GroupMessagingService) ────────────────────────

  Stream<List<GroupMessageModel>> getGroupMessagesStream(String groupId) =>
      _messaging.getGroupMessagesStream(groupId);

  Future<({GroupMessageModel message, bool isNewInsert})> sendGroupMessage({
    required String groupId,
    required String groupName,
    String? groupImageUrl,
    required String text,
    required String clientMessageId,
    String messageType = 'text',
    String? imageUrl,
    String? videoUrl,
    String? voiceUrl,
    int? durationSeconds,
    String? fileUrl,
    String? fileName,
    int? fileSizeBytes,
    String? caption,
    GroupMessageModel? replyTo,
    String? imagePublicId,
    String? videoPublicId,
    String? voicePublicId,
    String? filePublicId,
    String? forwardedFromUserId,
    String? forwardedFromUserName,
    String? forwardedFromUserAvatar,
    List<MentionRef> mentions = const [],
  }) => _messaging.sendGroupMessage(
    groupId: groupId,
    groupName: groupName,
    groupImageUrl: groupImageUrl,
    text: text,
    clientMessageId: clientMessageId,
    messageType: messageType,
    imageUrl: imageUrl,
    videoUrl: videoUrl,
    voiceUrl: voiceUrl,
    durationSeconds: durationSeconds,
    fileUrl: fileUrl,
    fileName: fileName,
    fileSizeBytes: fileSizeBytes,
    caption: caption,
    replyTo: replyTo,
    imagePublicId: imagePublicId,
    videoPublicId: videoPublicId,
    voicePublicId: voicePublicId,
    filePublicId: filePublicId,
    forwardedFromUserId: forwardedFromUserId,
    forwardedFromUserName: forwardedFromUserName,
    forwardedFromUserAvatar: forwardedFromUserAvatar,
    mentions: mentions,
  );

  Future<void> editGroupMessage({
    required String messageId,
    required String newText,
    required bool isCaptionEdit,
    required String groupId,
    List<MentionRef> mentions = const [],
  }) => _messaging.editGroupMessage(
    messageId: messageId,
    newText: newText,
    isCaptionEdit: isCaptionEdit,
    groupId: groupId,
    mentions: mentions,
  );

  Future<void> deleteGroupMessage(String messageId) =>
      _messaging.deleteGroupMessage(messageId);

  Future<void> deleteGroupMessageForMe({
    required String messageId,
    required String currentUserId,
  }) => _messaging.deleteGroupMessageForMe(
    messageId: messageId,
    currentUserId: currentUserId,
  );

  Future<void> deleteGroupMessagesForMe({
    required List<GroupMessageModel> messages,
    required String currentUserId,
  }) => _messaging.deleteGroupMessagesForMe(
    messages: messages,
    currentUserId: currentUserId,
  );

  Future<void> deleteGroupMessagesForEveryone(List<String> messageIds) =>
      _messaging.deleteGroupMessagesForEveryone(messageIds);

  Future<void> toggleReaction({
    required String messageId,
    required String emoji,
    required String groupId,
    String? currentEmoji,
  }) => _messaging.toggleReaction(
    messageId: messageId,
    emoji: emoji,
    groupId: groupId,
    currentEmoji: currentEmoji,
  );

  Stream<List<Map<String, dynamic>>> getReactionsStream(String groupId) =>
      _messaging.getReactionsStream(groupId);

  Stream<List<Map<String, dynamic>>> getMentionsStream(String groupId) =>
      _messaging.getMentionsStream(groupId);

  Future<void> markGroupMessagesRead(String groupId) =>
      _messaging.markGroupMessagesRead(groupId);

  Stream<List<Map<String, dynamic>>> getReadReceiptsStream(String groupId) =>
      _messaging.getReadReceiptsStream(groupId);

  Future<List<GroupMessageModel>> getGroupMediaPreview({
    required String groupId,
    int limit = 6,
  }) => _messaging.getGroupMediaPreview(groupId: groupId, limit: limit);

  Future<List<GroupMessageModel>> getGroupMediaMessages({
    required String groupId,
    required String messageType,
    int limit = 100,
  }) => _messaging.getGroupMediaMessages(
    groupId: groupId,
    messageType: messageType,
    limit: limit,
  );

  Future<List<GroupMessageModel>> getGroupLinkMessages({
    required String groupId,
    int limit = 100,
  }) => _messaging.getGroupLinkMessages(groupId: groupId, limit: limit);

  // ── Presence (GroupPresenceService) ────────────────────────────────

  Stream<Map<String, GroupPresenceSnapshot>> watchAllGroupsPresence() =>
      _presence.watchAllGroupsPresence();

  Future<void> setGroupAction(
    String groupId,
    ChatActionType actionType, {
    required bool isMember,
  }) => _presence.setGroupAction(groupId, actionType, isMember: isMember);

  Stream<GroupPresenceSnapshot> watchGroupPresence(String groupId) =>
      _presence.watchGroupPresence(groupId);
}
