import '../../group_chats/models/group_model.dart';

class SharedGroupItem {
  final GroupModel group;
  final int membersCount;

  const SharedGroupItem({required this.group, required this.membersCount});

  factory SharedGroupItem.fromMap(Map<String, dynamic> map) {
    return SharedGroupItem(
      group: GroupModel.fromMap(map),
      membersCount: (map['members_count'] as num?)?.toInt() ?? 0,
    );
  }
}
