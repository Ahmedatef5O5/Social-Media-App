// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chat_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AiChatSessionAdapter extends TypeAdapter<AiChatSession> {
  @override
  final int typeId = 4;

  @override
  AiChatSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AiChatSession(
      id: fields[0] as String,
      title: fields[1] as String,
      titleIsAuto: fields[2] as bool,
      activeProvider: fields[3] as String?,
      activeModel: fields[4] as String?,
      lastMessagePreview: fields[5] as String?,
      lastMessageAt: fields[6] as DateTime?,
      messageCount: fields[7] as int,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AiChatSession obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.titleIsAuto)
      ..writeByte(3)
      ..write(obj.activeProvider)
      ..writeByte(4)
      ..write(obj.activeModel)
      ..writeByte(5)
      ..write(obj.lastMessagePreview)
      ..writeByte(6)
      ..write(obj.lastMessageAt)
      ..writeByte(7)
      ..write(obj.messageCount)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiChatSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
