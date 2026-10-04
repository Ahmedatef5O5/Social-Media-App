import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/group_details_cubit/group_details_cubit.dart';
import '../models/group_header_stats.dart';

class GroupMembersOnlineLabel extends StatefulWidget {
  final String groupId;
  final TextStyle? style;
  const GroupMembersOnlineLabel({super.key, required this.groupId, this.style});

  @override
  State<GroupMembersOnlineLabel> createState() =>
      _GroupMembersOnlineLabelState();
}

class _GroupMembersOnlineLabelState extends State<GroupMembersOnlineLabel> {
  static const Duration _minDwell = Duration(seconds: 6);

  StreamSubscription<GroupHeaderStats>? _sub;
  GroupHeaderStats? _displayedStats;
  GroupHeaderStats? _pendingStats;
  Timer? _dwellTimer;
  DateTime? _lastAppliedAt;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant GroupMembersOnlineLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _sub?.cancel();
      _dwellTimer?.cancel();
      _displayedStats = null;
      _pendingStats = null;
      _lastAppliedAt = null;
      _subscribe();
    }
  }

  void _subscribe() {
    _sub = context.read<GroupDetailsCubit>().watchHeaderStats().listen(
      _onStatsReceived,
    );
  }

  void _onStatsReceived(GroupHeaderStats stats) {
    _pendingStats = stats;
    _scheduleApply();
  }

  void _scheduleApply() {
    final lastAppliedAt = _lastAppliedAt;

    if (lastAppliedAt == null) {
      _applyPending();
      return;
    }

    final elapsedSinceLastChange = DateTime.now().difference(lastAppliedAt);
    if (elapsedSinceLastChange >= _minDwell) {
      _applyPending();
      return;
    }

    _dwellTimer?.cancel();
    _dwellTimer = Timer(_minDwell - elapsedSinceLastChange, _applyPending);
  }

  void _applyPending() {
    final pending = _pendingStats;
    if (pending == null || !mounted) return;
    setState(() {
      _displayedStats = pending;
      _lastAppliedAt = DateTime.now();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _dwellTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _displayedStats;
    final text =
        stats == null
            ? 'Tap for group info'
            : '${stats.totalMembers} member${stats.totalMembers == 1 ? '' : 's'}'
                '${stats.onlineCount > 0 ? ', ${stats.onlineCount} online' : ''}';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder:
          (child, anim) => FadeTransition(opacity: anim, child: child),
      child: Text(
        text,
        key: ValueKey(text),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
      ),
    );
  }
}
