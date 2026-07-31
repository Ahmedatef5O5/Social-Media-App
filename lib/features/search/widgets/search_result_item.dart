import 'package:flutter/material.dart';
import '../../posts/cubit/posts_cubit/posts_cubit.dart';
import '../../posts/widgets/post_item_widget.dart';
import 'for_you_feed_item.dart';
import 'for_you_reels_grid_section.dart';
import 'suggested_accounts_section.dart';

class SearchResultItem extends StatelessWidget {
  const SearchResultItem({
    super.key,
    required this.context,
    required this.item,
    required this.postsCubit,
  });

  final BuildContext context;
  final ForYouFeedItem item;
  final PostsCubit postsCubit;

  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case ForYouItemType.suggestedAccounts:
        return const SuggestedAccountsSection();
      case ForYouItemType.post:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),

          child: PostItemWidget(
            key: ValueKey(item.post!.id),
            currPost: item.post!,
            postsCubit: postsCubit,
          ),
        );
      case ForYouItemType.reelsGrid:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ForYouReelsGridSection(
            reelsPool: item.reelsPool!,
            startIndex: item.reelsStartIndex!,
            count: item.reelsCount!,
          ),
        );
    }
  }
}
