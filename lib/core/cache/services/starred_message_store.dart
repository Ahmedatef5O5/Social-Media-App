import 'package:hive_flutter/adapters.dart';
import '../constants/hive_box_names.dart';

class StarredMessagesStore {
  StarredMessagesStore._();
  static final StarredMessagesStore instance = StarredMessagesStore._();

  Box<bool>? _box;

  Future<Box<bool>> _openBox() async {
    return _box ??= await Hive.openBox<bool>(HiveBoxNames.starredMessages);
  }

  String _key(String currentUserId, String messageId) =>
      '${currentUserId}_$messageId';

  Future<bool> isStarred({
    required String currentUserId,
    required String messageId,
  }) async {
    final box = await _openBox();
    return box.get(_key(currentUserId, messageId), defaultValue: false)!;
  }

  Future<bool> toggleStar({
    required String currentUserId,
    required String messageId,
  }) async {
    final box = await _openBox();
    final key = _key(currentUserId, messageId);
    final next = !(box.get(key, defaultValue: false)!);
    await box.put(key, next);
    return next;
  }

  Future<List<String>> getStarredMessageIds(String currentUserId) async {
    final box = await _openBox();
    final prefix = '${currentUserId}_';
    return box.keys
        .cast<String>()
        .where((k) => k.startsWith(prefix) && box.get(k) == true)
        .map((k) => k.substring(prefix.length))
        .toList();
  }
}
