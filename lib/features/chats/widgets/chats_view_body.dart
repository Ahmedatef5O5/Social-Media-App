import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/widgets/custom_tab_wrapper.dart';
import 'package:social_media_app/features/chats/views/chats_list_skeleton.dart';
import 'package:social_media_app/features/chats/widgets/chats_header_section.dart';
import 'package:social_media_app/features/chats/widgets/chats_list_view_section.dart';
// import 'package:social_media_app/features/chats/widgets/voice_message_bubble_widget.dart';
// import '../../../core/router/app_routes.dart';
import '../../../core/widgets/custom_pull_to_refresh.dart';
// import '../../group_chat/models/group_model.dart';
// import '../../group_chat/services/group_chat_services.dart';
import '../cubit/chats_cubit/chats_cubit.dart';

class ChatsViewBody extends StatefulWidget {
  const ChatsViewBody({super.key});

  @override
  State<ChatsViewBody> createState() => _ChatsViewBodyState();
}

class _ChatsViewBodyState extends State<ChatsViewBody> {
  // late final Future<GroupModel?> _groupFuture;

  // @override
  // void initState() {
  //   super.initState();
  //   _groupFuture = GroupChatServices().getGroup();
  // }

  // @override
  // void dispose() {
  //   VoiceMessageBubbleWidget.clearCache();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: BlocBuilder<ChatsCubit, ChatsState>(
        builder: (context, state) {
          return CustomTabWrapper(
            isLoading: state is ChatsInitial || state is ChatsLoading,
            loadingSkeleton: const ChatsListSkeleton(),
            errorMessage: state is ChatsError ? state.message : null,
            onRetry: () => context.read<ChatsCubit>().getChats(),

            child: CustomPullToRefresh(
              onRefresh:
                  () async => await context.read<ChatsCubit>().getChats(
                    isRefresh: true,
                  ),
              child: Column(
                children: [
                  const Gap(20),
                  ChatsHeaderSection(),
                  const Gap(20),

                  // FutureBuilder<GroupModel?>(
                  //   future: _groupFuture,
                  //   builder: (context, snapshot) {
                  //     debugPrint(
                  //       'Group snapshot: ${snapshot.connectionState} | data: ${snapshot.data} | error: ${snapshot.error}',
                  //     );
                  //     if (snapshot.connectionState == ConnectionState.waiting) {
                  //       return const SizedBox(
                  //         height: 65,
                  //         child: Center(child: CustomLoadingIndicator()),
                  //       );
                  //     }
                  //     if (snapshot.hasError) {
                  //       debugPrint('Group error: ${snapshot.error}');
                  //       return const SizedBox.shrink();
                  //     }
                  //     if (!snapshot.hasData || snapshot.data == null) {
                  //       debugPrint('No group found in database!');
                  //       return const SizedBox.shrink();
                  //     }
                  //     if (!snapshot.hasData) return const SizedBox.shrink();
                  //     final group = snapshot.data!;
                  //     return GestureDetector(
                  //       onTap:
                  //           () => Navigator.of(
                  //             context,
                  //             rootNavigator: true,
                  //           ).pushNamed(AppRoutes.groupChatRoute, arguments: group),
                  //       child: Container(
                  //         margin: const EdgeInsets.only(bottom: 8),
                  //         padding: const EdgeInsets.all(12),
                  //         decoration: BoxDecoration(
                  //           color: Theme.of(
                  //             context,
                  //           ).primaryColor.withValues(alpha: 0.08),
                  //           borderRadius: BorderRadius.circular(14),
                  //           border: Border.all(
                  //             color: Theme.of(
                  //               context,
                  //             ).primaryColor.withValues(alpha: 0.25),
                  //           ),
                  //         ),
                  //         child: Row(
                  //           children: [
                  //             CircleAvatar(
                  //               backgroundColor:
                  //                   Theme.of(
                  //                     context,
                  //                   ).scaffoldBackgroundColor.withValues(),
                  //               radius: 26,
                  //               child: Icon(
                  //                 Icons.group,
                  //                 color: Theme.of(context).primaryColor,
                  //                 size: 28,
                  //               ),
                  //             ),
                  //             const Gap(12),
                  //             Column(
                  //               crossAxisAlignment: CrossAxisAlignment.start,
                  //               children: [
                  //                 Text(
                  //                   group.name,
                  //                   style: const TextStyle(
                  //                     fontWeight: FontWeight.bold,
                  //                     fontSize: 16,
                  //                   ),
                  //                 ),
                  //                 Text(
                  //                   '${group.memberCount} members',
                  //                   style: const TextStyle(
                  //                     color: Colors.grey,
                  //                     fontSize: 13,
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //             const Spacer(),
                  //             Icon(
                  //               Icons.chevron_right,
                  //               color: Theme.of(
                  //                 context,
                  //               ).primaryColor.withValues(alpha: 0.5),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     );
                  //   },
                  // ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (state is ChatsSuccessloaded) {
                          return ChatsListViewSection(chats: state.chats);
                        } else {
                          return SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
