import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:social_media_app/core/audio/voice_recorder/services/audio_compression_service.dart';
import 'package:social_media_app/core/cache/repository/media_cache_repository.dart';
import 'package:social_media_app/features/single_chats/cubits/chat_details_cubit/chat_details_cubit.dart';
import 'package:social_media_app/features/single_chats/models/message_model.dart';
import 'package:social_media_app/features/single_chats/services/chat_permission_service.dart';
import 'package:social_media_app/features/single_chats/services/chat_presence_service.dart';
import 'package:social_media_app/features/single_chats/services/chat_services.dart';

import '../../../helpers/message_factory.dart';

class MockChatServices extends Mock implements ChatServices {}

class MockChatPresenceService extends Mock implements ChatPresenceService {}

class MockMediaCacheRepository extends Mock implements MediaCacheRepository {}

class MockChatPermissionService extends Mock implements ChatPermissionService {}

class MockAudioCompressionService extends Mock
    implements AudioCompressionService {}

/// PRIORITY: P0 — account isolation + data corruption (V6 C-02, H-02).
///
/// WHY THIS FILE NEEDED A SEAM FIRST
/// ─────────────────────────────────
/// `ChatDetailsCubit` resolved its identity with a field initialiser:
///
/// ```dart
/// final currentUserId = SupabaseProvider.id;
/// ```
///
/// That runs at construction and reaches `Supabase.instance.client`, which
/// throws in any plain test process. It is also the C-02 bug itself in
/// miniature: the identity is captured ONCE, so a Cubit that outlives an
/// account switch keeps operating as the previous user. The optional
/// `currentUserIdProvider` parameter (see PATCHES.md) fixes both — it is
/// the same seam `HomeCubit` already uses, and both real call sites in
/// `app_router.dart` are unaffected because it defaults to
/// `SupabaseProvider.id`.
///
/// Everything below is hermetic: `LocalSnapshotStore` returns `[]` and
/// no-ops on write while uninitialised, so no Hive box is ever opened.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockChatServices chatServices;
  late MockChatPresenceService presenceService;
  late MockMediaCacheRepository mediaCache;
  late MockChatPermissionService permissionService;
  late MockAudioCompressionService audioCompression;
  late StreamController<List<MessageModel>> messagesA;
  late StreamController<List<MessageModel>> messagesB;
  late StreamController<List<Map<String, dynamic>>> reactions;

  const me = 'user-me';
  const peerA = 'user-a';
  const peerB = 'user-b';

  setUp(() {
    chatServices = MockChatServices();
    presenceService = MockChatPresenceService();
    mediaCache = MockMediaCacheRepository();
    permissionService = MockChatPermissionService();
    audioCompression = MockAudioCompressionService();

    messagesA = StreamController<List<MessageModel>>.broadcast();
    messagesB = StreamController<List<MessageModel>>.broadcast();
    reactions = StreamController<List<Map<String, dynamic>>>.broadcast();

    when(
      () => chatServices.getMessagesStream(
        senderId: any(named: 'senderId'),
        receiverId: any(named: 'receiverId'),
      ),
    ).thenAnswer((_) => messagesA.stream);

    when(
      () => chatServices.getMessagesStream(
        senderId: any(named: 'senderId'),
        receiverId: peerB,
      ),
    ).thenAnswer((_) => messagesB.stream);

    when(
      () => chatServices.getMessageReactionsStream(any()),
    ).thenAnswer((_) => reactions.stream);
  });

  tearDown(() async {
    await messagesA.close();
    await messagesB.close();
    await reactions.close();
  });

  ChatDetailsCubit buildCubit({String userId = me}) {
    return ChatDetailsCubit(
      chatServices,
      'Peer Name',
      mediaCache,
      presenceService: presenceService,
      chatPermissionService: permissionService,
      audioCompressionService: audioCompression,
      currentUserIdProvider: () => userId,
    );
  }

  /// One microtask turn is enough for a broadcast stream event to reach a
  /// listener. No `Future.delayed`, no sleeps — nothing here is timing
  /// dependent, which is what keeps the suite fast and non-flaky on CI.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('identity and account isolation — C-02', () {
    test('the cubit subscribes with the INJECTED user id, never with the '
        'Supabase singleton', () {
      final cubit = buildCubit(userId: 'user-zed');
      addTearDown(cubit.close);

      cubit.getMessagesStream(receiverId: peerA);

      verify(
        () => chatServices.getMessagesStream(
          senderId: 'user-zed',
          receiverId: peerA,
        ),
      ).called(1);
    });

    test('the reactions channel is scoped to the sorted conversation id, so '
        'two accounts can never share one reactions cache', () {
      final cubit = buildCubit(userId: 'aaa');
      addTearDown(cubit.close);

      cubit.getMessagesStream(receiverId: 'zzz');

      verify(() => chatServices.getMessageReactionsStream('aaa_zzz')).called(1);
    });

    test('an EMPTY user id (what SupabaseProvider.id returns while signed '
        'out) still produces a distinct, non-colliding conversation scope', () {
      final cubit = buildCubit(userId: '');
      addTearDown(cubit.close);

      cubit.getMessagesStream(receiverId: peerA);

      verify(() => chatServices.getMessageReactionsStream('_$peerA')).called(1);
    });
  });

  group('snapshot handling', () {
    test(
      'the first snapshot emits MessagesSuccessLoaded, newest first',
      () async {
        final cubit = buildCubit();
        addTearDown(cubit.close);
        final states = <ChatDetailsState>[];
        cubit.stream.listen(states.add);

        cubit.getMessagesStream(receiverId: peerA);
        messagesA.add([
          message(id: 'm1', senderId: me, receiverId: peerA, createdAt: at(10)),
          message(id: 'm2', senderId: me, receiverId: peerA, createdAt: at(30)),
        ]);
        await settle();

        expect(states, hasLength(1));
        final loaded = states.single as MessagesSuccessLoaded;
        expect(loaded.messages.map((m) => m.id), ['m2', 'm1']);
        expect(cubit.hasConfirmedInitialLoad, isTrue);
      },
    );

    test('a duplicate snapshot does not duplicate messages', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.getMessagesStream(receiverId: peerA);
      final payload = [
        message(id: 'm1', senderId: peerA, receiverId: me, createdAt: at(10)),
      ];
      messagesA.add(payload);
      await settle();
      messagesA.add(payload);
      await settle();

      expect(cubit.cachedMessages, hasLength(1));
    });

    test('the optimistic and server representations of one message collapse '
        'into a single bubble across two snapshots', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.getMessagesStream(receiverId: peerA);
      messagesA.add([
        message(
          id: 'temp-1',
          clientMessageId: 'cid-1',
          senderId: me,
          receiverId: peerA,
          createdAt: at(10),
        ),
      ]);
      await settle();
      messagesA.add([
        message(
          id: 'server-1',
          clientMessageId: 'cid-1',
          senderId: me,
          receiverId: peerA,
          createdAt: at(10),
        ),
      ]);
      await settle();

      expect(cubit.cachedMessages, hasLength(1));
      expect(cubit.cachedMessages.single.id, 'server-1');
    });
  });

  group('switching conversations — the epoch guard', () {
    test('after switching to another peer, events from the PREVIOUS '
        "conversation's stream never reach state", () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.getMessagesStream(receiverId: peerA);
      messagesA.add([
        message(id: 'a1', senderId: peerA, receiverId: me, createdAt: at(10)),
      ]);
      await settle();
      expect(cubit.cachedMessages.map((m) => m.id), ['a1']);

      cubit.getMessagesStream(receiverId: peerB);
      messagesB.add([
        message(id: 'b1', senderId: peerB, receiverId: me, createdAt: at(20)),
      ]);
      await settle();

      // Late event from the abandoned conversation.
      messagesA.add([
        message(id: 'a2', senderId: peerA, receiverId: me, createdAt: at(30)),
      ]);
      await settle();

      expect(
        cubit.cachedMessages.map((m) => m.id),
        ['b1'],
        reason: "peer A's messages must not leak into peer B's chat",
      );
    });

    test('re-subscribing resets the confirmed-initial-load flag so the UI '
        'shows a loading state again instead of stale content', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.getMessagesStream(receiverId: peerA);
      messagesA.add([message(id: 'a1', createdAt: at(10))]);
      await settle();
      expect(cubit.hasConfirmedInitialLoad, isTrue);

      cubit.getMessagesStream(receiverId: peerB);
      expect(cubit.hasConfirmedInitialLoad, isFalse);
    });

    test(
      'the previous messages subscription is cancelled, not leaked',
      () async {
        final cubit = buildCubit();
        addTearDown(cubit.close);

        cubit.getMessagesStream(receiverId: peerA);
        await settle();
        expect(messagesA.hasListener, isTrue);

        cubit.getMessagesStream(receiverId: peerB);
        await settle();

        expect(
          messagesA.hasListener,
          isFalse,
          reason: 'a surviving listener is a zombie subscription',
        );
      },
    );
  });

  group('pending messages while scrolled up', () {
    test("a new message from the OTHER user is held pending and does not "
        'yank the list out from under the reader', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.getMessagesStream(receiverId: peerA);
      messagesA.add([
        message(id: 'm1', senderId: peerA, receiverId: me, createdAt: at(10)),
      ]);
      await settle();

      cubit.setUserAtBottom(false);
      messagesA.add([
        message(id: 'm1', senderId: peerA, receiverId: me, createdAt: at(10)),
        message(id: 'm2', senderId: peerA, receiverId: me, createdAt: at(20)),
      ]);
      await settle();

      expect(cubit.pendingNewCountNotifier.value, 1);
      expect(cubit.hasPendingMessages, isTrue);
      expect(
        cubit.cachedMessages.map((m) => m.id),
        ['m1'],
        reason: 'the visible list must not change until the user scrolls down',
      );
    });

    test('flushPendingMessages promotes them and clears the counter', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.getMessagesStream(receiverId: peerA);
      messagesA.add([
        message(id: 'm1', senderId: peerA, receiverId: me, createdAt: at(10)),
      ]);
      await settle();
      cubit.setUserAtBottom(false);
      messagesA.add([
        message(id: 'm1', senderId: peerA, receiverId: me, createdAt: at(10)),
        message(id: 'm2', senderId: peerA, receiverId: me, createdAt: at(20)),
      ]);
      await settle();

      cubit.flushPendingMessages();

      expect(cubit.pendingNewCountNotifier.value, 0);
      expect(cubit.cachedMessages.map((m) => m.id), ['m2', 'm1']);
    });

    test('MY OWN new message is never held pending — sending a message '
        'always scrolls you to it', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.getMessagesStream(receiverId: peerA);
      messagesA.add([
        message(id: 'm1', senderId: peerA, receiverId: me, createdAt: at(10)),
      ]);
      await settle();

      cubit.setUserAtBottom(false);
      messagesA.add([
        message(id: 'm1', senderId: peerA, receiverId: me, createdAt: at(10)),
        message(id: 'mine', senderId: me, receiverId: peerA, createdAt: at(20)),
      ]);
      await settle();

      expect(cubit.pendingNewCountNotifier.value, 0);
      expect(cubit.cachedMessages.map((m) => m.id), ['mine', 'm1']);
    });

    test('flushing with nothing pending is a no-op', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      expect(cubit.flushPendingMessages, returnsNormally);
      expect(cubit.pendingNewCountNotifier.value, 0);
    });
  });

  group('reactions', () {
    test('a reactions event decorates existing messages without duplicating '
        'or reordering them', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.getMessagesStream(receiverId: peerA);
      messagesA.add([
        message(id: 'm1', senderId: peerA, receiverId: me, createdAt: at(10)),
        message(id: 'm2', senderId: peerA, receiverId: me, createdAt: at(20)),
      ]);
      await settle();

      reactions.add([
        {
          'message_id': 'm1',
          'user_id': me,
          'reaction': '👍',
          'created_at': at(25).toIso8601String(),
        },
      ]);
      await settle();

      expect(cubit.cachedMessages, hasLength(2));
      expect(cubit.cachedMessages.map((m) => m.id), ['m2', 'm1']);
      final m1 = cubit.cachedMessages.firstWhere((m) => m.id == 'm1');
      expect(m1.reactions[me], '👍');
    });
  });

  group('disposal', () {
    test(
      'close cancels both the messages and reactions subscriptions',
      () async {
        final cubit = buildCubit();
        cubit.getMessagesStream(receiverId: peerA);
        await settle();

        expect(messagesA.hasListener, isTrue);
        expect(reactions.hasListener, isTrue);

        await cubit.close();
        await settle();

        expect(messagesA.hasListener, isFalse);
        expect(reactions.hasListener, isFalse);
      },
    );

    test('a stream event arriving after close does not emit — a closed '
        'Cubit that emits throws in bloc and crashes the app', () async {
      final cubit = buildCubit();
      cubit.getMessagesStream(receiverId: peerA);
      await settle();

      await cubit.close();
      messagesA.add([message(id: 'late', createdAt: at(99))]);

      await expectLater(settle(), completes);
    });
  });
}
