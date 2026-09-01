import '../../../core/utilities/supabase_constants.dart';
import '../../auth/data/models/user_data.dart';

class BlockedUserItemModel {
  final UserData user;
  final DateTime blockedAt;

  const BlockedUserItemModel({required this.user, required this.blockedAt});

  factory BlockedUserItemModel.fromMap(Map<String, dynamic> map) {
    final userMap = map['blocked_user'] as Map<String, dynamic>? ?? const {};
    return BlockedUserItemModel(
      user: UserData.fromMap(userMap),
      blockedAt:
          map[BlockedUsersColumns.createdAt] != null
              ? DateTime.parse(map[BlockedUsersColumns.createdAt].toString())
              : DateTime.now(),
    );
  }
}
