class MediaCacheDownloadException implements Exception {
  const MediaCacheDownloadException(this.secureUrl, this.cause);

  final String secureUrl;
  final Object cause;

  @override
  String toString() =>
      'MediaCacheDownloadException: failed to cache "$secureUrl" — $cause';
}
