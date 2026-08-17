// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chat_message_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AiChatMessageRecordAdapter extends TypeAdapter<AiChatMessageRecord> {
  @override
  final int typeId = 5;

  @override
  AiChatMessageRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AiChatMessageRecord(
      id: fields[0] as String,
      sessionId: fields[1] as String,
      role: fields[2] as String,
      text: fields[3] as String,
      mediaType: fields[4] as String,
      mediaUrl: fields[5] as String?,
      fileName: fields[6] as String?,
      fileSizeBytes: fields[7] as int?,
      durationSeconds: fields[8] as int?,
      provider: fields[9] as String?,
      model: fields[10] as String?,
      degraded: fields[11] as bool,
      requestId: fields[12] as String?,
      status: fields[13] as String,
      createdAt: fields[14] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AiChatMessageRecord obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sessionId)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.text)
      ..writeByte(4)
      ..write(obj.mediaType)
      ..writeByte(5)
      ..write(obj.mediaUrl)
      ..writeByte(6)
      ..write(obj.fileName)
      ..writeByte(7)
      ..write(obj.fileSizeBytes)
      ..writeByte(8)
      ..write(obj.durationSeconds)
      ..writeByte(9)
      ..write(obj.provider)
      ..writeByte(10)
      ..write(obj.model)
      ..writeByte(11)
      ..write(obj.degraded)
      ..writeByte(12)
      ..write(obj.requestId)
      ..writeByte(13)
      ..write(obj.status)
      ..writeByte(14)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiChatMessageRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
