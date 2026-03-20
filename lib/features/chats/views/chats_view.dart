import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/core/widgets/custom_pull_to_refresh.dart';
import 'package:social_media_app/features/chats/cubit/chats_cubit/chats_cubit.dart';
import '../widgets/chats_header_section.dart';

class ChatsView extends StatelessWidget {
  const ChatsView({super.key});
  @override
  Widget build(BuildContext context) {
    return BackgroundThemeWidget(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: CustomPullToRefresh(
            onRefresh:
                () async =>
                    await context.read<ChatsCubit>().getChats(isRefresh: true),
            child: Column(
              children: [
                const Gap(20),
                ChatsHeaderSection(),
                const Gap(20),
                Expanded(
                  child: BlocBuilder<ChatsCubit, ChatsState>(
                    builder: (context, state) {
                      if (state is ChatsLoading) {
                        return const CustomLoadingIndicator();
                      }
                      if (state is ChatsError) {
                        return Center(child: Text(state.message));
                      }
                      if (state is ChatsSuccessloaded) {
                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: state.chats.length + 1,
                          itemBuilder: (BuildContext context, int index) {
                            if (index == state.chats.length) {
                              return const SizedBox.shrink();
                            }
                            final user = state.chats[index];

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Hero(
                                tag: user.id,
                                child: Container(
                                  height: 52,
                                  width: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.bgColor2,
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          (user.imageUrl != null &&
                                                  user.imageUrl!.isNotEmpty)
                                              ? user.imageUrl!
                                              : AppImages.defaultUserImg,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) =>
                                              const CustomLoadingIndicator(),
                                      errorWidget:
                                          (context, url, error) =>
                                              const Icon(Icons.person),
                                      maxWidthDiskCache: 200,
                                      maxHeightDiskCache: 200,
                                    ),
                                  ),
                                ),
                              ),

                              title: Text(
                                user.name,
                                style: Theme.of(
                                  context,
                                ).textTheme.labelLarge!.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text(
                                user.lastMessage ?? 'tap to start chatting',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,

                                style: Theme.of(
                                  context,
                                ).textTheme.labelSmall!.copyWith(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: AppColors.grey6,
                                  height: 1.8,
                                ),
                              ),
                              trailing: Image.asset(
                                AppImages.sendIcon,
                                width: 20,
                                height: 20,
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.75,
                                ),
                              ),

                              onTap:
                                  () => Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pushNamed(
                                    AppRoutes.chatDetailsViewRoute,
                                    arguments: user,
                                  ),
                            );
                          },
                          separatorBuilder:
                              (_, __) =>
                                  const Divider(color: AppColors.black12),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
