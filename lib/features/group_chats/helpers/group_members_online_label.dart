import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/group_details_cubit/group_details_cubit.dart';
import '../models/group_header_stats.dart';

class GroupMembersOnlineLabel extends StatelessWidget {
  final String groupId;
  final TextStyle? style;
  const GroupMembersOnlineLabel({super.key, required this.groupId, this.style});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GroupHeaderStats>(
      stream: context.read<GroupDetailsCubit>().watchHeaderStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data;
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
            style: style,
          ),
        );
      },
    );
  }
}
