import 'package:flutter/material.dart';
import '../../../core/constants/app_images.dart';
import '../model/reel_model.dart';
import '../views/reels_full_screen_view.dart';
import 'reel_thumbnail_card.dart';

class ReelsHorizontalSection extends StatelessWidget {
  final List<ReelModel> reels;
  const ReelsHorizontalSection({super.key, required this.reels});

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
                onTap:
                    () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder:
                            (_) =>
                            // TestPlayerPage(),
                            ReelsFullScreenView(
                              reels: reels,
                              initialIndex: index,
                            ),
                      ),
                    ),
              );
            },
          ),
        ),
      ],
    );
  }
}
