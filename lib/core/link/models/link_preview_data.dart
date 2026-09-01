class LinkPreviewData {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
  final String domain;

  const LinkPreviewData({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    required this.domain,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasContent => (title != null && title!.isNotEmpty) || hasImage;

  factory LinkPreviewData.fromCacheJson(Map<String, dynamic> json) {
    return LinkPreviewData(
      url: json['url'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      siteName: json['siteName'] as String?,
      domain: (json['domain'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'url': url,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'siteName': siteName,
    'domain': domain,
  };
}
