import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../bootstrap/app_bootstrap.dart';
import '../../../helpers/safe_emit_mixin.dart';
import '../../../supabase/supabase_provider.dart';
import '../../../utilities/supabase_constants.dart';
import '../../models/presence_info.dart';

class PresenceCubit extends Cubit<Map<String, PresenceInfo>>
    with SafeEmitMixin<Map<String, PresenceInfo>> {
  PresenceCubit({SupabaseClient? client})
    : _injectedClient = client,
      super(const {}) {
    _init();
  }

  final SupabaseClient? _injectedClient;
  SupabaseClient get _supabase => _injectedClient ?? SupabaseProvider.client;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  StreamSubscription<AuthState>? _authSub;
  Timer? _retryTimer;

  Future<void> _init() async {
    await waitForCoreServicesReady();
    if (isClosed) return;

    if (SupabaseProvider.isAuthenticated) {
      _subscribe();
    }

    _authSub = SupabaseProvider.authChanges.listen((authState) {
      if (isClosed) return;
      if (authState.event == AuthChangeEvent.signedIn ||
          authState.event == AuthChangeEvent.tokenRefreshed) {
        if (_sub == null) _subscribe();
      } else if (authState.event == AuthChangeEvent.signedOut) {
        _retryTimer?.cancel();
        _sub?.cancel();
        _sub = null;
        emit(const {});
      }
    });
  }

  void _subscribe() {
    if (isClosed || !SupabaseProvider.isAuthenticated) return;
    _retryTimer?.cancel();
    _sub?.cancel();
    _sub = _supabase
        .from(SupabaseConstants.userPresence)
        .stream(primaryKey: [PresenceColumns.userId])
        .listen(
          _onRows,
          onError: (e) {
            debugPrint('[PresenceCubit] stream error: $e');
            _sub?.cancel();
            _sub = null;
            if (!isClosed && SupabaseProvider.isAuthenticated) {
              _retryTimer?.cancel();
              _retryTimer = Timer(const Duration(seconds: 3), _subscribe);
            }
          },
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
    _retryTimer?.cancel();
    _authSub?.cancel();
    _sub?.cancel();
    return super.close();
  }
}
