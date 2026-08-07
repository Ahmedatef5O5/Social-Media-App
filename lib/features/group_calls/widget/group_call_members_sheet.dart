import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../core/services/active_call/pip/call_pip_cubit.dart';
import '../../../core/services/notification_services.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/widgets/calls/call_avatar_image.dart';
import '../../../core/widgets/calls/call_status_pill.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../group_chats/cubit/group_members_cubit/group_members_cubit.dart';
import '../../group_chats/models/group_member_model.dart';
import '../../group_chats/services/group_chat_services.dart';
import '../../single_calls/cubits/single_call_cubit/call_cubit.dart';
import '../models/group_call_model.dart';

class GroupCallMemberEntry {
  final GroupMemberModel member;
  final bool isActive;

  const GroupCallMemberEntry({required this.member, required this.isActive});
}

class GroupCallMembersSheet extends StatefulWidget {
  final GroupCallModel call;

  const GroupCallMembersSheet({super.key, required this.call});

  static Future<void> show(BuildContext context, GroupCallModel call) {
    final ctx = navigatorKey.currentContext ?? context;
    return showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroupCallMembersSheet(call: call),
    );
  }

  @override
  State<GroupCallMembersSheet> createState() => _GroupCallMembersSheetState();
}

class _GroupCallMembersSheetState extends State<GroupCallMembersSheet> {
  late final GroupMembersCubit _membersCubit;
  late final ScrollController _scrollController;

  EventsListener<RoomEvent>? _roomListener;
  Set<String> _activeUserIds = {};

  // Optimistic "Ring" state — userId -> currently ringing.
  final Set<String> _ringingUserIds = {};
  final Map<String, Timer> _ringingCooldowns = {};

  @override
  void initState() {
    super.initState();

    _membersCubit = GroupMembersCubit(
      context.read<GroupChatServices>(),
      groupId: widget.call.groupId,
    )..loadMembers();

    _scrollController = ScrollController()..addListener(_onScroll);

    final room = context.read<CallPipCubit>().state.room;
    _syncActiveIds(room);
    if (room != null) {
      _roomListener = room.createListener();
      _roomListener!
        ..on<ParticipantConnectedEvent>((_) => _syncActiveIds(room))
        ..on<ParticipantDisconnectedEvent>((_) => _syncActiveIds(room));
    }
  }

  void _syncActiveIds(Room? room) {
    if (room == null || !mounted) return;
    final ids =
        {
          room.localParticipant?.identity,
          ...room.remoteParticipants.values.map((p) => p.identity),
        }.whereType<String>().toSet();
    setState(() {
      _activeUserIds = ids;
      for (final id in ids) {
        _ringingUserIds.remove(id);
        _ringingCooldowns.remove(id)?.cancel();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _membersCubit.loadMoreMembers();
    }
  }

  Future<void> _ringMember(GroupMemberModel member) async {
    if (_ringingUserIds.contains(member.userId)) return;

    setState(() => _ringingUserIds.add(member.userId));

    await context.read<CallCubit>().ringOfflineMember(
      widget.call,
      member.userId,
    );

    _ringingCooldowns[member.userId] = Timer(const Duration(seconds: 25), () {
      if (!mounted) return;
      setState(() => _ringingUserIds.remove(member.userId));
    });
  }

  @override
  void dispose() {
    _roomListener?.dispose();
    for (final timer in _ringingCooldowns.values) {
      timer.cancel();
    }
    _scrollController.dispose();
    _membersCubit.close();
    super.dispose();
  }

  List<GroupCallMemberEntry> _mergeAndSort(List<GroupMemberModel> members) {
    final entries =
        members
            .map(
              (m) => GroupCallMemberEntry(
                member: m,
                isActive: _activeUserIds.contains(m.userId),
              ),
            )
            .toList();

    entries.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return a.member.userName.toLowerCase().compareTo(
        b.member.userName.toLowerCase(),
      );
    });

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final currentUserId = SupabaseProvider.id;
    final sheetMaxHeight = MediaQuery.of(context).size.height * 0.72;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(maxHeight: sheetMaxHeight),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: BlocBuilder<GroupMembersCubit, GroupMembersState>(
              bloc: _membersCubit,
              builder: (context, state) {
                final loaded = state is GroupMembersLoaded ? state : null;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Group Members',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (loaded != null)
                            Text(
                              '${loaded.totalCount}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    Flexible(
                      child: _buildBody(state, loaded, primary, currentUserId),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    GroupMembersState state,
    GroupMembersLoaded? loaded,
    Color primary,
    String currentUserId,
  ) {
    if (state is GroupMembersInitial || state is GroupMembersLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CustomLoadingIndicator()),
      );
    }

    if (state is GroupMembersError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            state.message,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final entries = _mergeAndSort(loaded!.members);

    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: entries.length + (loaded.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= entries.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CustomLoadingIndicator()),
          );
        }

        final entry = entries[index];
        return _MemberTile(
          entry: entry,
          isCurrentUser: entry.member.userId == currentUserId,
          isRinging: _ringingUserIds.contains(entry.member.userId),
          primary: primary,
          onRing: () => _ringMember(entry.member),
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  final GroupCallMemberEntry entry;
  final bool isCurrentUser;
  final bool isRinging;
  final Color primary;
  final VoidCallback onRing;

  const _MemberTile({
    required this.entry,
    required this.isCurrentUser,
    required this.isRinging,
    required this.primary,
    required this.onRing,
  });

  @override
  Widget build(BuildContext context) {
    final member = entry.member;
    final isAdmin = member.role == GroupMemberRole.admin;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          CallAvatarImage(
            imageUrl: member.userAvatar,
            fallbackLabel: member.userName,
            diameter: 46,
            borderColor:
                entry.isActive
                    ? Colors.greenAccent.withValues(alpha: 0.85)
                    : Colors.white,
            borderWidth: entry.isActive ? 2.4 : 2,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isCurrentUser ? 'You' : member.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.isActive ? 'In the call' : 'Not in the call',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          entry.isActive
              ? const CallStatusPill(
                icon: Icons.graphic_eq_rounded,
                label: 'In Call',
                showLiveDot: true,
              )
              : _RingButton(
                isRinging: isRinging,
                primary: primary,
                onTap: onRing,
              ),
        ],
      ),
    );
  }
}

class _RingButton extends StatelessWidget {
  final bool isRinging;
  final Color primary;
  final VoidCallback onTap;

  const _RingButton({
    required this.isRinging,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isRinging ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              isRinging
                  ? Colors.white.withValues(alpha: 0.08)
                  : primary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: isRinging ? 0.15 : 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRinging)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              )
            else
              const Icon(
                Icons.notifications_active_rounded,
                size: 14,
                color: Colors.white,
              ),
            const SizedBox(width: 6),
            Text(
              isRinging ? 'Ringing…' : 'Ring',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
