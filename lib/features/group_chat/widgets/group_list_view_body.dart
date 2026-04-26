import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/group_chat/widgets/group_tile_item_widget.dart';
import '../../chats/views/chats_list_skeleton.dart';
import '../cubit/group_list_cubit/group_list_cubit.dart';

class GroupsListViewBody extends StatefulWidget {
  const GroupsListViewBody({super.key});

  @override
  State<GroupsListViewBody> createState() => _GroupsListViewBodyState();
}

class _GroupsListViewBodyState extends State<GroupsListViewBody>
    with WidgetsBindingObserver, RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final currentState = context.read<GroupListCubit>().state;
    if (currentState is! GroupListLoaded && currentState is! GroupListLoading) {
      context.read<GroupListCubit>().loadGroups();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<GroupListCubit>().loadGroups(isRefresh: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<GroupListCubit, GroupListState>(
      builder: (context, state) {
        if (state is GroupListLoaded) {
          if (state.groups.isEmpty) {
            return _buildEmptyState(context, primary);
          }

          return ListView.separated(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(top: 6, bottom: 100),
            itemCount: state.groups.length,
            separatorBuilder:
                (_, __) => Divider(
                  height: 1,
                  indent: 80,
                  color:
                      isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.06),
                ),
            itemBuilder: (context, index) {
              return GroupTileItem(group: state.groups[index]);
            },
          );
        } else if (state is GroupListLoading || state is GroupListInitial) {
          return const ChatsListSkeleton();
        } else if (state is GroupListError) {
          return Center(child: Text(state.message));
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

Widget _buildEmptyState(BuildContext context, Color primary) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.group_rounded,
          size: 80,
          color: primary.withValues(alpha: 0.3),
        ),
        const Gap(16),
        Text(
          'No groups yet',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: primary.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(8),
        Text(
          'Tap + to create your first group',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ],
    ),
  );
}
