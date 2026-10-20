import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_media_app/core/attachment/widgets/file_message_bubble.dart';
import 'package:social_media_app/core/chat_shared/widgets/highlighted_linkify_text.dart';
import 'package:social_media_app/core/design/tokens/typography.dart';
import 'package:social_media_app/core/helpers/formatted_date.dart';
import 'package:social_media_app/core/localization/app_l10n.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:social_media_app/core/widgets/app_avatar.dart';
import 'package:social_media_app/features/ai_chat/models/ai_chat_message.dart';
import 'package:social_media_app/features/chat_forwarding/widgets/forwarded_header.dart';
import 'package:social_media_app/features/gifs/widgets/gif_message_bubble.dart';
import 'package:social_media_app/features/group_chats/models/group_member_model.dart';
import 'package:social_media_app/features/group_chats/models/group_model.dart';
import 'package:social_media_app/features/group_chats/models/groupe_message_model.dart';
import 'package:social_media_app/features/reactions/models/reaction_entry.dart';
import 'package:social_media_app/features/reactions/services/reaction_profile_resolver.dart';
import 'package:social_media_app/features/reports/models/report_target.dart';
import 'package:social_media_app/features/reports/widgets/report_bottom_sheet.dart';
import 'package:social_media_app/features/single_chats/helpers/chat_bubble_colors.dart';
import 'package:social_media_app/features/single_chats/models/chat_user_model.dart';
import 'package:social_media_app/features/single_chats/models/message_model.dart';
import 'package:social_media_app/features/single_chats/widgets/image_message_widget.dart';
import 'package:social_media_app/features/single_chats/widgets/video_message_widget.dart';
import 'package:social_media_app/features/single_chats/widgets/voice_message_bubble_widget.dart';
import 'package:social_media_app/features/stickers/widgets/sticker_message_bubble.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../helpers/link_color_helper.dart';
import '../../link/widgets/message_link_preview.dart';
import '../../mentions/models/mention_ref.dart';
import '../../mentions/widgets/mention_rich_text.dart';
import '../../router/app_routes.dart';
import '../../toast/app_toast.dart';
import '../../widgets/read_more_text.dart';

enum MessageInfoChatType { single, group, ai }

class MessageInfoArgs {
  final MessageInfoChatType chatType;
  final String messageId;
  final String text;
  final String messageType;
  final DateTime createdAt;
  final bool isMe;
  final String senderId;
  final String senderName;
  final String? senderAvatar;

  // Media fields
  final String? imageUrl;
  final String? videoUrl;
  final String? voiceUrl;
  final int? durationSeconds;
  final String? fileUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final String? caption;

  // Forwarded
  final String? forwardedFromUserId;
  final String? forwardedFromUserName;
  final String? forwardedFromUserAvatar;

  // Single Chat specific
  final bool isRead;
  final String? receiverName;
  final String? receiverAvatar;

  // Group Chat specific
  final String? groupId;
  final String? groupName;
  final Set<String> readBy;
  final List<GroupMemberModel> members;

  // AI Chat specific
  final String? aiModelLabel;

  // Mentions
  final List<MentionRef> mentions;

  // Initial reactions snapshot (if already available from message model)
  final Map<String, String> initialReactions;

  const MessageInfoArgs({
    required this.chatType,
    required this.messageId,
    required this.text,
    required this.messageType,
    required this.createdAt,
    required this.isMe,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.imageUrl,
    this.videoUrl,
    this.voiceUrl,
    this.durationSeconds,
    this.fileUrl,
    this.fileName,
    this.fileSizeBytes,
    this.caption,
    this.forwardedFromUserId,
    this.forwardedFromUserName,
    this.forwardedFromUserAvatar,
    this.isRead = false,
    this.receiverName,
    this.receiverAvatar,
    this.groupId,
    this.groupName,
    this.readBy = const {},
    this.members = const [],
    this.aiModelLabel,
    this.mentions = const [],
    this.initialReactions = const {},
  });

  bool get isForwarded => (forwardedFromUserId ?? '').isNotEmpty;

  factory MessageInfoArgs.fromSingleChat({
    required MessageModel message,
    required ChatUserModel receiverUser,
    required String currentUserId,
    String? currentUserName,
    String? currentUserAvatar,
  }) {
    final isMe = message.senderId == currentUserId;
    return MessageInfoArgs(
      chatType: MessageInfoChatType.single,
      messageId: message.id,
      text: message.text,
      messageType: message.messageType,
      createdAt: message.createdAt,
      isMe: isMe,
      senderId: message.senderId,
      senderName: isMe ? AppL10n.current.you : receiverUser.name,
      senderAvatar: isMe ? currentUserAvatar : receiverUser.imageUrl,
      imageUrl: message.imageUrl,
      videoUrl: message.videoUrl,
      voiceUrl: message.voiceUrl,
      durationSeconds: message.durationSeconds,
      fileUrl: message.fileUrl,
      fileName: message.fileName,
      fileSizeBytes: message.fileSizeBytes,
      caption: message.caption,
      forwardedFromUserId: message.forwardedFromUserId,
      forwardedFromUserName: message.forwardedFromUserName,
      forwardedFromUserAvatar: message.forwardedFromUserAvatar,
      isRead: message.isRead,
      receiverName: receiverUser.name,
      receiverAvatar: receiverUser.imageUrl,
      mentions: const [],
      initialReactions: message.reactions,
    );
  }

  factory MessageInfoArgs.fromGroupChat({
    required GroupMessageModel message,
    required GroupModel group,
    required String currentUserId,
    String? currentUserName,
    String? currentUserAvatar,
  }) {
    final isMe = message.senderId == currentUserId;
    String? resolvedAvatar = message.senderAvatar;
    if (resolvedAvatar == null || resolvedAvatar.isEmpty) {
      if (isMe) {
        resolvedAvatar =
            currentUserAvatar ??
            group.members
                .where((m) => m.userId == currentUserId)
                .map((m) => m.userAvatar)
                .firstOrNull;
      } else {
        resolvedAvatar =
            group.members
                .where((m) => m.userId == message.senderId)
                .map((m) => m.userAvatar)
                .firstOrNull;
      }
    }

    return MessageInfoArgs(
      chatType: MessageInfoChatType.group,
      messageId: message.id,
      text: message.text,
      messageType: message.messageType,
      createdAt: message.createdAt,
      isMe: isMe,
      senderId: message.senderId,
      senderName: isMe ? AppL10n.current.you : message.senderName,
      senderAvatar: resolvedAvatar,
      imageUrl: message.imageUrl,
      videoUrl: message.videoUrl,
      voiceUrl: message.voiceUrl,
      durationSeconds: message.durationSeconds,
      fileUrl: message.fileUrl,
      fileName: message.fileName,
      fileSizeBytes: message.fileSizeBytes,
      caption: message.caption,
      forwardedFromUserId: message.forwardedFromUserId,
      forwardedFromUserName: message.forwardedFromUserName,
      forwardedFromUserAvatar: message.forwardedFromUserAvatar,
      groupId: group.id,
      groupName: group.name,
      readBy: message.readBy,
      members: group.members,
      mentions: message.mentions,
      initialReactions: message.reactions,
    );
  }

  factory MessageInfoArgs.fromAiChat({
    required AiChatMessage message,
    required String currentUserId,
    String? currentUserName,
    String? currentUserAvatar,
  }) {
    final isMe = message.isMe;
    final modelLabel =
        message.model?.fullLabel ??
        message.model?.label ??
        'Gemini 3.5 Flash Lite';
    return MessageInfoArgs(
      chatType: MessageInfoChatType.ai,
      messageId: message.id,
      text: message.text,
      messageType:
          message.mediaType.name == 'none' ? 'text' : message.mediaType.name,
      createdAt: message.createdAt,
      isMe: isMe,
      senderId: isMe ? currentUserId : 'ai_assistant',
      senderName: isMe ? AppL10n.current.you : 'Syncra AI',
      senderAvatar: isMe ? currentUserAvatar : null,
      imageUrl: message.mediaType.name == 'image' ? message.mediaUrl : null,
      videoUrl: message.mediaType.name == 'video' ? message.mediaUrl : null,
      voiceUrl: message.mediaType.name == 'voice' ? message.mediaUrl : null,
      durationSeconds: message.durationSeconds,
      fileUrl: message.mediaType.name == 'file' ? message.mediaUrl : null,
      fileName: message.fileName,
      fileSizeBytes: message.fileSizeBytes,
      aiModelLabel: modelLabel,
      mentions: const [],
    );
  }
}

class _ReactionRow {
  final String userId;
  final String emoji;
  final DateTime? createdAt;
  const _ReactionRow(this.userId, this.emoji, this.createdAt);
}

class _ReaderRow {
  final String userId;
  final DateTime? readAt;
  const _ReaderRow(this.userId, this.readAt);
}

class _Identity {
  final String name;
  final String? avatar;
  const _Identity(this.name, this.avatar);
}

class MessageInfoView extends StatefulWidget {
  final MessageInfoArgs args;

  const MessageInfoView({super.key, required this.args});

  @override
  State<MessageInfoView> createState() => _MessageInfoViewState();
}

class _MessageInfoViewState extends State<MessageInfoView> {
  static const Duration _refreshEvery = Duration(seconds: 8);

  MessageInfoArgs get args => widget.args;

  final ReactionProfileResolver _resolver = GroupChatReactionProfileResolver();

  Timer? _timer;
  bool _fetching = false;
  bool _initialLoading = true;

  List<_ReactionRow> _reactions = const [];
  List<_ReaderRow> _readers = const [];
  Map<String, ReactionEntry> _profiles = const {};

  late bool _isRead;
  DateTime? _deliveredAt;
  DateTime? _readAt;
  String? _senderAvatar;

  String get _currentUserId => SupabaseProvider.idOrNull ?? '';

  @override
  void initState() {
    super.initState();
    _isRead = args.isRead;
    _senderAvatar = args.senderAvatar;
    _fetchLiveStatus();
    if (args.chatType != MessageInfoChatType.ai) {
      _timer = Timer.periodic(_refreshEvery, (_) => _fetchLiveStatus());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------
  static DateTime? _ts(dynamic v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  Future<void> _fetchLiveStatus() async {
    if (_fetching) return;
    _fetching = true;
    try {
      if (args.chatType == MessageInfoChatType.single) {
        await _loadSingle();
      } else if (args.chatType == MessageInfoChatType.group) {
        await _loadGroup();
      }
      await _resolveProfiles();
    } catch (e) {
      debugPrint('[MessageInfoView] fetchLiveStatus error: $e');
    } finally {
      _fetching = false;
      if (mounted && _initialLoading) {
        setState(() => _initialLoading = false);
      }
    }
  }

  List<_ReactionRow> _parseReactions(dynamic rows, String reactionCol) {
    final out = <_ReactionRow>[];
    for (final r in (rows as List)) {
      final m = Map<String, dynamic>.from(r as Map);
      final uid = m['user_id'] as String?;
      final emoji = m[reactionCol] as String?;
      if (uid == null || emoji == null || emoji.isEmpty) continue;
      out.add(_ReactionRow(uid, emoji, _ts(m['created_at'])));
    }
    return out;
  }

  Future<void> _loadSingle() async {
    final client = SupabaseProvider.client;

    final reactionRows = await client
        .from(SupabaseConstants.messageReactions)
        .select(
          '${MessageReactionColumns.userId}, '
          '${MessageReactionColumns.reaction}, '
          '${MessageReactionColumns.createdAt}',
        )
        .eq(MessageReactionColumns.messageId, args.messageId);
    final reactions = _parseReactions(
      reactionRows,
      MessageReactionColumns.reaction,
    );

    var isRead = _isRead;
    DateTime? deliveredAt = _deliveredAt;
    DateTime? readAt = _readAt;

    if (args.isMe) {
      Map<String, dynamic>? row;
      try {
        row =
            await client
                .from(SupabaseConstants.messages)
                .select('is_read, delivered_at, read_at')
                .eq(MessagesColumns.id, args.messageId)
                .maybeSingle();
      } on PostgrestException catch (e) {
        if (e.code != '42703') rethrow;
        row =
            await client
                .from(SupabaseConstants.messages)
                .select('is_read')
                .eq(MessagesColumns.id, args.messageId)
                .maybeSingle();
      }
      if (row != null) {
        isRead = (row['is_read'] as bool?) ?? isRead;
        deliveredAt = _ts(row['delivered_at']) ?? deliveredAt;
        readAt = _ts(row['read_at']) ?? readAt;
      }
    }

    if (!mounted) return;
    setState(() {
      _reactions = reactions;
      _isRead = isRead;
      _deliveredAt = deliveredAt;
      _readAt = readAt;
    });
  }

  Future<void> _loadGroup() async {
    final client = SupabaseProvider.client;

    final reactionRows = await client
        .from(SupabaseConstants.groupMessageReactions)
        .select(
          '${GroupReactionColumns.userId}, ${GroupReactionColumns.reaction}',
        )
        .eq(GroupReactionColumns.messageId, args.messageId);
    final reactions = _parseReactions(
      reactionRows,
      GroupReactionColumns.reaction,
    );

    final readers = <String, DateTime?>{};
    if (args.isMe) {
      try {
        final rows = await client
            .from('group_message_reads')
            .select('user_id, read_at')
            .eq('message_id', args.messageId);
        for (final r in (rows as List)) {
          final m = Map<String, dynamic>.from(r as Map);
          final uid = m['user_id'] as String?;
          if (uid != null) readers[uid] = _ts(m['read_at']);
        }
      } on PostgrestException catch (e) {
        debugPrint('[MessageInfoView] group_message_reads unavailable: $e');
      }

      try {
        final row =
            await client
                .from(SupabaseConstants.groupMessages)
                .select('read_by')
                .eq(GroupMessageColumns.id, args.messageId)
                .maybeSingle();
        final raw = row?['read_by'];
        if (raw is List) {
          for (final id in raw) {
            readers.putIfAbsent(id.toString(), () => null);
          }
        }
      } on PostgrestException catch (e) {
        debugPrint('[MessageInfoView] read_by fetch failed: $e');
      }
      for (final id in args.readBy) {
        readers.putIfAbsent(id, () => null);
      }
      readers.remove(args.senderId);
    }

    final readerRows =
        readers.entries.map((e) => _ReaderRow(e.key, e.value)).toList()
          ..sort((a, b) {
            if (a.readAt == null && b.readAt == null) return 0;
            if (a.readAt == null) return 1;
            if (b.readAt == null) return -1;
            return a.readAt!.compareTo(b.readAt!);
          });

    if (!mounted) return;
    setState(() {
      _reactions = reactions;
      _readers = readerRows;
    });
  }

  Future<void> _resolveProfiles() async {
    final ids = <String>{
      ..._reactions.map((r) => r.userId),
      ..._readers.map((r) => r.userId),
      if (args.isMe &&
          (_senderAvatar ?? '').isEmpty &&
          args.senderId.isNotEmpty)
        args.senderId,
    }..removeWhere((id) => id.isEmpty || id == 'ai_assistant');
    if (ids.isEmpty) return;

    final resolved = await _resolver.resolve(ids.toList());
    if (!mounted) return;
    setState(() {
      _profiles = {..._profiles, ...resolved};
      if (args.isMe && (_senderAvatar ?? '').isEmpty) {
        final me = resolved[args.senderId];
        if (me?.userImageUrl?.isNotEmpty == true) {
          _senderAvatar = me!.userImageUrl;
        }
      }
    });
  }

  _Identity _identity(String userId) {
    final isMe = userId == _currentUserId;
    final profile = _profiles[userId];
    final member = args.members.where((m) => m.userId == userId).firstOrNull;

    final name =
        isMe
            ? AppL10n.current.you
            : (profile?.userName ??
                member?.userName ??
                (args.chatType == MessageInfoChatType.single
                    ? args.receiverName
                    : null) ??
                'Unknown User');
    final avatar =
        profile?.userImageUrl ??
        member?.userAvatar ??
        (args.chatType == MessageInfoChatType.single && !isMe
            ? args.receiverAvatar
            : null);
    return _Identity(name, avatar);
  }

  String _fmt(DateTime? d) =>
      d == null ? '—' : FormattedDate.getFormattedDate(d.toIso8601String());

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final showReactionsShimmer =
        _initialLoading &&
        (args.initialReactions.isNotEmpty || _reactions.isNotEmpty);
    final showGroupReadersShimmer =
        _initialLoading &&
        args.isMe &&
        args.chatType == MessageInfoChatType.group;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.l10n.messageInfo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLiveStatus,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _buildMessagePreviewCard(context, primary, isDark),
            const Gap(20),

            if (showReactionsShimmer) ...[
              _buildReactionsShimmer(
                context,
                primary,
                isDark,
                count:
                    args.initialReactions.isNotEmpty
                        ? args.initialReactions.length
                        : _reactions.length,
              ),
              const Gap(16),
            ] else if (_reactions.isNotEmpty) ...[
              _buildReactionsSection(context, primary, isDark),
              const Gap(16),
            ],

            if (args.isMe) ...[
              if (args.chatType == MessageInfoChatType.group)
                if (showGroupReadersShimmer)
                  _buildGroupReadReceiptsShimmer(
                    context,
                    primary,
                    isDark,
                    count: args.readBy.isNotEmpty ? args.readBy.length : 2,
                  )
                else
                  _buildGroupReadReceiptsSection(context, primary, isDark)
              else if (args.chatType == MessageInfoChatType.single)
                _buildSingleChatStatusSection(context, primary, isDark)
              else if (args.chatType == MessageInfoChatType.ai)
                _buildAiChatStatusSection(context, primary, isDark),
            ],

            if (!args.isMe && args.chatType != MessageInfoChatType.ai)
              _buildReportActionCard(context),

            if (!args.isMe && args.chatType == MessageInfoChatType.ai)
              _buildAiChatStatusSection(context, primary, isDark),

            const Gap(32),
          ],
        ),
      ),
    );
  }

  Color _cardBg(BuildContext context, bool isDark) =>
      isDark
          ? Theme.of(context).colorScheme.surfaceContainerHigh
          : Colors.white;

  BoxDecoration _cardDecoration(
    BuildContext context,
    Color primary,
    bool isDark,
  ) => BoxDecoration(
    color: _cardBg(context, isDark),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: primary.withValues(alpha: isDark ? 0.15 : 0.08)),
  );

  // ---------------------------------------------------------------------------
  // Message Preview Card
  // ---------------------------------------------------------------------------
  Widget _buildMessagePreviewCard(
    BuildContext context,
    Color primary,
    bool isDark,
  ) {
    return Container(
      decoration: _cardDecoration(context, primary, isDark).copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (args.chatType == MessageInfoChatType.ai && !args.isMe)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome, color: primary, size: 22),
                )
              else
                AppAvatar(imageUrl: _senderAvatar, size: 40),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      args.senderName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(2),
                    Text(
                      FormattedDate.getFormattedDate(
                        args.createdAt.toIso8601String(),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(14),
          const Divider(height: 1, thickness: 0.5),
          const Gap(14),
          Align(
            alignment: args.isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              crossAxisAlignment:
                  args.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBubbleContent(context, primary, isDark),
                if (_reactions.isNotEmpty) ...[
                  const Gap(4),
                  _buildReactionsChip(context, primary, isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsChip(BuildContext context, Color primary, bool isDark) {
    final counts = <String, int>{};
    for (final r in _reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }
    final top =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _cardBg(context, isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_reactions.length > 1) ...[
            Text(
              '${_reactions.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const Gap(4),
          ],
          for (final e in top.take(3))
            Text(
              e.key,
              style: TextStyle(
                inherit: false,
                fontSize: 13,
                fontFamilyFallback: AppTypography.emojiFontFallback,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBubbleContent(BuildContext context, Color primary, bool isDark) {
    final bubbleColor =
        args.isMe
            ? getSenderBubbleColor(context)
            : getReceiverBubbleColor(context);
    final textColor =
        args.isMe ? Colors.white : Theme.of(context).colorScheme.onSurface;

    final displayText = args.caption ?? args.text;

    Widget content;

    switch (args.messageType) {
      case 'image':
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (args.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 260,
                    maxWidth: 280,
                  ),
                  child: ImageMessageWidget(
                    imageUrl: args.imageUrl!,
                    caption: args.caption,
                    isMe: args.isMe,
                    fileSizeBytes: args.fileSizeBytes,
                  ),
                ),
              ),
            if (displayText.isNotEmpty && displayText != args.imageUrl) ...[
              const Gap(6),
              _buildFormattedTextContent(
                context,
                displayText,
                textColor,
                primary,
              ),
            ],
          ],
        );
        break;

      case 'video':
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (args.videoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 240,
                    maxWidth: 280,
                  ),
                  child: VideoMessageWidget(
                    videoUrl: args.videoUrl!,
                    caption: args.caption,
                    isMe: args.isMe,
                    fileSizeBytes: args.fileSizeBytes,
                    durationSeconds: args.durationSeconds,
                  ),
                ),
              ),
            if (displayText.isNotEmpty && displayText != args.videoUrl) ...[
              const Gap(6),
              _buildFormattedTextContent(
                context,
                displayText,
                textColor,
                primary,
              ),
            ],
          ],
        );
        break;

      case 'voice':
        content =
            args.voiceUrl != null
                ? ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: VoiceMessageBubbleWidget(
                    voiceUrl: args.voiceUrl!,
                    isMe: args.isMe,
                    timestamp: args.createdAt,
                    isRead: _isRead,
                    initialDurationSeconds: args.durationSeconds,
                    isUploading: false,
                  ),
                )
                : Text(context.l10n.voiceNote);
        break;

      case 'file':
        content = FileMessageBubble(
          fileUrl: args.fileUrl ?? '',
          fileName: args.fileName,
          fileSizeBytes: args.fileSizeBytes,
          isMe: args.isMe,
          isUploading: false,
          uploadProgress: null,
        );
        break;

      case 'gif':
        content =
            args.imageUrl != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: GifMessageBubble(
                      url: args.imageUrl!,
                      isMe: args.isMe,
                    ),
                  ),
                )
                : const SizedBox.shrink();
        break;

      case 'sticker':
        content =
            args.imageUrl != null
                ? SizedBox(
                  width: 140,
                  height: 140,
                  child: StickerMessageBubble(url: args.imageUrl!),
                )
                : const SizedBox.shrink();
        break;

      case 'call':
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.call_rounded, color: textColor, size: 20),
            const Gap(8),
            Text(
              args.text.isNotEmpty ? args.text : context.l10n.call,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ],
        );
        break;

      default:
        content = _buildFormattedTextContent(
          context,
          displayText,
          textColor,
          primary,
        );
    }

    final isPureMedia =
        args.messageType == 'sticker' || args.messageType == 'gif';

    final forwardedHeader =
        args.isForwarded
            ? ForwardedHeader(
              originalSenderId: args.forwardedFromUserId ?? '',
              name: args.forwardedFromUserName ?? 'Unknown',
              avatarUrl: args.forwardedFromUserAvatar,
              onColoredBubble: args.isMe && !isPureMedia,
            )
            : null;

    if (isPureMedia) {
      if (forwardedHeader == null) return content;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [forwardedHeader, const Gap(4), content],
      );
    }

    final maxBubbleWidth = (MediaQuery.of(context).size.width * 0.78).clamp(
      280.0,
      360.0,
    );

    return Container(
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(args.isMe ? 16 : 4),
          bottomRight: Radius.circular(args.isMe ? 4 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (forwardedHeader != null) ...[forwardedHeader, const Gap(6)],
          content,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Formatted Text: ReadMoreText + MentionRichText + MessageLinkPreview
  // ---------------------------------------------------------------------------
  Widget _buildFormattedTextContent(
    BuildContext context,
    String text,
    Color textColor,
    Color primary,
  ) {
    final double maxTextWidth = MediaQuery.sizeOf(context).width * 0.75 - 28;

    Widget textWidget;

    if (args.mentions.isNotEmpty) {
      textWidget = MentionRichText(
        text: text,
        style: TextStyle(color: textColor, fontSize: 15, height: 1.35),
        mentionColor: args.isMe ? Colors.white : primary,
        linkColor: LinkColorHelper.forBubble(args.isMe ? primary : Colors.grey),
        maxTextWidth: maxTextWidth,
        mentions: args.mentions,
        collapsedMaxLines: 7,
        onMentionTap: (userId, name) => _onMentionTap(userId, name),
      );
    } else {
      textWidget = ReadMoreText(
        text: text,
        style: TextStyle(color: textColor, fontSize: 15, height: 1.35),
        textMaxWidth: maxTextWidth,
        collapsedMaxLines: 7,
        toggleTextStyle: TextStyle(
          color: args.isMe ? Colors.white.withValues(alpha: 0.85) : primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        contentBuilder: (context, effectiveMaxLines, overflow) {
          return HighlightedLinkifyText(
            text: text,
            maxLines: effectiveMaxLines,
            overflow: overflow,
            style: TextStyle(color: textColor, fontSize: 15, height: 1.35),
            linkStyle: TextStyle(
              color: args.isMe ? Colors.white : Colors.blue,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          );
        },
      );
    }

    return MessageLinkPreview(
      text: text,
      isMe: args.isMe,
      textWidget: textWidget,
    );
  }

  void _onMentionTap(String userId, String name) {
    final currentUserId = SupabaseProvider.idOrNull;

    if (userId == 'all') {
      final isMe = args.senderId == currentUserId;
      if (isMe) {
        AppToast.info(context.l10n.youMentionedAllGroup);
      } else {
        final senderName =
            args.senderName.trim().isNotEmpty
                ? args.senderName.trim()
                : 'Someone';
        AppToast.info(context.l10n.mentionedAllGroupMembers(senderName));
      }
      return;
    }

    if (userId == currentUserId) {
      if (args.senderId == currentUserId) {
        AppToast.info(context.l10n.youMentionedYourselfIn2);
      } else {
        final senderName =
            args.senderName.trim().isNotEmpty
                ? args.senderName.trim()
                : 'Someone';
        AppToast.info(context.l10n.mentionedYouInThis2(senderName));
      }
    } else {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed(AppRoutes.profileViewRoute, arguments: userId);
    }
  }

  // ---------------------------------------------------------------------------
  // Reactions Section
  // ---------------------------------------------------------------------------
  Widget _buildReactionsShimmer(
    BuildContext context,
    Color primary,
    bool isDark, {
    int count = 2,
  }) {
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[750]! : Colors.grey[100]!;
    final displayCount = count.clamp(1, 4);

    return Container(
      decoration: _cardDecoration(context, primary, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.add_reaction_outlined, color: primary, size: 20),
                const Gap(8),
                Text(
                  '${context.l10n.reactions} ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(
                    width: 32,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Column(
              children: [
                for (var i = 0; i < displayCount; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 64, thickness: 0.5),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: i.isEven ? 120 : 95,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    trailing: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsSection(
    BuildContext context,
    Color primary,
    bool isDark,
  ) {
    final rows = [..._reactions]..sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return Container(
      decoration: _cardDecoration(context, primary, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.add_reaction_outlined, color: primary, size: 20),
                const Gap(8),
                Text(
                  '${context.l10n.reactions} (${rows.length})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 64, thickness: 0.5),
            _buildReactionTile(context, rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildReactionTile(BuildContext context, _ReactionRow r) {
    final id = _identity(r.userId);
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: AppAvatar(imageUrl: id.avatar, size: 38),
        title: Text(
          id.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          r.emoji,
          style: TextStyle(
            inherit: false,
            fontSize: 26,
            fontFamilyFallback: AppTypography.emojiFontFallback,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Group Read Receipts Section (Read by ...)
  // ---------------------------------------------------------------------------
  Widget _buildGroupReadReceiptsShimmer(
    BuildContext context,
    Color primary,
    bool isDark, {
    int count = 2,
  }) {
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[750]! : Colors.grey[100]!;
    final displayCount = count.clamp(2, 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: _cardDecoration(context, primary, isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, color: primary, size: 20),
                    const Gap(8),
                    Text(
                      '${context.l10n.readBy('').replaceAll(RegExp(r'[\(\)]'), '').trim()} ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    Shimmer.fromColors(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      child: Container(
                        width: 32,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Column(
                  children: [
                    for (var i = 0; i < displayCount; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, indent: 64, thickness: 0.5),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: i.isEven ? 120 : 100,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 50,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const Gap(6),
                            Container(
                              width: 48,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const Gap(16),
        Container(
          decoration: _cardDecoration(context, primary, isDark),
          child: _buildStatusTile(
            context,
            icon: Icons.done_rounded,
            iconColor: AppColors.greyColor.withValues(alpha: 0.7),
            title: context.l10n.sent,
            subtitle: context.l10n.sentToServer,
            timeText: _fmt(args.createdAt),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupReadReceiptsSection(
    BuildContext context,
    Color primary,
    bool isDark,
  ) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: _cardDecoration(context, primary, isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, color: primary, size: 20),
                    const Gap(8),
                    Text(
                      context.l10n.readBy(_readers.length),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              if (_readers.isNotEmpty)
                for (var i = 0; i < _readers.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 64, thickness: 0.5),
                  _buildReaderTile(context, _readers[i], primary, onSurface),
                ]
              else
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.done_rounded,
                        color: AppColors.grey5,
                        size: 20,
                      ),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          context.l10n.noGroupMembersHave,
                          style: TextStyle(
                            fontSize: 13,
                            color: onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const Gap(16),
        Container(
          decoration: _cardDecoration(context, primary, isDark),
          child: _buildStatusTile(
            context,
            icon: Icons.done_rounded,
            iconColor: AppColors.greyColor.withValues(alpha: 0.7),
            title: context.l10n.sent,
            subtitle: context.l10n.sentToServer,
            timeText: _fmt(args.createdAt),
          ),
        ),
      ],
    );
  }

  Widget _buildReaderTile(
    BuildContext context,
    _ReaderRow reader,
    Color primary,
    Color onSurface,
  ) {
    final id = _identity(reader.userId);
    final member =
        args.members.where((m) => m.userId == reader.userId).firstOrNull;

    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: AppAvatar(imageUrl: id.avatar, size: 38),
        title: Text(
          id.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle:
            member == null
                ? null
                : Text(
                  member.role.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all_rounded, color: primary, size: 16),
            if (reader.readAt != null) ...[
              const Gap(6),
              Text(
                _fmt(reader.readAt),
                style: TextStyle(
                  fontSize: 12,
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Single Chat Status Section (Read / Delivered / Sent)
  // ---------------------------------------------------------------------------
  Widget _buildSingleChatStatusSection(
    BuildContext context,
    Color primary,
    bool isDark,
  ) {
    return Container(
      decoration: _cardDecoration(context, primary, isDark),
      child: Column(
        children: [
          _buildStatusTile(
            context,
            icon: Icons.done_all_rounded,
            iconColor:
                _isRead ? primary : AppColors.greyColor.withValues(alpha: 0.35),
            title: context.l10n.read,
            subtitle:
                _isRead
                    ? (args.receiverName != null
                        ? context.l10n.seenBy(args.receiverName!)
                        : context.l10n.read)
                    : context.l10n.notReadYet,
            timeText: _isRead ? _fmt(_readAt) : '—',
          ),
          const Divider(height: 1, indent: 56, thickness: 0.5),
          _buildStatusTile(
            context,
            icon: Icons.done_all_rounded,
            iconColor: AppColors.greyColor,
            title: context.l10n.delivered,
            subtitle:
                args.receiverName != null
                    ? context.l10n.deliveredTo(args.receiverName!)
                    : context.l10n.delivered,
            timeText: _fmt(_deliveredAt ?? (_isRead ? _readAt : null)),
          ),
          const Divider(height: 1, indent: 56, thickness: 0.5),
          _buildStatusTile(
            context,
            icon: Icons.done_rounded,
            iconColor: AppColors.greyColor.withValues(alpha: 0.7),
            title: context.l10n.sent,
            subtitle: context.l10n.sentToServer,
            timeText: _fmt(args.createdAt),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AI Chat Status Section
  // ---------------------------------------------------------------------------
  Widget _buildAiChatStatusSection(
    BuildContext context,
    Color primary,
    bool isDark,
  ) {
    return Container(
      decoration: _cardDecoration(context, primary, isDark),
      child: Column(
        children: [
          _buildStatusTile(
            context,
            icon: args.isMe ? Icons.done_rounded : Icons.schedule_rounded,
            iconColor: primary,
            title: args.isMe ? context.l10n.sent : 'Generated',
            subtitle:
                args.isMe
                    ? context.l10n.deliveredToAi
                    : context.l10n.responseCreated,
            timeText: _fmt(args.createdAt),
          ),
          const Divider(height: 1, indent: 56, thickness: 0.5),
          _buildStatusTile(
            context,
            icon: Icons.smart_toy_outlined,
            iconColor: Colors.amber.shade700,
            title: context.l10n.model,
            subtitle: context.l10n.aiEngine,
            timeText: args.aiModelLabel ?? 'Gemini 3.5 Flash Lite',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Report Action Card (Incoming Single & Group Messages)
  // ---------------------------------------------------------------------------
  Widget _buildReportActionCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withValues(alpha: 0.22)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.report_gmailerrorred_rounded,
              color: Colors.red,
              size: 24,
            ),
          ),
          title: Text(
            context.l10n.reportMessage,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          subtitle: Text(
            context.l10n.reportSpamAbusiveContent,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.red,
          ),
          onTap: () {
            final targetType =
                args.chatType == MessageInfoChatType.group
                    ? ReportTargetType.groupMessage
                    : ReportTargetType.message;

            ReportBottomSheet.show(
              context,
              target: ReportTarget(type: targetType, id: args.messageId),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper Status Tile
  // ---------------------------------------------------------------------------
  Widget _buildStatusTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String timeText,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
