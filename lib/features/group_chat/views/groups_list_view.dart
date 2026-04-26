// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:gap/gap.dart';
// import '../cubit/group_list_cubit/group_list_cubit.dart';
// import '../widgets/group_tile_item_widget.dart';

// class GroupsListView extends StatefulWidget {
//   const GroupsListView({super.key});

//   @override
//   State<GroupsListView> createState() => _GroupsListViewState();
// }

// class _GroupsListViewState extends State<GroupsListView> {
//   @override
//   void initState() {
//     super.initState();
//     context.read<GroupListCubit>().monitorGroups();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final primary = Theme.of(context).primaryColor;
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return BlocBuilder<GroupListCubit, GroupListState>(
//       builder: (context, state) {
//         if (state is GroupListLoading) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (state is GroupListError) {
//           return Center(child: Text(state.message));
//         }
//         if (state is GroupListLoaded) {
//           if (state.groups.isEmpty) {
//             return _buildEmptyState(context, primary);
//           }
//           return ListView.separated(
//             physics: const AlwaysScrollableScrollPhysics(
//               parent: ClampingScrollPhysics(),
//             ),
//             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//             itemCount: state.groups.length,
//             separatorBuilder:
//                 (_, __) => Divider(
//                   height: 1,
//                   indent: 80,
//                   color:
//                       isDark
//                           ? Colors.white12
//                           : Colors.black.withValues(alpha: 0.06),
//                 ),
//             itemBuilder:
//                 (_, index) => GroupTileItem(group: state.groups[index]),
//           );
//         }
//         return const SizedBox.shrink();
//       },
//     );
//   }
// }
