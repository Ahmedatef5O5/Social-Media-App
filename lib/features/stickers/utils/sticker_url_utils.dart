class StickerUrlUtils {
  StickerUrlUtils._();

  static String staticPreviewUrl(String imageUrl, {required bool isAnimated}) {
    if (!isAnimated || !imageUrl.contains('/upload/')) return imageUrl;
    if (imageUrl.contains('pg_1')) return imageUrl; // already a preview
    return imageUrl.replaceFirst('/upload/', '/upload/pg_1,');
  }
}
