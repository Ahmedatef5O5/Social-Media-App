import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/messaging/message_reconciler.dart';
import 'package:social_media_app/features/single_chats/models/message_model.dart';

import '../../helpers/message_factory.dart';

/// PRIORITY: P0 — data corruption.
///
/// [MessageReconciler] is the single mutation boundary for every chat
/// message list in the app (`ChatDetailsCubit` and the group-chat cubit
/// both build one). Every optimistic send, every API ack, every Realtime
/// row, every disk snapshot and every reaction update passes through it.
///
/// A defect here is not a cosmetic bug: it duplicates messages, drops a
/// message the user believes was sent, or resurrects a deleted one. It is
/// also 100% pure logic with no I/O — which makes it both the highest-risk
/// and the cheapest thing in this codebase to test. That combination is
/// why it is the first file in this suite.
void main() {
  /// Mirrors the real merge policy configured in
  /// `ChatDetailsCubit._reconciler`: the incoming representation wins for
  /// content, EXCEPT reactions, which arrive on a separate stream and must
  /// not be clobbered by a snapshot that simply does not carry them.
  final reconciler = MessageReconciler<MessageModel>(
    idOf: (m) => m.id,
    clientMessageIdOf: (m) => m.clientMessageId,
    createdAtOf: (m) => m.createdAt,
    merge:
        (existing, incoming) => incoming.copyWith(
          reactions:
              incoming.reactions.isNotEmpty
                  ? incoming.reactions
                  : existing.reactions,
          reactionsCreatedAt:
              incoming.reactionsCreatedAt ?? existing.reactionsCreatedAt,
        ),
  );

  group('correlationKeyFor', () {
    test('prefers the client message id when present', () {
      expect(
        correlationKeyFor(id: 'server-1', clientMessageId: 'cid-1'),
        'cid:cid-1',
      );
    });

    test('falls back to the server id for legacy rows', () {
      expect(
        correlationKeyFor(id: 'server-1', clientMessageId: null),
        'sid:server-1',
      );
    });

    test('an EMPTY client id is treated as absent, not as a valid key', () {
      // A row written with `client_message_id = ''` instead of NULL must
      // not collide with every other empty-id row in the conversation.
      expect(
        correlationKeyFor(id: 'server-1', clientMessageId: ''),
        'sid:server-1',
      );
    });

    test('the same logical message keeps one key across id changes', () {
      // This is the entire point of the correlation id: the optimistic
      // message and the server row have DIFFERENT `id`s but the same key.
      final optimistic = correlationKeyFor(id: 'temp-x', clientMessageId: 'c1');
      final confirmed = correlationKeyFor(
        id: 'server-9',
        clientMessageId: 'c1',
      );
      expect(optimistic, confirmed);
    });
  });

  group('sortMessages', () {
    test('orders newest first', () {
      final sorted = reconciler.sortMessages([
        message(id: 'a', createdAt: at(10)),
        message(id: 'b', createdAt: at(30)),
        message(id: 'c', createdAt: at(20)),
      ]);

      expect(sorted.ids, ['b', 'c', 'a']);
    });

    test('identical timestamps fall back to the identity key, so the order '
        'is stable across rebuilds instead of arbitrary', () {
      final input = [
        message(id: 'a', createdAt: at(5)),
        message(id: 'b', createdAt: at(5)),
        message(id: 'c', createdAt: at(5)),
      ];

      final first = reconciler.sortMessages(input).ids;
      final second = reconciler.sortMessages(input.reversed.toList()).ids;

      expect(first, second);
      expect(first, ['c', 'b', 'a']); // descending by 'sid:<id>'
    });

    test('does not mutate the caller list', () {
      final original = [
        message(id: 'a', createdAt: at(1)),
        message(id: 'b', createdAt: at(2)),
      ];
      reconciler.sortMessages(original);
      expect(original.ids, ['a', 'b']);
    });
  });

  group('dedupe', () {
    test('collapses two representations of the same client message', () {
      final result = reconciler.dedupe([
        message(id: 'temp-1', clientMessageId: 'c1', text: 'optimistic'),
        message(id: 'server-1', clientMessageId: 'c1', text: 'confirmed'),
      ]);

      expect(result, hasLength(1));
      expect(result.single.id, 'server-1');
      expect(result.single.text, 'confirmed');
    });

    test('legacy rows without a client id are deduped by server id', () {
      final result = reconciler.dedupe([
        message(id: 's1', text: 'first copy'),
        message(id: 's1', text: 'second copy'),
        message(id: 's2'),
      ]);

      expect(result, hasLength(2));
    });

    test('merging preserves reactions the incoming copy does not carry', () {
      final result = reconciler.dedupe([
        message(
          id: 'temp-1',
          clientMessageId: 'c1',
          reactions: const {'user-9': '👍'},
        ),
        message(id: 'server-1', clientMessageId: 'c1'), // no reactions
      ]);

      expect(result.single.reactions, {'user-9': '👍'});
    });

    test('an empty list stays empty', () {
      expect(reconciler.dedupe([]), isEmpty);
    });
  });

  group('applyOptimistic', () {
    test('adds a brand-new optimistic message at the right position', () {
      final current = [message(id: 's1', createdAt: at(10))];
      final result = reconciler.applyOptimistic(
        current,
        message(id: 'temp', clientMessageId: 'c1', createdAt: at(20)),
      );

      expect(result.ids, ['temp', 's1']);
    });

    test('a double tap on SEND does not create a second bubble', () {
      // The UI can fire twice; the cid is generated once per logical
      // message, so the second call must be a no-op returning the SAME
      // list instance (cheap identity check for the caller).
      final optimistic = message(id: 'temp', clientMessageId: 'c1');
      final current = [optimistic];

      final result = reconciler.applyOptimistic(current, optimistic);

      expect(result, same(current));
      expect(result, hasLength(1));
    });

    test('a retry reusing the same cid does not duplicate, even though the '
        'retry built a new model object', () {
      final current = [message(id: 'temp', clientMessageId: 'c1')];
      final retry = message(id: 'temp', clientMessageId: 'c1', text: 'retry');

      expect(reconciler.applyOptimistic(current, retry), hasLength(1));
    });
  });

  group('applyPointEvent — a single Realtime row or API ack', () {
    test('an unknown message is appended and sorted in', () {
      final result = reconciler.applyPointEvent([
        message(id: 'a', createdAt: at(10)),
      ], message(id: 'b', createdAt: at(30)));

      expect(result.ids, ['b', 'a']);
    });

    test('the server ack REPLACES the optimistic row instead of adding a '
        'second one — this is the "message shows twice" regression', () {
      final optimistic = message(
        id: 'temp-1',
        clientMessageId: 'c1',
        text: 'hi',
        createdAt: at(10),
      );
      final ack = message(
        id: 'server-1',
        clientMessageId: 'c1',
        text: 'hi',
        createdAt: at(10),
        isRead: true,
      );

      final result = reconciler.applyPointEvent([optimistic], ack);

      expect(result, hasLength(1));
      expect(result.single.id, 'server-1');
      expect(result.single.isRead, isTrue);
    });

    test('order of arrival does not matter: Realtime-then-ack and '
        'ack-then-Realtime converge on the same list', () {
      final optimistic = message(id: 'temp', clientMessageId: 'c1');
      final realtime = message(id: 'srv', clientMessageId: 'c1', isRead: true);
      final ack = message(id: 'srv', clientMessageId: 'c1', text: 'hello');

      final a = reconciler.applyPointEvent(
        reconciler.applyPointEvent([optimistic], realtime),
        ack,
      );
      final b = reconciler.applyPointEvent(
        reconciler.applyPointEvent([optimistic], ack),
        realtime,
      );

      expect(a.ids, b.ids);
      expect(a, hasLength(1));
    });

    test('a duplicate Realtime event for a message already present is '
        'idempotent', () {
      final row = message(id: 's1', clientMessageId: 'c1');
      final once = reconciler.applyPointEvent([], row);
      final twice = reconciler.applyPointEvent(once, row);

      expect(twice, hasLength(1));
    });

    test('reactions already held locally survive an ack that omits them', () {
      final withReaction = message(
        id: 's1',
        clientMessageId: 'c1',
        reactions: const {'u1': '❤️'},
      );
      final ack = message(id: 's1', clientMessageId: 'c1', text: 'edited');

      final result = reconciler.applyPointEvent([withReaction], ack);

      expect(result.single.text, 'edited');
      expect(result.single.reactions, {'u1': '❤️'});
    });
  });

  group('applySnapshot — a full list from Realtime or disk', () {
    test('messages present in both are merged, incoming content wins', () {
      final result = reconciler.applySnapshot(
        [message(id: 's1', text: 'old')],
        snapshot: [message(id: 's1', text: 'new')],
        protectedKeys: const {},
      );

      expect(result.messages.single.text, 'new');
      expect(result.stillUnconfirmed, isEmpty);
    });

    test('a local message missing from the snapshot and NOT protected is '
        'dropped — this is how a remote delete propagates', () {
      final result = reconciler.applySnapshot(
        [message(id: 's1'), message(id: 's2')],
        snapshot: [message(id: 's1')],
        protectedKeys: const {},
      );

      expect(result.messages.ids, ['s1']);
    });

    test('an in-flight optimistic message SURVIVES a snapshot that does not '
        'contain it yet — the user must never watch their own message '
        'disappear one frame after sending it', () {
      final optimistic = message(
        id: 'temp',
        clientMessageId: 'c1',
        createdAt: at(50),
      );
      final key = correlationKeyFor(id: 'temp', clientMessageId: 'c1');

      final result = reconciler.applySnapshot(
        [optimistic, message(id: 's1', createdAt: at(10))],
        snapshot: [message(id: 's1', createdAt: at(10))],
        protectedKeys: {key},
      );

      expect(result.messages.ids, ['temp', 's1']);
      expect(result.stillUnconfirmed, {key});
    });

    test('once the snapshot DOES contain it, protection is released so the '
        'message can never be protected forever', () {
      final key = correlationKeyFor(id: 'temp', clientMessageId: 'c1');

      final result = reconciler.applySnapshot(
        [message(id: 'temp', clientMessageId: 'c1')],
        snapshot: [message(id: 'server-1', clientMessageId: 'c1')],
        protectedKeys: {key},
      );

      expect(result.messages.single.id, 'server-1');
      expect(
        result.stillUnconfirmed,
        isEmpty,
        reason: 'confirmed messages must drop out of the protected set',
      );
    });

    test('brand-new messages from the snapshot are added', () {
      final result = reconciler.applySnapshot(
        [message(id: 's1', createdAt: at(10))],
        snapshot: [
          message(id: 's1', createdAt: at(10)),
          message(id: 's2', createdAt: at(20)),
        ],
        protectedKeys: const {},
      );

      expect(result.messages.ids, ['s2', 's1']);
    });

    test('an empty snapshot with no protection clears the list — an empty '
        'conversation must actually render as empty', () {
      final result = reconciler.applySnapshot(
        [message(id: 's1')],
        snapshot: const [],
        protectedKeys: const {},
      );

      expect(result.messages, isEmpty);
    });

    test('the result is always sorted newest-first regardless of the '
        'snapshot ordering the server happened to return', () {
      final result = reconciler.applySnapshot(
        const [],
        snapshot: [
          message(id: 'a', createdAt: at(10)),
          message(id: 'c', createdAt: at(30)),
          message(id: 'b', createdAt: at(20)),
        ],
        protectedKeys: const {},
      );

      expect(result.messages.ids, ['c', 'b', 'a']);
    });

    test('a snapshot carrying the same logical message under a new server '
        'id does not duplicate it', () {
      final result = reconciler.applySnapshot(
        [message(id: 'temp', clientMessageId: 'c1')],
        snapshot: [message(id: 'server-1', clientMessageId: 'c1')],
        protectedKeys: const {},
      );

      expect(result.messages, hasLength(1));
      expect(result.messages.single.id, 'server-1');
    });
  });

  group('applyFieldUpdate', () {
    test('rewrites every message and keeps ordering', () {
      final result = reconciler.applyFieldUpdate([
        message(id: 'a', createdAt: at(10)),
        message(id: 'b', createdAt: at(20)),
      ], (m) => m.copyWith(reactions: {'u1': '🔥'}));

      expect(result.ids, ['b', 'a']);
      expect(result.every((m) => m.reactions.containsKey('u1')), isTrue);
    });
  });

  group('removeById / applyRemoval', () {
    test('removeById drops only the matching server id', () {
      final result = reconciler.removeById([
        message(id: 'a'),
        message(id: 'b'),
      ], 'a');
      expect(result.ids, ['b']);
    });

    test('applyRemoval matches on logical identity, so deleting by cid '
        'removes the optimistic row even though its server id differs', () {
      final result = reconciler.applyRemoval(
        [message(id: 'temp', clientMessageId: 'c1'), message(id: 's2')],
        id: 'server-1',
        clientMessageId: 'c1',
      );

      expect(result.ids, ['s2']);
    });

    test('removing something that is not there is a no-op, never a throw', () {
      final current = [message(id: 'a')];
      expect(reconciler.applyRemoval(current, id: 'zzz'), hasLength(1));
    });
  });

  group('convergence — the sequences that actually happen in production', () {
    test('send → ack → realtime snapshot → reaction ends with exactly one '
        'message carrying both the server id and the reaction', () {
      var list = <MessageModel>[];
      const cid = 'c1';
      final key = correlationKeyFor(id: 'temp', clientMessageId: cid);

      // 1. optimistic send
      list = reconciler.applyOptimistic(
        list,
        message(id: 'temp', clientMessageId: cid, createdAt: at(10)),
      );
      expect(list, hasLength(1));

      // 2. API ack with the real row
      list = reconciler.applyPointEvent(
        list,
        message(id: 'srv-1', clientMessageId: cid, createdAt: at(10)),
      );
      expect(list.single.id, 'srv-1');

      // 3. a Realtime snapshot that has not caught up yet
      var snapshot = reconciler.applySnapshot(
        list,
        snapshot: const [],
        protectedKeys: {key},
      );
      expect(
        snapshot.messages,
        hasLength(1),
        reason: 'protected by cid, so the lagging snapshot cannot delete it',
      );

      // 4. the snapshot catches up
      snapshot = reconciler.applySnapshot(
        snapshot.messages,
        snapshot: [
          message(id: 'srv-1', clientMessageId: cid, createdAt: at(10)),
        ],
        protectedKeys: snapshot.stillUnconfirmed,
      );
      list = snapshot.messages;
      expect(list, hasLength(1));

      // 5. a reaction arrives on its own stream
      list = reconciler.applyFieldUpdate(
        list,
        (m) => m.copyWith(reactions: {'u2': '😂'}),
      );

      expect(list, hasLength(1));
      expect(list.single.id, 'srv-1');
      expect(list.single.reactions, {'u2': '😂'});
    });

    test('two devices sending at the same second produce two distinct '
        'messages, not a merged one', () {
      var list = <MessageModel>[];
      list = reconciler.applyPointEvent(
        list,
        message(id: 's1', clientMessageId: 'cA', createdAt: at(10)),
      );
      list = reconciler.applyPointEvent(
        list,
        message(id: 's2', clientMessageId: 'cB', createdAt: at(10)),
      );

      expect(list, hasLength(2));
    });
  });
}
