import 'package:social_media_app/core/utilities/supabase_constants.dart';

class StickerModel {
  final String id;
  final String packId;
  final String imageUrl;
  final int sortOrder;
  final bool isAnimated;
  final String? format;

  const StickerModel({
    required this.id,
    required this.packId,
    required this.imageUrl,
    required this.sortOrder,
    this.isAnimated = false,
    this.format,
  });

  factory StickerModel.fromMap(Map<String, dynamic> map) {
    return StickerModel(
      id: map[StickerColumns.id] as String,
      packId: map[StickerColumns.packId] as String,
      imageUrl: map[StickerColumns.imageUrl] as String,
      sortOrder: map[StickerColumns.sortOrder] as int? ?? 0,
      isAnimated: map[StickerColumns.isAnimated] as bool? ?? false,
      format: map[StickerColumns.format] as String?,
    );
  }
}
