abstract class MediaCacheRepository {
  void initialize();

  Future<String?> resolveLocalPath(
    String secureUrl, {
    void Function(double progress)? onProgress,
  });

  bool isAvailableOffline(String secureUrl);

  String? resolveLocalPathSync(String secureUrl);

  Future<int> runEvictionSweep();
}
