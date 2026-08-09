import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/presence/cubit/presence_cubit/presence_cubit.dart';
import '../../../core/presence/model/chat_action_type.dart';
import '../../../core/presence/model/presence_info.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/calls/call_icon_button.dart';
import '../../single_calls/model/call_model.dart';
import '../cubit/chat_details_cubit/chat_details_cubit.dart';
import '../helper/safe_pop.dart';
import '../models/chat_user_model.dart';

class ReceiverDetailsHeaderSection extends StatelessWidget {
  final ChatUserModel receiverUser;
  final ItemScrollController itemScrollController;

  const ReceiverDetailsHeaderSection({
    super.key,
    required this.receiverUser,
    required this.itemScrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          InkWell(
            onTap: () => safePop(context),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_ios_new,
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
                const Gap(8),

                PresenceAvatarWidget(
                  userId: receiverUser.id,
                  avatarSize: 42,
                  showDot: true,
                  showBorder: true,
                  child: AppAvatar(
                    imageUrl: receiverUser.imageUrl,
                    size: 42,
                    heroTag: receiverUser.id,
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pushNamed(
                        AppRoutes.receiverProfileViewRoute,
                        arguments: {
                          'user': receiverUser,
                          'cubit': context.read<ChatDetailsCubit>(),
                          'itemScrollController': itemScrollController,
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Gap(12),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context, rootNavigator: true).pushNamed(
                  AppRoutes.receiverProfileViewRoute,
                  arguments: {
                    'user': receiverUser,
                    'cubit': context.read<ChatDetailsCubit>(),
                    'itemScrollController': itemScrollController,
                  },
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    receiverUser.name,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  ValueListenableBuilder<ChatActionType>(
                    valueListenable:
                        context.read<ChatDetailsCubit>().receiverAction,
                    builder: (context, action, _) {
                      if (action != ChatActionType.none) {
                        return Text(
                          action == ChatActionType.recording
                              ? 'recording audio...'
                              : 'typing...',
                          style: TextStyle(
                            color:
                                action == ChatActionType.recording
                                    ? Colors.red.shade700
                                    : Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }
                      return Builder(
                        builder: (context) {
                          final presenceInfo = context
                              .select<PresenceCubit, PresenceInfo?>(
                                (cubit) => cubit.of(receiverUser.id),
                              );

                          final isOnline =
                              presenceInfo?.isEffectivelyOnline ??
                              receiverUser.isOnline;
                          final lastSeen =
                              presenceInfo?.lastSeen ?? receiverUser.lastSeen;

                          if (isOnline) {
                            return const Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }

                          if (lastSeen != null) {
                            final lastSeenStr = FormattedDate.getLastSeen(
                              lastSeen,
                            );
                            if (lastSeenStr == 'Online' ||
                                lastSeenStr == 'just now') {
                              return const Text(
                                'Online',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }
                            return Text(
                              "Last seen $lastSeenStr",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          Row(
            children: [
              CallIconButton(
                size: 21,
                type: CallType.audio,
                receiverId: receiverUser.id,
                receiverName: receiverUser.name,
                receiverAvatar: receiverUser.imageUrl ?? '',
                padding: const EdgeInsets.symmetric(horizontal: 6),
                style: IconButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              CallIconButton(
                size: 21,
                type: CallType.video,
                receiverId: receiverUser.id,
                receiverName: receiverUser.name,
                receiverAvatar: receiverUser.imageUrl ?? '',
                padding: const EdgeInsets.symmetric(horizontal: 6),
                style: IconButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.more_vert_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 21,
                  ),
                ),
                onSelected: (value) {
                  if (value == 'search') {
                    context
                        .read<ChatDetailsCubit>()
                        .searchController
                        .activate();
                  }
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: 'search',
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, size: 20),
                            Gap(10),
                            Text('Search'),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
