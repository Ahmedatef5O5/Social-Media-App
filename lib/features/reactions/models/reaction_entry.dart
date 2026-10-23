import 'package:social_media_app/core/localization/app_l10n.dart';

class ReactionEntry {
  final String userId;
  final String _userName;
  final String? userImageUrl;
  final DateTime? lastSeen;
  final String emoji;
  final String? createdAt;

  const ReactionEntry({
    required this.userId,
    required String userName,
    this.userImageUrl,
    this.lastSeen,
    required this.emoji,
    this.createdAt,
  }) : _userName = userName;

  bool get isDeletedAccount =>
      _userName.trim().toLowerCase() == 'deleted account' ||
      _userName.trim() == 'حساب محذوف';

  String get userName =>
      isDeletedAccount ? AppL10n.current.deletedAccount : _userName;
}
