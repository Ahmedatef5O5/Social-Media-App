import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/helpers/chat_helper.dart';

/// PRIORITY: P0 — account isolation.
///
/// `buildConversationId` is not a cosmetic helper. Its output is used as
/// the Hive snapshot key in `ChatDetailsCubit.getMessagesStream`
/// (`chat_messages_snapshot_$conversationId`) and as the Realtime channel
/// topic for reactions. If it were not symmetric, the two participants of
/// the same chat would write to two different caches and each would see
/// half the conversation. If it were not injective, two different chats
/// would share one cache — messages from chat A leaking into chat B.
void main() {
  group('ChatHelper.buildConversationId', () {
    test('is symmetric: both participants derive the same id', () {
      expect(
        ChatHelper.buildConversationId('user-a', 'user-b'),
        ChatHelper.buildConversationId('user-b', 'user-a'),
      );
    });

    test('sorts lexicographically, so the result is predictable', () {
      expect(ChatHelper.buildConversationId('zzz', 'aaa'), 'aaa_zzz');
    });

    test('different pairs never collide', () {
      final ids = <String>{
        ChatHelper.buildConversationId('a', 'b'),
        ChatHelper.buildConversationId('a', 'c'),
        ChatHelper.buildConversationId('b', 'c'),
      };
      expect(ids, hasLength(3));
    });

    test('an empty user id (what SupabaseProvider.id returns while signed '
        'out) produces a DIFFERENT id than any real pair — it must never '
        'silently alias onto a real conversation', () {
      final signedOut = ChatHelper.buildConversationId('', 'user-b');
      final signedIn = ChatHelper.buildConversationId('user-a', 'user-b');
      expect(signedOut, isNot(signedIn));
      expect(signedOut, '_user-b');
    });
  });

  test('isArabic detects Arabic text correctly', () {
    expect(ChatHelper.isArabic('مرحبا'), isTrue);
    expect(ChatHelper.isArabic('hello'), isFalse);
    expect(ChatHelper.isArabic('   '), isFalse);
  });

  test('getTextDirection returns rtl for Arabic and ltr for English', () {
    expect(ChatHelper.getTextDirection('مرحبا'), TextDirection.rtl);
    expect(ChatHelper.getTextDirection('hello'), TextDirection.ltr);
  });
}
