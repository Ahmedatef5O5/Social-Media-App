import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMuteService {
  Future<void> setMuted({required String peerId, required bool muted}) async {
    await SupabaseProvider.client.from('chat_mutes').upsert({
      'owner_id': SupabaseProvider.id,
      'peer_id': peerId,
      'is_muted': muted,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<bool> getMuted({required String peerId}) async {
    final result = await SupabaseProvider.client.rpc(
      'is_chat_muted',
      params: {'p_owner': SupabaseProvider.id, 'p_peer': peerId},
    );
    return (result as bool?) ?? false;
  }

  Stream<bool> watchMuted({required String peerId}) {
    final controller = StreamController<bool>.broadcast();
    final supabase = SupabaseProvider.client;

    Future<void> refresh() async {
      try {
        final muted = await getMuted(peerId: peerId);
        if (!controller.isClosed) controller.add(muted);
      } catch (e) {
        debugPrint(
          '[ChatMuteService] watchMuted refresh failed for $peerId: $e',
        );
      }
    }

    final channelName = 'chat_mutes_${SupabaseProvider.id}_$peerId';
    supabase.removeChannel(supabase.channel(channelName));
    final channel = supabase.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_mutes',
          callback: (payload) {
            final row =
                payload.eventType == PostgresChangeEvent.delete
                    ? payload.oldRecord
                    : payload.newRecord;

            final ownerId = row['owner_id'] as String?;
            final rowPeerId = row['peer_id'] as String?;
            if (ownerId != SupabaseProvider.id || rowPeerId != peerId) return;
            final isMuted = row['is_muted'] as bool? ?? false;
            if (!controller.isClosed) controller.add(isMuted);
          },
        )
        .subscribe();

    refresh();

    controller.onCancel = () {
      supabase.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }
}
