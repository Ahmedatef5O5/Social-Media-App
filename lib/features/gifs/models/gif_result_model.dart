class GifResult {
  final String id;
  final String previewUrl;
  final String sendUrl;
  final double aspectRatio;

  const GifResult({
    required this.id,
    required this.previewUrl,
    required this.sendUrl,
    required this.aspectRatio,
  });

  factory GifResult.fromGiphyJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>;
    final Map<String, dynamic> preview =
        (images['fixed_width_small'] ?? images['fixed_width'])
            as Map<String, dynamic>;
    final Map<String, dynamic> full =
        (images['fixed_height'] ?? images['original']) as Map<String, dynamic>;

    final width = double.tryParse('${full['width']}') ?? 1;
    final height = double.tryParse('${full['height']}') ?? 1;

    return GifResult(
      id: json['id'] as String,
      previewUrl: preview['url'] as String,
      sendUrl: full['url'] as String,
      aspectRatio: height == 0 ? 1 : width / height,
    );
  }
}
