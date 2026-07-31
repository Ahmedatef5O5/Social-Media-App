import '../../posts/model/post_model.dart';
import '../../reels/model/reel_model.dart';

enum ForYouItemType { suggestedAccounts, post, reelsGrid }

class ForYouFeedItem {
  final ForYouItemType type;
  final PostModel? post;
  final List<ReelModel>? reelsPool;
  final int? reelsStartIndex;
  final int? reelsCount;

  const ForYouFeedItem.suggestedAccounts()
    : type = ForYouItemType.suggestedAccounts,
      post = null,
      reelsPool = null,
      reelsStartIndex = null,
      reelsCount = null;

  const ForYouFeedItem.post(this.post)
    : type = ForYouItemType.post,
      reelsPool = null,
      reelsStartIndex = null,
      reelsCount = null;

  const ForYouFeedItem.reelsGrid(
    this.reelsPool,
    this.reelsStartIndex,
    this.reelsCount,
  ) : type = ForYouItemType.reelsGrid,
      post = null;
}
