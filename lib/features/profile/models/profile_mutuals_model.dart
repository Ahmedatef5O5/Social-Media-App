class ProfileMutualFriend {
  final String id;
  final String name;
  final String? imageUrl;

  const ProfileMutualFriend({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory ProfileMutualFriend.fromMap(Map<String, dynamic> map) {
    return ProfileMutualFriend(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      imageUrl: map['image_url'] as String?,
    );
  }
}

class ProfileMutualGroup {
  final String id;
  final String name;

  const ProfileMutualGroup({required this.id, required this.name});

  factory ProfileMutualGroup.fromMap(Map<String, dynamic> map) {
    return ProfileMutualGroup(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
    );
  }
}

class ProfileMutualsModel {
  final int friendsCount;
  final List<ProfileMutualFriend> friends;
  final int groupsCount;
  final List<ProfileMutualGroup> groups;

  const ProfileMutualsModel({
    required this.friendsCount,
    required this.friends,
    required this.groupsCount,
    required this.groups,
  });

  static const ProfileMutualsModel empty = ProfileMutualsModel(
    friendsCount: 0,
    friends: [],
    groupsCount: 0,
    groups: [],
  );

  bool get isEmpty => friendsCount == 0 && groupsCount == 0;

  factory ProfileMutualsModel.fromMap(Map<String, dynamic> map) {
    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) parser) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((item) => parser(Map<String, dynamic>.from(item)))
          .toList();
    }

    return ProfileMutualsModel(
      friendsCount: (map['mutual_friends_count'] as num?)?.toInt() ?? 0,
      friends: parseList(
        map['mutual_friends_preview'],
        ProfileMutualFriend.fromMap,
      ),
      groupsCount: (map['mutual_groups_count'] as num?)?.toInt() ?? 0,
      groups: parseList(
        map['mutual_groups_preview'],
        ProfileMutualGroup.fromMap,
      ),
    );
  }
}
