import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_images.dart';
import '../cubits/reels_feed_cubit/reels_feed_cubit.dart';
import '../models/reel_model.dart';
import '../services/reels_preferences_store.dart';
import '../views/reels_full_screen_view.dart';
import '../views/reels_onboarding_view.dart';
import 'reel_thumbnail_card.dart';

class ReelsHorizontalSection extends StatelessWidget {
  final List<ReelModel> reels;
  final int sectionIndex;
  const ReelsHorizontalSection({
    super.key,
    required this.reels,
    required this.sectionIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reels',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Image.asset(AppImages.reelsIcon, width: 24, height: 24),
            ],
          ),
        ),

        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: reels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final reel = reels[index];
              return ReelThumbnailCard(
                reel: reel,
                onTap: () async {
                  final reelsCubit = context.read<ReelsFeedCubit>();
                  final hasSeen =
                      await ReelsPreferencesStore.instance.hasSeenOnboarding();
                  if (!context.mounted) return;

                  if (!hasSeen) {
                    final categories = await Navigator.of(
                      context,
                      rootNavigator: true,
                    ).push<List<String>>(
                      MaterialPageRoute(
                        builder: (_) => const ReelsOnboardingView(),
                      ),
                    );
                    if (categories != null && context.mounted) {
                      reelsCubit.updatePreferredCategories(categories);
                    }
                  }

                  if (!context.mounted) return;

                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder:
                          (_) => BlocProvider.value(
                            value: reelsCubit,
                            child: ReelsFullScreenView(
                              sectionIndex: sectionIndex,
                              initialIndex: index,
                            ),
                          ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
