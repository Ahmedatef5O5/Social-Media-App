import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../../core/design/tokens/typography.dart';
import '../../../core/helpers/formatted_date.dart';
import '../../../core/presence/widgets/presence_avatar_widget.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/custom_loading_indicator.dart';
import '../cubits/story_views_cubit/story_views_cubit.dart';
import '../models/story_viewer_model.dart';

class StoryViewsBottomSheet extends StatelessWidget {
  const StoryViewsBottomSheet({super.key});

  void _navigateToProfile(BuildContext context, StoryViewerModel viewer) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.profileViewRoute, arguments: viewer.viewerId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: GestureDetector(
        onTap: () {},
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Gap(10),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Gap(15),
                  BlocBuilder<StoryViewsCubit, StoryViewsState>(
                    builder: (context, state) {
                      final count =
                          state is StoryViewsLoaded ? state.viewers.length : 0;
                      return Text(
                        '$count Views',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const Gap(10),
                  Expanded(
                    child: BlocBuilder<StoryViewsCubit, StoryViewsState>(
                      builder: (context, state) {
                        return switch (state) {
                          StoryViewsLoading() => const Center(
                            child: CustomLoadingIndicator(),
                          ),
                          StoryViewsError() => const Center(
                            child: Text(
                              'Couldn\'t load views.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          StoryViewsLoaded(:final viewers)
                              when viewers.isEmpty =>
                            const Center(
                              child: Text(
                                'No views yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          StoryViewsLoaded(:final viewers) => ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: viewers.length,
                            itemBuilder: (context, index) {
                              final viewer = viewers[index];
                              return ListTile(
                                leading: GestureDetector(
                                  onTap:
                                      () => _navigateToProfile(context, viewer),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      PresenceAvatarWidget(
                                        userId: viewer.viewerId,
                                        avatarSize: 45,
                                        showDot: true,
                                        showBorder: true,
                                        child: AppAvatar(
                                          imageUrl: viewer.userImageUrl,
                                          size: 45,
                                        ),
                                      ),
                                      if (viewer.hasReacted)
                                        Positioned(
                                          bottom: -4,
                                          right: -4,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surface,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.1),
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              viewer.reaction!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                inherit: false,
                                                fontWeight: FontWeight.normal,
                                                fontFamilyFallback:
                                                    AppTypography
                                                        .emojiFontFallback,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                title: GestureDetector(
                                  onTap:
                                      () => _navigateToProfile(context, viewer),
                                  child: Text(
                                    viewer.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                subtitle: Text(
                                  FormattedDate.getFormattedDate(
                                    viewer.viewedAt.toIso8601String(),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        };
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
