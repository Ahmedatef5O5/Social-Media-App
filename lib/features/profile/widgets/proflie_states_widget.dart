import 'package:flutter/material.dart';
import 'package:social_media_app/core/themes/app_colors.dart';
import '../models/profile_stats_model.dart';
import 'state_item_widget.dart';

class ProfileStatsWidget extends StatelessWidget {
  final ProfileStatsModel stats;
  const ProfileStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,

        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.grey4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          StatItemWidget(label: 'Posts', value: stats.postsCount.toString()),

          _buildDivider(),
          StatItemWidget(label: 'Photos', value: stats.photosCount.toString()),

          _buildDivider(),
          StatItemWidget(
            label: 'Followers',
            value: _formatNumber(stats.followersCount),
          ),

          _buildDivider(),
          StatItemWidget(
            label: 'Following',
            value: _formatNumber(stats.followingCount),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 32, width: 1.2, color: AppColors.grey4);
  }

  String _formatNumber(int number) {
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}k';
    return number.toString();
  }
}
