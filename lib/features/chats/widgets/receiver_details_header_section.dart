import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/chats/widgets/custom_icon_btn_widget.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../../calls/cubits/single_call_cubit/call_cubit.dart';
import '../../calls/model/call_model.dart';
import '../cubit/chat_details_cubit/chat_details_cubit.dart';
import '../helper/call_actions.dart';
import '../helper/safe_pop.dart';
import '../models/chat_user_model.dart';

class ReceiverDetailsHeaderSection extends StatefulWidget {
  final ChatUserModel receiverUser;
  final Widget Function(ChatDetailsState state)? statusBuilder;

  const ReceiverDetailsHeaderSection({
    super.key,
    required this.receiverUser,
    this.statusBuilder,
  });

  @override
  State<ReceiverDetailsHeaderSection> createState() =>
      _ReceiverDetailsHeaderSectionState();
}

class _ReceiverDetailsHeaderSectionState
    extends State<ReceiverDetailsHeaderSection> {
  // Caching Variables
  late bool _isOnlineCache;
  DateTime? _lastSeenCache;

  @override
  void initState() {
    super.initState();
    _isOnlineCache = widget.receiverUser.isOnline;
    _lastSeenCache = widget.receiverUser.lastSeen;
  }

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
                BlocBuilder<ChatDetailsCubit, ChatDetailsState>(
                  builder: (context, state) {
                    // Update cache securely
                    if (state is ReceiverPresenceUpdated) {
                      _isOnlineCache = state.isOnline;
                      if (state.lastSeen != null) {
                        _lastSeenCache = state.lastSeen;
                      }
                    } else if (state is LastSeenUpdated) {
                      if (state.lastSeen != null) {
                        _lastSeenCache = state.lastSeen;
                      }
                    }

                    final lastSeenText =
                        _lastSeenCache != null
                            ? FormattedDate.getLastSeen(_lastSeenCache!)
                            : null;
                    final isOnlineIndicator =
                        _isOnlineCache == true ||
                        lastSeenText == 'just now' ||
                        lastSeenText == 'Online';

                    return Stack(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushNamed(
                              AppRoutes.receiverProfileViewRoute,
                              arguments: widget.receiverUser,
                            );
                          },
                          child: Hero(
                            tag: widget.receiverUser.id,
                            child: Container(
                              height: 42,
                              width: 42,

                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border:
                                    isOnlineIndicator
                                        ? Border.all(
                                          color: Colors.green,
                                          width: 2.5,
                                        )
                                        : null,
                              ),
                              child: ClipOval(
                                child:
                                    (widget.receiverUser.imageUrl != null &&
                                            widget
                                                .receiverUser
                                                .imageUrl!
                                                .isNotEmpty)
                                        ? CachedNetworkImage(
                                          imageUrl:
                                              widget.receiverUser.imageUrl!,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) =>
                                                  const CustomLoadingIndicator(),
                                          errorWidget:
                                              (context, url, error) =>
                                                  Image.asset(
                                                    AppImages.defaultUserImg,
                                                    fit: BoxFit.cover,
                                                  ),
                                        )
                                        : Image.asset(
                                          AppImages.defaultUserImg,
                                          fit: BoxFit.cover,
                                        ),
                              ),
                            ),
                          ),
                        ),
                        if (isOnlineIndicator)
                          Positioned(
                            bottom: 1,
                            right: 1,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
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
                  arguments: widget.receiverUser,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.receiverUser.name,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  BlocBuilder<ChatDetailsCubit, ChatDetailsState>(
                    builder: (context, state) {
                      if (widget.statusBuilder != null) {
                        return widget.statusBuilder!(state);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              CustomIconBtnWidget(
                icon: Icons.call_outlined,
                onTap: () async {
                  final call = await CallActions.buildCall(
                    type: CallType.audio,
                    receiverId: widget.receiverUser.id,
                    receiverName: widget.receiverUser.name,
                    receiverAvatar: widget.receiverUser.imageUrl ?? '',
                  );
                  if (call == null || !context.mounted) return;

                  context.read<CallCubit>().makeAudioCall(call);
                },
                size: 24,
              ),
              const Gap(12),
              CustomIconBtnWidget(
                icon: Icons.videocam_outlined,
                onTap: () async {
                  final call = await CallActions.buildCall(
                    type: CallType.video,
                    receiverId: widget.receiverUser.id,
                    receiverName: widget.receiverUser.name,
                    receiverAvatar: widget.receiverUser.imageUrl ?? '',
                  );
                  if (call == null || !context.mounted) return;

                  context.read<CallCubit>().makeAudioCall(call);
                },
                size: 24,
              ),
              const Gap(8),
              CustomIconBtnWidget(
                icon: Icons.more_vert_outlined,
                onTap: () {},
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
