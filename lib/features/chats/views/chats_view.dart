import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/constants/app_images.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import 'package:social_media_app/core/themes/background_theme_widget.dart';
import 'package:social_media_app/core/widgets/custom_loading_indicator.dart';
import 'package:social_media_app/features/chats/cubit/chats_cubit.dart';
import '../widgets/chats_header_section.dart';

class ChatsView extends StatelessWidget {
  const ChatsView({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatsCubit()..getChats(),
      child: BackgroundThemeWidget(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
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
                          itemCount: state.chats.length,
                          itemBuilder: (BuildContext context, int index) {
                            final user = state.chats[index];

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                height: 44,
                                width: 44,
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

                              title: Text(
                                user.name,
                                style: Theme.of(
                                  context,
                                ).textTheme.labelLarge!.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text('tap to start chatting'),
                              onTap: () {},
                            );
                          },
                          separatorBuilder:
                              (_, __) => const Divider(
                                height: 1,
                                color: AppColors.black12,
                              ),
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
