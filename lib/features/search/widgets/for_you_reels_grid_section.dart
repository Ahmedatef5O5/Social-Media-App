import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../reels/models/reel_model.dart';
import '../../reels/views/reels_full_screen_view.dart';
import 'reel_grid_tile.dart';

class ForYouReelsGridSection extends StatelessWidget {
  final List<ReelModel> reelsPool;
  final int startIndex;
  final int count;

  const ForYouReelsGridSection({
    super.key,
    required this.reelsPool,
    required this.startIndex,
    required this.count,
  });

  void _openReel(BuildContext context, int localIndex) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder:
            (_) => ReelsFullScreenView(
              reels: reelsPool,
              initialIndex: startIndex + localIndex,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.movie_filter_rounded,
              size: 17,
              color: theme.primaryColor,
            ),
            const Gap(6),
            Text(
              'Reels for you',
              style: theme.textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Gap(8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 9 / 14,
          ),
          itemCount: count,
          itemBuilder: (context, i) {
            final reel = reelsPool[startIndex + i];
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ReelGridTile(
                key: ValueKey(reel.id),
                reel: reel,
                onTap: () => _openReel(context, i),
              ),
            );
          },
        ),
      ],
    );
  }
}
