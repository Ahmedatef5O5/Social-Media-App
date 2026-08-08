import 'package:social_media_app/core/supabase/supabase_provider.dart';

class ChatMuteService {
  Future<void> setMuted({required String peerId, required bool muted}) async {
    await SupabaseProvider.client.from('chat_mutes').upsert({
      'owner_id': SupabaseProvider.id,
      'peer_id': peerId,
      'is_muted': muted,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
