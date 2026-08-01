class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;
  final String resourceType;
  final int? width;
  final int? height;

  CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.resourceType,
    this.width,
    this.height,
  });

  /// Null when dimensions aren't available (e.g. raw/document uploads)
  double? get aspectRatio =>
      (width != null && height != null && height! > 0)
          ? width! / height!
          : null;
}
