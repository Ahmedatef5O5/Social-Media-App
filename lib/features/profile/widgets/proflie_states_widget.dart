import 'package:flutter/material.dart';
import '../models/profile_stats_model.dart';
import '../utils/profile_ui_tokens.dart';
import 'state_item_widget.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class ProfileStatsWidget extends StatelessWidget {
  final ProfileStatsModel stats;
  const ProfileStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileUiTokens.of(context);

    final items = <({String label, String value})>[
      (label: context.l10n.posts, value: stats.postsCount.toString()),
      (label: context.l10n.media, value: stats.mediaCount.toString()),
      (
        label: context.l10n.followers,
        value: _formatNumber(stats.followersCount),
      ),
      (
        label: context.l10n.following,
        value: _formatNumber(stats.followingCount),
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: ProfileUiTokens.screenPadding,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(ProfileUiTokens.cardRadius),
        border: Border.all(color: tokens.outline),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Container(
                decoration:
                    i == 0
                        ? null
                        : BoxDecoration(
                          border: Border(
                            left: BorderSide(color: tokens.outline),
                          ),
                        ),
                child: StatItemWidget(
                  label: items[i].label,
                  value: items[i].value,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}k';
    return number.toString();
  }
}
