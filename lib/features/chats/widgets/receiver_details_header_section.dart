import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/chats/widgets/custom_icon_btn_widget.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubit/chat_details_cubit/chat_details_cubit.dart';
import '../models/chat_user_model.dart';

class ReceiverDetailsHeaderSection extends StatelessWidget {
  final ChatUserModel receiverUser;
  const ReceiverDetailsHeaderSection({super.key, required this.receiverUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_ios_new,
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
                const Gap(8),
                BlocBuilder<ChatDetailsCubit, ChatDetailsState>(
                  buildWhen: (previous, current) => current is LastSeenUpdated,
                  builder: (context, state) {
                    final lastSeen =
                        state is LastSeenUpdated
                            ? state.lastSeen
                            : receiverUser.lastSeen;

                    final lastSeenText =
                        lastSeen != null
                            ? FormattedDate.getLastSeen(lastSeen)
                            : null;
                    final isOnline =
                        lastSeen == null || lastSeenText == 'Online';
                    return Stack(
                      children: [
                        Hero(
                          tag: receiverUser.id,
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border:
                                  isOnline
                                      ? Border.all(
                                        color: Colors.green,
                                        width: 2.5,
                                      )
                                      : null,
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl:
                                    (receiverUser.imageUrl != null &&
                                            receiverUser.imageUrl!.isNotEmpty)
                                        ? receiverUser.imageUrl!
                                        : AppImages.defaultUserImg,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) =>
                                        const CustomLoadingIndicator(),
                                errorWidget:
                                    (context, url, error) =>
                                        const Icon(Icons.person),
                              ),
                            ),
                          ),
                        ),
                        if (isOnline)
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
                BlocBuilder<ChatDetailsCubit, ChatDetailsState>(
                  buildWhen: (prev, curr) => curr is LastSeenUpdated,
                  builder: (context, state) {
                    final lastSeen =
                        state is LastSeenUpdated
                            ? state.lastSeen
                            : receiverUser.lastSeen;

                    if (lastSeen == null) {
                      return const Text(
                        'Online',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      );
                    }
                    final lastSeenText = FormattedDate.getLastSeen(lastSeen);
                    final isOnline = lastSeenText == 'Online';
                    return Text(
                      isOnline ? 'Online' : 'last seen $lastSeenText',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          Row(
            children: [
              CustomIconBtnWidget(
                icon: Icons.call_outlined,
                onTap: () {},
                size: 24,
              ),
              const Gap(12),
              CustomIconBtnWidget(
                icon: Icons.videocam_outlined,
                onTap: () {},
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
