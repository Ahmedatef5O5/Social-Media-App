import 'package:social_media_app/core/utilities/supabase_constants.dart';
import '../../../../core/presence/model/presence_privacy.dart';

class UserData {
  final String id;
  final String name;
  final String email;
  final String? userName;
  final String? title;
  final String? bio;
  final String? imageUrl;
  final String? backgroundImageUrl;
  final String? imagePublicId;
  final String? backgroundImagePublicId;
  final DateTime? lastSeen;
  final PresencePrivacy presencePrivacy;
  final List<String> presenceVisibleTo;
  final Map<String, String> socialLinks;

  const UserData({
    required this.id,
    required this.name,
    required this.email,
    this.userName,
    this.title,
    this.bio,
    this.imageUrl,
    this.backgroundImageUrl,
    this.imagePublicId,
    this.backgroundImagePublicId,
    this.lastSeen,
    this.presencePrivacy = PresencePrivacy.friends,
    this.presenceVisibleTo = const [],
    this.socialLinks = const {},
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
      'image_public_id': imagePublicId,
      'background_image_public_id': backgroundImagePublicId,
      UserColumns.lastSeen: lastSeen,
      UserColumns.presencePrivacy: presencePrivacy.value,
      UserColumns.presenceVisibleTo: presenceVisibleTo,
      UserColumns.socialLinks: socialLinks,
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
      imagePublicId: map['image_public_id'] as String?,
      backgroundImagePublicId: map['background_image_public_id'] as String?,
      lastSeen:
          map[UserColumns.lastSeen] != null
              ? DateTime.parse(map[UserColumns.lastSeen].toString())
              : null,
      presencePrivacy: PresencePrivacy.fromValue(
        map[UserColumns.presencePrivacy] as String?,
      ),
      presenceVisibleTo: List<String>.from(
        map[UserColumns.presenceVisibleTo] as List? ?? const [],
      ),
      socialLinks: Map<String, String>.from(
        (map[UserColumns.socialLinks] as Map?) ?? const {},
      ),
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'id': id,
    'name': name,
    'email': email,
    'username': userName,
    'title': title,
    'bio': bio,
    'image_url': imageUrl,
    'background_image_url': backgroundImageUrl,
    'image_public_id': imagePublicId,
    'background_image_public_id': backgroundImagePublicId,
    'last_seen': lastSeen?.toIso8601String(),
    'presence_privacy': presencePrivacy.value,
    'presence_visible_to': presenceVisibleTo,
    'social_links': socialLinks,
  };

  factory UserData.fromCacheJson(Map<String, dynamic> map) {
    return UserData(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      userName: map['username'] as String?,
      title: map['title'] as String?,
      bio: map['bio'] as String?,
      imageUrl: map['image_url'] as String?,
      backgroundImageUrl: map['background_image_url'] as String?,
      imagePublicId: map['image_public_id'] as String?,
      backgroundImagePublicId: map['background_image_public_id'] as String?,
      lastSeen:
          map['last_seen'] != null
              ? DateTime.parse(map['last_seen'] as String)
              : null,
      presencePrivacy: PresencePrivacy.fromValue(
        map['presence_privacy'] as String?,
      ),
      presenceVisibleTo: List<String>.from(
        map['presence_visible_to'] as List? ?? const [],
      ),
      socialLinks: Map<String, String>.from(
        (map['social_links'] as Map?) ?? const {},
      ),
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
    String? imagePublicId,
    String? backgroundImagePublicId,
    final DateTime? lastSeen,
    PresencePrivacy? presencePrivacy,
    List<String>? presenceVisibleTo,
    Map<String, String>? socialLinks,
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
      imagePublicId: imagePublicId ?? this.imagePublicId,
      backgroundImagePublicId:
          backgroundImagePublicId ?? this.backgroundImagePublicId,
      lastSeen: lastSeen ?? this.lastSeen,
      presencePrivacy: presencePrivacy ?? this.presencePrivacy,
      presenceVisibleTo: presenceVisibleTo ?? this.presenceVisibleTo,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }
}
