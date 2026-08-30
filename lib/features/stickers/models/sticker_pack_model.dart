import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'sticker_pack_privacy.dart';

class StickerPackModel {
  final String id;
  final String title;
  final String coverUrl;
  final int stickerCount;
  final int totalSizeBytes;
  final int sortOrder;
  final String? ownerId;
  final StickerPackPrivacy privacyLevel;

  const StickerPackModel({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.stickerCount,
    this.totalSizeBytes = 0,
    required this.sortOrder,
    this.ownerId,
    this.privacyLevel = StickerPackPrivacy.public,
  });

  bool get isUserGenerated => ownerId != null;

  factory StickerPackModel.fromMap(Map<String, dynamic> map) {
    return StickerPackModel(
      id: map[StickerPackColumns.id] as String,
      title: map[StickerPackColumns.title] as String,
      coverUrl: map[StickerPackColumns.coverUrl] as String,
      stickerCount: map[StickerPackColumns.stickerCount] as int? ?? 0,
      totalSizeBytes: map[StickerPackColumns.totalSizeBytes] as int? ?? 0,
      sortOrder: map[StickerPackColumns.sortOrder] as int? ?? 0,
      ownerId: map[StickerPackColumns.ownerId] as String?,
      privacyLevel: StickerPackPrivacyX.fromDbValue(
        map[StickerPackColumns.privacyLevel] as String?,
      ),
    );
  }
}
