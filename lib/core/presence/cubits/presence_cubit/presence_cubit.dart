import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../supabase/supabase_provider.dart';
import '../../../utilities/supabase_constants.dart';
import '../../models/presence_info.dart';

class PresenceCubit extends Cubit<Map<String, PresenceInfo>> {
  PresenceCubit({SupabaseClient? client})
    : _supabase = client ?? SupabaseProvider.client,
      super(const {}) {
    _subscribe();
  }

  final SupabaseClient _supabase;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  void _subscribe() {
    _sub = _supabase
        .from(SupabaseConstants.userPresence)
        .stream(primaryKey: [PresenceColumns.userId])
        .listen(
          _onRows,
          onError: (e) => debugPrint('[PresenceCubit] stream error: $e'),
        );
  }

  void _onRows(List<Map<String, dynamic>> rows) {
    final updated = <String, PresenceInfo>{
      for (final row in rows)
        row[PresenceColumns.userId] as String: PresenceInfo.fromMap(row),
    };
    emit(updated);
  }

  PresenceInfo? of(String userId) => state[userId];

  bool isOnline(String userId) => state[userId]?.isEffectivelyOnline ?? false;

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
