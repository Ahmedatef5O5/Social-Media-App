import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import '../../../core/chat_shared/helpers/muted_badge_icon.dart';
import '../../../core/presence/models/chat_action_type.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../../core/presence/widgets/presence_status_text.dart';
import '../../../core/widgets/animated_activity_text.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/calls/call_icon_button.dart';
import '../../single_calls/models/call_model.dart';
import '../cubits/chat_details_cubit/chat_details_cubit.dart';
import '../helpers/safe_pop.dart';
import '../models/chat_block_status.dart';
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          receiverUser.name,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable:
                            context.read<ChatDetailsCubit>().muteStatus,
                        builder:
                            (context, isMuted, _) =>
                                isMuted
                                    ? const MutedBadgeIcon(size: 10)
                                    : const SizedBox.shrink(),
                      ),
                    ],
                  ),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: ValueListenableBuilder<ChatActionType>(
                      valueListenable:
                          context.read<ChatDetailsCubit>().receiverAction,
                      builder: (context, action, _) {
                        if (action != ChatActionType.none) {
                          return AnimatedActivityText(
                            text:
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
                        return PresenceStatusText(
                          userId: receiverUser.id,
                          fallbackIsOnline: receiverUser.isOnline,
                          fallbackLastSeen: receiverUser.lastSeen,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          Row(
            children: [
              ValueListenableBuilder<ChatBlockStatus>(
                valueListenable: context.read<ChatDetailsCubit>().blockStatus,
                builder: (context, blockStatus, _) {
                  return Row(
                    children: [
                      CallIconButton(
                        size: 21,
                        type: CallType.audio,
                        receiverId: receiverUser.id,
                        receiverName: receiverUser.name,
                        receiverAvatar: receiverUser.imageUrl ?? '',
                        isBlocked: blockStatus.isBlocked,
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
                        isBlocked: blockStatus.isBlocked,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        style: IconButton.styleFrom(
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  );
                },
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
