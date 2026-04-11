import 'package:social_media_app/core/utilities/supabase_constants.dart';

class UserData {
  final String id;
  final String name;
  final String email;
  final String? userName;
  final String? title;
  final String? bio;
  final String? imageUrl;
  final String? backgroundImageUrl;
  final DateTime? lastSeen;

  const UserData({
    required this.id,
    required this.name,
    required this.email,
    this.userName,
    this.title,
    this.bio,
    this.imageUrl,
    this.backgroundImageUrl,
    this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'username': userName,
      'title': title,
      'bio': bio,
      'image_url': imageUrl,
      'background_image_url': backgroundImageUrl,
      UserColumns.lastSeen: lastSeen,
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      userName:
          map['username'] != null ? map['username'] as String? ?? '' : null,
      title: map['title'] != null ? map['title'] as String? ?? '' : null,
      bio: map['bio'] != null ? map['bio'] as String? ?? '' : null,
      imageUrl:
          map['image_url'] != null ? map['image_url'] as String? ?? '' : null,
      backgroundImageUrl:
          map['background_image_url'] != null
              ? map['background_image_url'] as String? ?? ''
              : null,
      lastSeen:
          map[UserColumns.lastSeen] != null
              ? DateTime.parse(map[UserColumns.lastSeen].toString())
              : null,
    );
  }

  UserData copyWith({
    String? id,
    String? name,
    String? email,
    String? userName,
    String? title,
    String? bio,
    String? imageUrl,
    String? backgroundImageUrl,
    final DateTime? lastSeen,
  }) {
    return UserData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      userName: userName ?? this.userName,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
