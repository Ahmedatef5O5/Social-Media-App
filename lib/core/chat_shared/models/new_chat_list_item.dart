import '../../../features/auth/data/models/user_data.dart';
import '../../../features/group_chats/models/group_model.dart';

class NewChatListItem {
  final UserData? person;
  final GroupModel? group;

  const NewChatListItem._({this.person, this.group});

  factory NewChatListItem.person(UserData user) =>
      NewChatListItem._(person: user);

  factory NewChatListItem.group(GroupModel group) =>
      NewChatListItem._(group: group);

  bool get isGroup => group != null;
  String get id => isGroup ? group!.id : person!.id;
  String get displayName => isGroup ? group!.name : person!.name;
}
