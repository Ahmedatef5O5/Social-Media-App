import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_media_app/core/cache/services/local_snapshot_store.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import '../models/sticker_model.dart';
import '../models/sticker_pack_model.dart';
import '../models/sticker_pack_privacy.dart';

class StickersRepository {
  StickersRepository._();
  static final StickersRepository instance = StickersRepository._();

  static const String _downloadedPacksKey = 'downloaded_sticker_packs';

  final _client = Supabase.instance.client;

  Future<List<StickerPackModel>> fetchPacks() async {
    final response = await _client
        .from(SupabaseConstants.stickerPacks)
        .select()
        .order(StickerPackColumns.sortOrder);

    return (response as List)
        .map((e) => StickerPackModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StickerModel>> fetchStickers(String packId) async {
    final response = await _client
        .from(SupabaseConstants.stickers)
        .select()
        .eq(StickerColumns.packId, packId)
        .order(StickerColumns.sortOrder);

    return (response as List)
        .map((e) => StickerModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> getDownloadedPackIds() async {
    final rows = LocalSnapshotStore.instance.readList(_downloadedPacksKey);
    return rows.map((r) => r['id'] as String).toSet();
  }

  Future<void> markPackDownloaded(String packId) async {
    final current = await getDownloadedPackIds();
    current.add(packId);
    await LocalSnapshotStore.instance.saveList(
      _downloadedPacksKey,
      current.map((id) => {'id': id}).toList(),
    );
  }

  Future<void> removeDownloadedPack(String packId) async {
    final current = await getDownloadedPackIds();
    current.remove(packId);
    await LocalSnapshotStore.instance.saveList(
      _downloadedPacksKey,
      current.map((id) => {'id': id}).toList(),
    );
  }

  Future<StickerPackModel> createUserPack({
    required String title,
    required StickerPackPrivacy privacy,
    required List<Map<String, dynamic>> stickers,
    required Set<String> friendIds,
  }) async {
    final response = await _client.rpc(
      SupabaseConstants.createUserStickerPackRpc,
      params: {
        'p_title': title,
        'p_privacy_level': privacy.dbValue,
        'p_stickers': stickers,
        'p_friend_ids': friendIds.isEmpty ? null : friendIds.toList(),
      },
    );
    return StickerPackModel.fromMap(response as Map<String, dynamic>);
  }

  Future<List<StickerPackModel>> fetchMyPacks() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(SupabaseConstants.stickerPacks)
        .select()
        .eq(StickerPackColumns.ownerId, userId)
        .order(StickerPackColumns.createdAt);

    return (response as List)
        .map((e) => StickerPackModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteMyPack(String packId) async {
    await _client
        .from(SupabaseConstants.stickerPacks)
        .delete()
        .eq(StickerPackColumns.id, packId);
  }
}
