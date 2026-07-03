// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_media_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedMediaModelAdapter extends TypeAdapter<CachedMediaModel> {
  @override
  final int typeId = 0;

  @override
  CachedMediaModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedMediaModel(
      secureUrl: fields[0] as String,
      mediaType: fields[1] as CachedMediaType,
      featureFolder: fields[2] as String,
      cachedAt: fields[4] as DateTime,
      lastAccessedAt: fields[5] as DateTime,
      localFilePath: fields[3] as String?,
      sizeInBytes: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedMediaModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.secureUrl)
      ..writeByte(1)
      ..write(obj.mediaType)
      ..writeByte(2)
      ..write(obj.featureFolder)
      ..writeByte(3)
      ..write(obj.localFilePath)
      ..writeByte(4)
      ..write(obj.cachedAt)
      ..writeByte(5)
      ..write(obj.lastAccessedAt)
      ..writeByte(6)
      ..write(obj.sizeInBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedMediaModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedMediaTypeAdapter extends TypeAdapter<CachedMediaType> {
  @override
  final int typeId = 1;

  @override
  CachedMediaType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CachedMediaType.image;
      case 1:
        return CachedMediaType.video;
      case 2:
        return CachedMediaType.audio;
      case 3:
        return CachedMediaType.raw;
      default:
        return CachedMediaType.image;
    }
  }

  @override
  void write(BinaryWriter writer, CachedMediaType obj) {
    switch (obj) {
      case CachedMediaType.image:
        writer.writeByte(0);
        break;
      case CachedMediaType.video:
        writer.writeByte(1);
        break;
      case CachedMediaType.audio:
        writer.writeByte(2);
        break;
      case CachedMediaType.raw:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedMediaTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
