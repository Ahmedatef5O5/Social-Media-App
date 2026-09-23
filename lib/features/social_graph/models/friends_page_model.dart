import 'friend_list_item_model.dart';

class FriendsPage {
  final List<FriendListItemModel> items;

  final int? totalCount;

  const FriendsPage({required this.items, this.totalCount});
}
