import 'dart:convert';

class UserData {
  final String id;
  final String name;
  final String email;
  final String? title;
  final String? imageUrl;

  const UserData({
    required this.id,
    required this.name,
    required this.email,
    this.title,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'title': title,
      'imageUrl': imageUrl,
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String,
      title: map['title'] != null ? map['title'] as String? ?? '' : null,
      imageUrl:
          map['imageUrl'] != null ? map['imageUrl'] as String? ?? '' : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserData.fromJson(String source) =>
      UserData.fromMap(json.decode(source) as Map<String, dynamic>);
}
