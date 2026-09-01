/// Generic reconciliation layer for chat message lists.
///
/// Keeps identity, deduplication, merging, snapshots, updates, and removals
/// consistent across Single Chat and Group Chat.
library;

/// Returns the stable identity key for a message.
///
/// Messages with a clientMessageId are matched by that ID.
/// Legacy messages without one are matched by their server ID.
String correlationKeyFor({
  required String id,
  required String? clientMessageId,
}) {
  if (clientMessageId != null && clientMessageId.isNotEmpty) {
    return 'cid:$clientMessageId';
  }

  return 'sid:$id';
}

/// Result returned after reconciling a full snapshot.
class SnapshotReconciliation<T> {
  final List<T> messages;
  final Set<String> stillUnconfirmed;

  const SnapshotReconciliation({
    required this.messages,
    required this.stillUnconfirmed,
  });
}

class MessageReconciler<T> {
  final String Function(T message) idOf;
  final String? Function(T message) clientMessageIdOf;
  final DateTime Function(T message) createdAtOf;

  /// Merges two representations of the same logical message.
  final T Function(T existing, T incoming) merge;

  const MessageReconciler({
    required this.idOf,
    required this.clientMessageIdOf,
    required this.createdAtOf,
    required this.merge,
  });

  String _keyOf(T message) {
    return correlationKeyFor(
      id: idOf(message),
      clientMessageId: clientMessageIdOf(message),
    );
  }

  /// Sorts messages newest first using a stable identity tie-breaker.
  List<T> sortMessages(List<T> messages) {
    final list = List<T>.from(messages);

    list.sort((a, b) {
      final byTime = createdAtOf(b).compareTo(createdAtOf(a));

      if (byTime != 0) {
        return byTime;
      }

      return _keyOf(b).compareTo(_keyOf(a));
    });

    return list;
  }

  /// Removes duplicate logical messages from an existing list.
  List<T> dedupe(List<T> current) {
    final byKey = <String, T>{};

    for (final message in current) {
      final key = _keyOf(message);
      final existing = byKey[key];

      byKey[key] = existing == null ? message : merge(existing, message);
    }

    return sortMessages(byKey.values.toList());
  }

  /// Adds a new optimistic message if it does not already exist.
  List<T> applyOptimistic(List<T> current, T message) {
    final key = _keyOf(message);

    if (current.any((m) => _keyOf(m) == key)) {
      return current;
    }

    return sortMessages([...current, message]);
  }

  /// Adds or merges a single incoming message.
  List<T> applyPointEvent(List<T> current, T incoming) {
    final key = _keyOf(incoming);
    final index = current.indexWhere((m) => _keyOf(m) == key);

    if (index == -1) {
      return sortMessages([...current, incoming]);
    }

    final updated = List<T>.from(current);

    updated[index] = merge(updated[index], incoming);

    return sortMessages(updated);
  }

  /// Reconciles a complete snapshot with the current list.
  ///
  /// Protected messages survive temporarily when they are not yet confirmed
  /// by the incoming snapshot.
  SnapshotReconciliation<T> applySnapshot(
    List<T> current, {
    required List<T> snapshot,
    required Set<String> protectedKeys,
  }) {
    final byKey = <String, T>{
      for (final message in snapshot) _keyOf(message): message,
    };

    final result = <T>[];
    final stillUnconfirmed = <String>{};

    for (final existing in current) {
      final key = _keyOf(existing);
      final incoming = byKey[key];

      if (incoming != null) {
        result.add(merge(existing, incoming));
        continue;
      }

      if (protectedKeys.contains(key)) {
        result.add(existing);
        stillUnconfirmed.add(key);
      }
    }

    final knownKeys = current.map(_keyOf).toSet();

    for (final entry in byKey.entries) {
      if (!knownKeys.contains(entry.key)) {
        result.add(entry.value);
      }
    }

    return SnapshotReconciliation(
      messages: sortMessages(result),
      stillUnconfirmed: stillUnconfirmed,
    );
  }

  /// Applies non-identity updates such as reactions or mentions.
  List<T> applyFieldUpdate(List<T> current, T Function(T message) updater) {
    return sortMessages(current.map(updater).toList());
  }

  /// Removes a message using its current ID.
  List<T> removeById(List<T> current, String id) {
    return current.where((message) => idOf(message) != id).toList();
  }

  /// Removes a message using its logical identity.
  List<T> applyRemoval(
    List<T> current, {
    required String id,
    String? clientMessageId,
  }) {
    final key = correlationKeyFor(id: id, clientMessageId: clientMessageId);

    return current.where((message) => _keyOf(message) != key).toList();
  }
}
