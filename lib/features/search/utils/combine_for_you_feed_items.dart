import '../../posts/model/post_model.dart';
import '../../reels/model/reel_model.dart';
import '../model/injection_plan_entry.dart';
import '../widgets/for_you_feed_item.dart';

List<ForYouFeedItem> combineForYouFeedItems({
  required List<PostModel> rankedPosts,
  required List<InjectionPlanEntry> plan,
  required List<ReelModel> reelsPool,
  required bool showSuggestedAccounts,
}) {
  final items = <ForYouFeedItem>[];
  if (showSuggestedAccounts) {
    items.add(const ForYouFeedItem.suggestedAccounts());
  }

  var planCursor = 0;
  var reelOffset = 0;

  for (var i = 0; i < rankedPosts.length; i++) {
    items.add(ForYouFeedItem.post(rankedPosts[i]));

    if (planCursor < plan.length &&
        (i + 1) == plan[planCursor].afterPostIndex) {
      final entry = plan[planCursor];
      final remaining = reelsPool.length - reelOffset;
      if (remaining >= 2) {
        final take = entry.reelsCount.clamp(1, remaining);
        items.add(ForYouFeedItem.reelsGrid(reelsPool, reelOffset, take));
        reelOffset += take;
      }
      planCursor++;
    }
  }
  return items;
}
