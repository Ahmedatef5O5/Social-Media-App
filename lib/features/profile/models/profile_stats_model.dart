class ProfileStatsModel {
  final int postsCount;
  final int mediaCount;
  final int followersCount;
  final int followingCount;

  const ProfileStatsModel({
    required this.postsCount,
    required this.mediaCount,
    required this.followersCount,
    required this.followingCount,
  });

  ProfileStatsModel copyWith({
    int? postsCount,
    int? mediaCount,
    int? followersCount,
    int? followingCount,
  }) {
    return ProfileStatsModel(
      postsCount: postsCount ?? this.postsCount,
      mediaCount: mediaCount ?? this.mediaCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'postsCount': postsCount,
      'mediaCount': mediaCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
    };
  }

  factory ProfileStatsModel.fromMap(Map<String, dynamic> map) {
    return ProfileStatsModel(
      postsCount: map['postsCount'] as int,
      mediaCount: map['mediaCount'] as int,
      followersCount: map['followersCount'] as int,
      followingCount: map['followingCount'] as int,
    );
  }

  // String toJson() => json.encode(toMap());

  // factory ProfileStatsModel.fromJson(String source) => ProfileStatsModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
