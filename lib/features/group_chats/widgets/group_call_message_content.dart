import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../../core/widgets/cached_cloudinary_image.dart';
import '../../group_calls/models/group_call_model.dart';
import '../../group_calls/services/group_call_signaling_service.dart';
import '../../group_calls/views/livekit_group_call_view.dart';
import '../models/groupe_message_model.dart';

class GroupCallMessageContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Map<String, dynamic> initialData = {};
    try {
      final txt = message.text.trim();
      if (txt.startsWith('{')) {
        initialData = jsonDecode(txt) as Map<String, dynamic>;
      }
    } catch (_) {}

    final isTemp = message.id.startsWith('temp_');
    if (isTemp) {
      return _buildCallBubbleContent(context, initialData, isDark);
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _watchCallData(),
      initialData: initialData.isNotEmpty ? initialData : null,
      builder: (context, snapshot) {
        final callData =
            snapshot.data ?? (initialData.isNotEmpty ? initialData : {});

        return _buildCallBubbleContent(context, callData, isDark);
      },
    );
  }

  Stream<Map<String, dynamic>?> _watchCallData() {
    return SupabaseProvider.client
        .from(SupabaseConstants.groupMessages)
        .stream(primaryKey: ['id'])
        .eq('id', message.id)
        .map((list) {
          if (list.isEmpty) return null;
          try {
            final msgText = list.first['message_text'] as String? ?? '';
            if (msgText.trim().startsWith('{')) {
              return jsonDecode(msgText) as Map<String, dynamic>;
            }
          } catch (_) {}
          return null;
        });
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
        (rawDuration is String && rawDuration.isNotEmpty) ? rawDuration : '';

    final callId = callData['call_id'] as String? ?? '';
    final groupId = callData[GroupMemberColumns.groupId] as String? ?? '';
    final groupAvatarUrl = callData['group_avatar_url'] as String?;

    final isAudio = callType == 'audio';
    final isMissed = status == 'missed';
    final isEnded = status == 'ended';
    final isOngoing =
        status == 'ringing' || status == 'accepted' || status == 'ongoing';

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
    final iconColor = isMissed ? Colors.redAccent.shade100 : Colors.greenAccent;

    final IconData callIcon =
        isMissed
            ? (isAudio
                ? Icons.call_missed_rounded
                : Icons.missed_video_call_rounded)
            : (isAudio ? Icons.call_rounded : Icons.videocam_rounded);

    final String callLabel =
        isMissed
            ? (isAudio ? 'Missed voice call' : 'Missed video call')
            : (isAudio ? 'Group voice call' : 'Group video call');

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
              _buildGroupAvatar(groupAvatarUrl, primary),
              const SizedBox(width: 10),

              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(callIcon, color: iconColor, size: 17),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            callLabel,
                            style: TextStyle(
                              color: labelColor,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (isEnded && duration.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 11, color: subColor),
                          const SizedBox(width: 4),
                          Text(
                            duration,
                            style: TextStyle(color: subColor, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ] else if (isOngoing) ...[
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
                          Text(
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

          if (isOngoing && groupId.isNotEmpty && callId.isNotEmpty) ...[
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

  Widget _buildGroupAvatar(String? groupAvatarUrl, Color primary) {
    const double size = 40;
    final hasAvatar = groupAvatarUrl != null && groupAvatarUrl.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isMe ? Colors.white : primary.withValues(alpha: 0.15),
        border: Border.all(color: primary.withValues(alpha: 0.35), width: 1.5),
      ),
      child: ClipOval(
        child:
            hasAvatar
                ? CachedCloudinaryImage(
                  secureUrl: groupAvatarUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,

                  isAvatar: true,
                  errorWidget: (_, __) => _groupAvatarFallback(primary, size),
                )
                : _groupAvatarFallback(primary, size),
      ),
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
          onTap: () async {
            final signaling = context.read<GroupCallSignalingService>();
            final joined = await signaling.acceptCall(activeCall.callId);
            final user = SupabaseProvider.user!;
            final profile =
                await SupabaseProvider.client
                    .from('users')
                    .select('name')
                    .eq('id', user.id)
                    .maybeSingle();
            final userName = (profile?['name'] as String?) ?? 'Me';
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => LiveKitGroupCallView(
                        call: joined,
                        currentUserId: user.id,
                        currentUserName: userName,
                      ),
                ),
              );
            }
          },
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
