enum ConversationType { single, group }

class ConversationRef {
  final ConversationType type;
  final String id;
  const ConversationRef({required this.type, required this.id});

  String get storageKey => '${type.name}:$id';

  @override
  bool operator ==(Object other) =>
      other is ConversationRef && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}
