import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/group_chats/cubits/group_list_cubit/group_list_cubit.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../../group_calls/helpers/group_call_join_helper.dart';
import '../../group_calls/models/group_call_model.dart';
import '../../group_calls/services/group_call_signaling_service.dart';
import '../models/groupe_message_model.dart';

class GroupCallMessageContent extends StatefulWidget {
  final GroupMessageModel message;
  final bool isMe;
  final Color primary;

  const GroupCallMessageContent({
    super.key,
    required this.message,
    required this.isMe,
    required this.primary,
  });

  @override
  State<GroupCallMessageContent> createState() =>
      _GroupCallMessageContentState();
}

class _GroupCallMessageContentState extends State<GroupCallMessageContent> {
  GroupMessageModel get message => widget.message;
  bool get isMe => widget.isMe;
  Color get primary => widget.primary;

  late Map<String, dynamic> _initialData;
  Stream<Map<String, dynamic>?>? _callDataStream;

  @override
  void initState() {
    super.initState();
    _initialData = _parseInitialData();
    _callDataStream = _createStream();
  }

  @override
  void didUpdateWidget(covariant GroupCallMessageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id ||
        oldWidget.message.text != widget.message.text) {
      _initialData = _parseInitialData();
      _callDataStream = _createStream();
    }
  }

  Map<String, dynamic> _parseInitialData() {
    try {
      final txt = message.text.trim();
      if (txt.startsWith('{')) {
        return jsonDecode(txt) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint(
        '[GroupCallMessageContent] failed to parse call message data: $e',
      );
    }
    return {};
  }

  Stream<Map<String, dynamic>?>? _createStream() {
    if (message.id.startsWith('temp_')) return null;
    return _watchCallData(_initialData);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stream = _callDataStream;
    if (stream == null) {
      return _buildCallBubbleContent(context, _initialData, isDark);
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: stream,
      initialData: _initialData.isNotEmpty ? _initialData : null,
      builder: (context, snapshot) {
        final callData =
            snapshot.data ?? (_initialData.isNotEmpty ? _initialData : {});

        return _buildCallBubbleContent(context, callData, isDark);
      },
    );
  }

  Stream<Map<String, dynamic>?> _watchCallData(
    Map<String, dynamic> initialData,
  ) {
    final callId = initialData['call_id'] as String? ?? '';

    late StreamController<Map<String, dynamic>?> controller;
    StreamSubscription<List<Map<String, dynamic>>>? messageSub;
    StreamSubscription<List<Map<String, dynamic>>>? callSub;

    Map<String, dynamic>? messageData =
        initialData.isNotEmpty ? initialData : null;
    Map<String, dynamic>? callRow;

    void emit() {
      if (controller.isClosed) return;
      final base = messageData;
      if (base == null) {
        controller.add(null);
        return;
      }
      controller.add(_overlayCallRow(base, callRow));
    }

    controller = StreamController<Map<String, dynamic>?>(
      onListen: () {
        messageSub = SupabaseProvider.client
            .from(SupabaseConstants.groupMessages)
            .stream(primaryKey: ['id'])
            .eq('id', message.id)
            .listen(
              (list) {
                if (list.isEmpty) return;
                try {
                  final msgText = list.first['message_text'] as String? ?? '';
                  if (msgText.trim().startsWith('{')) {
                    messageData = jsonDecode(msgText) as Map<String, dynamic>;
                    emit();
                  }
                } catch (e) {
                  debugPrint(
                    '[GroupCallMessageContent] failed to parse latest call message: $e',
                  );
                }
              },
              onError: (Object e) {
                debugPrint(
                  '[GroupCallMessageContent] message stream error: $e',
                );
              },
            );

        if (callId.isNotEmpty) {
          callSub = SupabaseProvider.client
              .from('group_calls')
              .stream(primaryKey: ['call_id'])
              .eq('call_id', callId)
              .listen(
                (rows) {
                  callRow = rows.isEmpty ? null : rows.first;
                  emit();
                },
                onError: (Object e) {
                  debugPrint('[GroupCallMessageContent] call stream error: $e');
                },
              );
        }
      },
      onCancel: () async {
        await messageSub?.cancel();
        await callSub?.cancel();
      },
    );

    return controller.stream;
  }

  Map<String, dynamic> _overlayCallRow(
    Map<String, dynamic> base,
    Map<String, dynamic>? row,
  ) {
    if (row == null) return base;

    final merged = Map<String, dynamic>.from(base);
    final rowStatus = row['status'] as String?;
    if (rowStatus != null && rowStatus.isNotEmpty) {
      merged['status'] = rowStatus;
    }

    final rowDuration = row['duration'] as String?;
    if (_isValidNonZeroDuration(rowDuration)) {
      merged['duration'] = rowDuration!.trim();
    } else if (rowStatus == 'ended') {
      final existing = merged['duration'];
      final hasExisting =
          existing is String && _isValidNonZeroDuration(existing);
      if (!hasExisting) {
        final computed = GroupCallSignalingService.computeConnectedDuration(
          row,
        );
        if (computed != null) merged['duration'] = computed;
      }
    }
    return merged;
  }

  bool _isValidNonZeroDuration(String? d) {
    if (d == null) return false;
    final t = d.trim();
    return t.isNotEmpty && t != '00:00' && t != '0:00' && t != '00:00:00';
  }

  Widget _buildCallBubbleContent(
    BuildContext context,
    Map<String, dynamic> callData,
    bool isDark,
  ) {
    final status = callData['status'] as String? ?? 'ended';
    final callType = callData['call_type'] as String? ?? 'audio';

    final rawDuration = callData['duration'];
    final duration =
        (rawDuration is String && _isValidNonZeroDuration(rawDuration))
            ? rawDuration.trim()
            : '';

    final callId = callData['call_id'] as String? ?? '';
    final groupId = callData[GroupMemberColumns.groupId] as String? ?? '';
    final groupAvatarUrl = callData['group_avatar_url'] as String?;

    final isAudio = callType == 'audio';

    final isLive = status == 'accepted' || status == 'ongoing';

    final isActionable =
        status == 'ringing' || status == 'accepted' || status == 'ongoing';

    final isOngoing = isActionable;

    final isEndedConnected =
        status == 'ended' && _isValidNonZeroDuration(duration);

    final neverConnected =
        status == 'missed' || (status == 'ended' && duration.isEmpty);

    final showAsMissed = neverConnected && !isMe;

    final bubbleBg =
        isMe
            ? primary
            : (isDark
                ? Colors.white.withValues(alpha: 0.09)
                : primary.withValues(alpha: 0.08));

    final labelColor =
        isMe ? Colors.white : (isDark ? Colors.white70 : Colors.black87);
    final subColor =
        isMe ? Colors.white70 : (isDark ? Colors.white54 : Colors.black45);
    final missedTint = Colors.redAccent.shade100;

    final badge = _resolveBadgeStyle(
      isOngoing: isOngoing,
      showAsMissed: showAsMissed,
      isAudio: isAudio,
    );

    final String callLabel;
    if (neverConnected) {
      callLabel =
          showAsMissed
              ? (isAudio ? 'Missed voice call' : 'Missed video call')
              : 'Ended call';
    } else if (isEndedConnected) {
      callLabel = 'Ended call';
    } else {
      callLabel = isAudio ? 'Group voice call' : 'Group video call';
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 210, maxWidth: 270),
      decoration: BoxDecoration(
        color: bubbleBg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        border:
            !isMe
                ? Border.all(
                  color: primary.withValues(alpha: isDark ? 0.2 : 0.12),
                  width: 1,
                )
                : null,
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                message.senderName,
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),

          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildGroupAvatar(groupId, groupAvatarUrl, primary),

              const SizedBox(width: 10),

              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildStateBadge(badge),

                    const SizedBox(width: 8),

                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            callLabel,
                            style: TextStyle(
                              color: showAsMissed ? missedTint : labelColor,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isEndedConnected) ...[
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 11,
                                  color: subColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  duration,
                                  style: TextStyle(
                                    color: subColor,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (isLive) ...[
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Ongoing',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isActionable && groupId.isNotEmpty && callId.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildJoinButton(context, callId, groupId, callType, primary),
          ],

          const SizedBox(height: 4),
          Align(
            alignment: Alignment.bottomRight,
            child: _buildLocalTimeWidget(context),
          ),
        ],
      ),
    );
  }

  _CallBadgeStyle _resolveBadgeStyle({
    required bool isOngoing,
    required bool showAsMissed,
    required bool isAudio,
  }) {
    if (isOngoing) {
      return _CallBadgeStyle(
        background: const Color(0xFF16A34A).withValues(alpha: 0.22),
        border: const Color(0xFF22C55E).withValues(alpha: 0.45),
        iconColor: const Color(0xFF4ADE80),
        icon: isAudio ? Icons.call_rounded : Icons.videocam_rounded,
      );
    }

    if (showAsMissed) {
      return _CallBadgeStyle(
        background: const Color(0xFFEF4444).withValues(alpha: 0.22),
        border: const Color(0xFFEF4444).withValues(alpha: 0.50),
        iconColor: const Color(0xFFF87171),
        icon:
            isAudio
                ? Icons.call_missed_rounded
                : Icons.missed_video_call_rounded,
      );
    }

    // Ended.
    return _CallBadgeStyle(
      background: const Color(0xFFEF4444).withValues(alpha: 0.20),
      border: const Color(0xFFEF4444).withValues(alpha: 0.45),
      iconColor: const Color(0xFFF87171),
      icon: isAudio ? Icons.call_end_rounded : Icons.videocam_off_rounded,
    );
  }

  Widget _buildStateBadge(_CallBadgeStyle style) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: style.background,
        border: Border.all(color: style.border, width: 1),
      ),
      child: Icon(style.icon, color: style.iconColor, size: 18),
    );
  }

  Widget _buildGroupAvatar(
    String? groupId,
    String? fallbackAvatarUrl,
    Color primary,
  ) {
    const double size = 40;

    return BlocBuilder<GroupListCubit, GroupListState>(
      builder: (context, state) {
        String? liveAvatarUrl;
        if (state is GroupListLoaded && groupId != null && groupId.isNotEmpty) {
          final liveGroup = state.groups.firstWhereOrNull(
            (g) => g.id == groupId,
          );
          liveAvatarUrl = liveGroup?.avatarUrl;
        }

        final avatarUrl = liveAvatarUrl ?? fallbackAvatarUrl;
        final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMe ? Colors.white : primary.withValues(alpha: 0.15),
            border: Border.all(
              color: primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child:
                hasAvatar
                    ? CachedCloudinaryImage(
                      secureUrl: avatarUrl,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,

                      isAvatar: true,
                      errorWidget:
                          (_, __) => _groupAvatarFallback(primary, size),
                    )
                    : _groupAvatarFallback(primary, size),
          ),
        );
      },
    );
  }

  Widget _groupAvatarFallback(Color primary, double size) {
    return Container(
      width: size,
      height: size,
      color: primary.withValues(alpha: 0.12),
      child: Center(
        child: Icon(Icons.group_rounded, color: primary, size: size * 0.55),
      ),
    );
  }

  Widget _buildLocalTimeWidget(BuildContext context) {
    final localTime = message.createdAt.toLocal();
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    int hour12 = localTime.hour % 12;
    hour12 = hour12 == 0 ? 12 : hour12;

    final hourStr = hour12.toString();
    final minuteStr = localTime.minute.toString().padLeft(2, '0');

    return Text(
      '$hourStr:$minuteStr $period',
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
        color:
            isMe ? AppColors.white70 : Theme.of(context).colorScheme.onSurface,
        fontSize: 9,
      ),
    );
  }

  Widget _buildJoinButton(
    BuildContext context,
    String callId,
    String groupId,
    String callType,
    Color primary,
  ) {
    return StreamBuilder<GroupCallModel?>(
      stream: context.read<GroupCallSignalingService>().activeCallStream(
        groupId,
      ),
      builder: (context, snapshot) {
        final activeCall = snapshot.data;
        if (activeCall == null) return const SizedBox.shrink();
        if (activeCall.callId != callId) return const SizedBox.shrink();

        final currentUserId = SupabaseProvider.id;
        if (activeCall.initiatorId == currentUserId) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => GroupCallJoinHelper.join(context, activeCall),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.green.shade500,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  callType == 'video'
                      ? Icons.videocam_rounded
                      : Icons.call_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                const SizedBox(width: 5),
                const Text(
                  'Tap to Join',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CallBadgeStyle {
  final Color background;
  final Color border;
  final Color iconColor;
  final IconData icon;

  const _CallBadgeStyle({
    required this.background,
    required this.border,
    required this.iconColor,
    required this.icon,
  });
}
