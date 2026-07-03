import 'package:hive/hive.dart';
import '../constants/hive_type_ids.dart';
part 'cached_media_model.g.dart';

@HiveType(typeId: HiveTypeIds.cachedMediaType)
enum CachedMediaType {
  @HiveField(0)
  image,
  @HiveField(1)
  video,
  @HiveField(2)
  audio,
  @HiveField(3)
  raw,
}

@HiveType(typeId: HiveTypeIds.cachedMediaModel)
class CachedMediaModel extends HiveObject {
  @HiveField(0)
  final String secureUrl;

  @HiveField(1)
  final CachedMediaType mediaType;

  @HiveField(2)
  final String featureFolder;

  @HiveField(3)
  final String? localFilePath;

  @HiveField(4)
  final DateTime cachedAt;

  @HiveField(5)
  DateTime lastAccessedAt;

  @HiveField(6)
  final int? sizeInBytes;

  CachedMediaModel({
    required this.secureUrl,
    required this.mediaType,
    required this.featureFolder,
    required this.cachedAt,
    required this.lastAccessedAt,
    this.localFilePath,
    this.sizeInBytes,
  });
}
