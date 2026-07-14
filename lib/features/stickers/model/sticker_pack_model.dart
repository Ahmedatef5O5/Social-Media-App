import 'package:social_media_app/core/utilities/supabase_constants.dart';

class StickerPackModel {
  final String id;
  final String title;
  final String coverUrl;
  final int stickerCount;
  final int sortOrder;

  const StickerPackModel({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.stickerCount,
    required this.sortOrder,
  });

  factory StickerPackModel.fromMap(Map<String, dynamic> map) {
    return StickerPackModel(
      id: map[StickerPackColumns.id] as String,
      title: map[StickerPackColumns.title] as String,
      coverUrl: map[StickerPackColumns.coverUrl] as String,
      stickerCount: map[StickerPackColumns.stickerCount] as int? ?? 0,
      sortOrder: map[StickerPackColumns.sortOrder] as int? ?? 0,
    );
  }
}
