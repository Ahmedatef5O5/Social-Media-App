import 'new_chat_list_item.dart';

sealed class NewChatRow {
  const NewChatRow();
}

class NewChatSectionHeaderRow extends NewChatRow {
  final String title;
  const NewChatSectionHeaderRow(this.title);
}

class NewChatItemRow extends NewChatRow {
  final NewChatListItem item;
  final bool isBlocked;
  const NewChatItemRow(this.item, {this.isBlocked = false});
}
