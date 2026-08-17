import 'package:hive/hive.dart';
import '../../../core/cache/constants/hive_type_ids.dart';
part 'ai_chat_session.g.dart';

@HiveType(typeId: HiveTypeIds.aiChatSession)
class AiChatSession extends HiveObject {
  AiChatSession({
    required this.id,
    required this.title,
    required this.titleIsAuto,
    this.activeProvider,
    this.activeModel,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.messageCount,
    required this.createdAt,
    required this.updatedAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final bool titleIsAuto;

  @HiveField(3)
  final String? activeProvider;

  @HiveField(4)
  final String? activeModel;

  @HiveField(5)
  final String? lastMessagePreview;

  @HiveField(6)
  final DateTime? lastMessageAt;

  @HiveField(7)
  final int messageCount;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  factory AiChatSession.fromJson(Map<String, dynamic> json) => AiChatSession(
    id: json['id'] as String,
    title: json['title'] as String,
    titleIsAuto: json['title_is_auto'] as bool? ?? true,
    activeProvider: json['active_provider'] as String?,
    activeModel: json['active_model'] as String?,
    lastMessagePreview: json['last_message_preview'] as String?,
    lastMessageAt:
        json['last_message_at'] == null
            ? null
            : DateTime.parse(json['last_message_at'] as String),
    messageCount: json['message_count'] as int? ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'title_is_auto': titleIsAuto,
    'active_provider': activeProvider,
    'active_model': activeModel,
    'last_message_preview': lastMessagePreview,
    'last_message_at': lastMessageAt?.toIso8601String(),
    'message_count': messageCount,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  AiChatSession copyWith({
    String? title,
    bool? titleIsAuto,
    String? activeProvider,
    String? activeModel,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int? messageCount,
    DateTime? updatedAt,
  }) {
    return AiChatSession(
      id: id,
      title: title ?? this.title,
      titleIsAuto: titleIsAuto ?? this.titleIsAuto,
      activeProvider: activeProvider ?? this.activeProvider,
      activeModel: activeModel ?? this.activeModel,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messageCount: messageCount ?? this.messageCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
