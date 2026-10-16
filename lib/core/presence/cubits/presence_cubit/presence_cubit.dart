import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../bootstrap/app_bootstrap.dart';
import '../../../helpers/safe_emit_mixin.dart';
import '../../../observability/error_category.dart';
import '../../../observability/observability.dart';
import '../../../observability/realtime_diagnostics.dart';
import '../../../supabase/supabase_provider.dart';
import '../../../utilities/supabase_constants.dart';
import '../../models/presence_info.dart';

class PresenceCubit extends Cubit<Map<String, PresenceInfo>>
    with SafeEmitMixin<Map<String, PresenceInfo>> {
  PresenceCubit({SupabaseClient? client})
    : _injectedClient = client,
      super(const {}) {
    unawaited(_init());
  }

  /// Realtime accepts at most 100 values inside an `in` filter.
  static const int maxIdsPerChannel = 100;
  static const int maxLiveChannels = 3;
  static const int maxLiveIds = maxIdsPerChannel * maxLiveChannels;

  static const Duration _reconcileDebounce = Duration(milliseconds: 1200);
  static const Duration _reconcileMaxWait = Duration(seconds: 3);
  static const Duration _flushInterval = Duration(milliseconds: 200);
  static const Duration _retryDelay = Duration(seconds: 5);
  static const String _channelPrefix = 'presence_scope_';

  final SupabaseClient? _injectedClient;
  SupabaseClient get _supabase => _injectedClient ?? SupabaseProvider.client;

  final Map<String, int> _interest = <String, int>{};

  Set<String> _liveIds = <String>{};

  final List<RealtimeChannel> _channels = <RealtimeChannel>[];
  final Map<String, PresenceInfo> _pending = <String, PresenceInfo>{};
  final Set<String> _pendingRemovals = <String>{};

  StreamSubscription<AuthState>? _authSub;
  Timer? _reconcileTimer;
  Timer? _flushTimer;
  Timer? _retryTimer;
  DateTime? _firstPendingAt;

  bool _ready = false;
  bool _reconciling = false;
  bool _reconcileAgain = false;
  bool _overflowReported = false;
  int _generation = 0;
  int _channelEpoch = 0;
  String? _sessionUserId;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  PresenceInfo? of(String userId) => state[userId];

  bool isOnline(String userId) => state[userId]?.isEffectivelyOnline ?? false;

  void watch(String userId) => watchAll([userId]);

  void unwatch(String userId) => unwatchAll([userId]);

  void watchAll(Iterable<String> userIds) {
    if (isClosed) return;
    var changed = false;
    for (final id in userIds) {
      if (id.isEmpty) continue;
      final next = (_interest[id] ?? 0) + 1;
      _interest[id] = next;
      if (next == 1) changed = true;
    }
    if (changed) _scheduleReconcile();
  }

  void unwatchAll(Iterable<String> userIds) {
    if (isClosed) return;
    var changed = false;
    for (final id in userIds) {
      final current = _interest[id];
      if (current == null) continue;
      if (current <= 1) {
        _interest.remove(id);
        changed = true;
      } else {
        _interest[id] = current - 1;
      }
    }
    if (changed) _scheduleReconcile();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> _init() async {
    try {
      await waitForCoreServicesReady();
      if (isClosed) return;

      _sessionUserId = SupabaseProvider.idOrNull;
      _authSub = SupabaseProvider.authChanges.listen(_onAuth);
      _ready = true;

      if (_interest.isNotEmpty) _scheduleReconcile();
    } catch (e, st) {
      obs.recordError(
        e,
        st,
        category: ErrorCategory.realtime,
        feature: 'presence',
        operation: 'init',
        reason: 'PresenceCubit init failed',
      );
    }
  }

  void _onAuth(AuthState authState) {
    if (isClosed) return;
    switch (authState.event) {
      case AuthChangeEvent.signedOut:
        _endSession();
      case AuthChangeEvent.signedIn:
        {
          final uid = authState.session?.user.id;
          if (uid != null && uid != _sessionUserId) {
            _endSession();
            _sessionUserId = uid;
          }
          if (_channels.isEmpty && _interest.isNotEmpty) _scheduleReconcile();
        }
      case AuthChangeEvent.tokenRefreshed:
        if (_channels.isEmpty && _interest.isNotEmpty) _scheduleReconcile();
      default:
        break;
    }
  }

  /// Drops everything that belongs to the previous account. Widget interest is
  /// kept: it is balanced by widget mount/dispose, not by auth events.
  void _endSession() {
    _generation++;
    _sessionUserId = null;
    _reconcileTimer?.cancel();
    _retryTimer?.cancel();
    _flushTimer?.cancel();
    _flushTimer = null;
    _firstPendingAt = null;
    _pending.clear();
    _pendingRemovals.clear();
    _liveIds = <String>{};
    unawaited(_teardownChannels());
    if (state.isNotEmpty) emit(const {});
  }

  // ---------------------------------------------------------------------------
  // Reconciliation (interest set -> snapshot + channels)
  // ---------------------------------------------------------------------------

  bool get _isAuthenticated {
    try {
      return SupabaseProvider.isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  void _scheduleReconcile() {
    if (isClosed || !_ready) return;

    final now = DateTime.now();
    _firstPendingAt ??= now;
    final waited = now.difference(_firstPendingAt!);
    final delay =
        waited >= _reconcileMaxWait ? Duration.zero : _reconcileDebounce;

    _reconcileTimer?.cancel();
    _reconcileTimer = Timer(delay, () {
      _firstPendingAt = null;
      unawaited(_reconcile());
    });
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, _scheduleReconcile);
  }

  Future<void> _reconcile() async {
    if (isClosed || !_ready || !_isAuthenticated) return;
    if (_reconciling) {
      _reconcileAgain = true;
      return;
    }

    _reconciling = true;
    try {
      do {
        _reconcileAgain = false;
        await _reconcileOnce();
      } while (_reconcileAgain && !isClosed);
    } catch (e, st) {
      obs.recordError(
        e,
        st,
        category: ErrorCategory.realtime,
        feature: 'presence',
        operation: 'reconcile',
        reason: 'presence reconcile failed',
      );
      _scheduleRetry();
    } finally {
      _reconciling = false;
    }
  }

  Future<void> _reconcileOnce() async {
    final generation = _generation;
    final desired = _interest.keys.take(maxLiveIds).toList(growable: false);
    _reportOverflowIfNeeded();

    final desiredSet = desired.toSet();
    final needsChannels = desired.isNotEmpty && _channels.isEmpty;
    if (!needsChannels && setEquals(desiredSet, _liveIds)) return;

    if (desired.isEmpty) {
      await _teardownChannels();
      _liveIds = <String>{};
      if (state.isNotEmpty) emit(const {});
      return;
    }

    await _rebuildChannels(desired, generation);
    if (isClosed || generation != _generation) return;

    final added = desired.where((id) => !_liveIds.contains(id)).toList();
    final failed = await _fetchSnapshot(added, generation);
    if (isClosed || generation != _generation) return;

    _liveIds = desiredSet.difference(failed);
    _pruneState(desiredSet);
    if (failed.isNotEmpty) _scheduleRetry();
  }

  void _reportOverflowIfNeeded() {
    if (_interest.length > maxLiveIds) {
      if (_overflowReported) return;
      _overflowReported = true;
      obs.breadcrumb(
        'presence interest ${_interest.length} exceeds cap $maxLiveIds',
        feature: 'presence',
      );
    } else {
      _overflowReported = false;
    }
  }

  void _pruneState(Set<String> keep) {
    if (state.keys.every(keep.contains)) return;
    emit({
      for (final entry in state.entries)
        if (keep.contains(entry.key)) entry.key: entry.value,
    });
  }

  // ---------------------------------------------------------------------------
  // Snapshot
  // ---------------------------------------------------------------------------

  /// Returns the ids whose snapshot failed (they are retried later).
  Future<Set<String>> _fetchSnapshot(List<String> ids, int generation) async {
    final failed = <String>{};
    for (var i = 0; i < ids.length; i += maxIdsPerChannel) {
      final chunk = ids.sublist(i, math.min(i + maxIdsPerChannel, ids.length));
      try {
        final rows = await _supabase
            .from(SupabaseConstants.userPresence)
            .select(
              '${PresenceColumns.userId}, ${PresenceColumns.isOnline}, '
              '${PresenceColumns.lastSeen}, ${PresenceColumns.updatedAt}',
            )
            .inFilter(PresenceColumns.userId, chunk);
        if (isClosed || generation != _generation) return failed;
        _stageRows(rows as List<dynamic>);
        _flush();
      } catch (e, st) {
        failed.addAll(chunk);
        obs.recordError(
          e,
          st,
          category: ErrorCategory.realtime,
          feature: 'presence',
          operation: 'snapshot',
          reason: 'presence snapshot failed for ${chunk.length} ids',
        );
      }
    }
    return failed;
  }

  Future<void> _resyncSnapshot(int generation) async {
    if (isClosed || generation != _generation || _liveIds.isEmpty) return;
    await _fetchSnapshot(_liveIds.toList(growable: false), generation);
  }

  // ---------------------------------------------------------------------------
  // Channels
  // ---------------------------------------------------------------------------

  Future<void> _rebuildChannels(List<String> ids, int generation) async {
    await _teardownChannels();
    if (isClosed || generation != _generation) return;

    final uid = SupabaseProvider.idOrNull;
    if (uid == null) return;

    _channelEpoch++;
    for (var i = 0, n = 0; i < ids.length; i += maxIdsPerChannel, n++) {
      final chunk = ids.sublist(i, math.min(i + maxIdsPerChannel, ids.length));
      final channel = _supabase.channel('$_channelPrefix${_channelEpoch}_$n');
      final topic = channel.topic;
      var hadError = false;

      RealtimeDiagnostics.instance.onChannelCreated(topic, ownerUserId: uid);

      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: SupabaseConstants.userPresence,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.inFilter,
              column: PresenceColumns.userId,
              value: chunk,
            ),
            callback: (payload) => _onChange(payload, generation),
          )
          .subscribe((status, [error]) {
            switch (status) {
              case RealtimeSubscribeStatus.subscribed:
                RealtimeDiagnostics.instance.onChannelSubscribed(topic);
                if (hadError) {
                  hadError = false;
                  unawaited(_resyncSnapshot(generation));
                }
              case RealtimeSubscribeStatus.channelError:
              case RealtimeSubscribeStatus.timedOut:
                hadError = true;
                if (status == RealtimeSubscribeStatus.channelError) {
                  RealtimeDiagnostics.instance.onChannelError(
                    topic,
                    error ?? status,
                    StackTrace.current,
                  );
                }
              case RealtimeSubscribeStatus.closed:
                break;
            }
          });

      _channels.add(channel);
    }
  }

  Future<void> _teardownChannels() async {
    if (_channels.isEmpty) return;
    final old = List<RealtimeChannel>.of(_channels);
    _channels.clear();

    await Future.wait(
      old.map((channel) async {
        RealtimeDiagnostics.instance.onChannelClosed(channel.topic);
        try {
          await _supabase.removeChannel(channel);
        } catch (e, st) {
          obs.recordError(
            e,
            st,
            category: ErrorCategory.realtime,
            feature: 'presence',
            operation: 'remove_channel',
            reason: 'failed to remove ${channel.topic}',
          );
        }
      }),
    );
  }

  void _onChange(PostgresChangePayload payload, int generation) {
    if (isClosed || generation != _generation) return;

    final isDelete = payload.eventType == PostgresChangeEvent.delete;
    final record = isDelete ? payload.oldRecord : payload.newRecord;
    final id = record[PresenceColumns.userId] as String?;
    if (id == null || !_interest.containsKey(id)) return;

    if (isDelete) {
      _pending.remove(id);
      _pendingRemovals.add(id);
    } else {
      try {
        _stage(PresenceInfo.fromMap(record));
        _pendingRemovals.remove(id);
      } catch (e) {
        debugPrint('[PresenceCubit] bad presence payload: $e');
        return;
      }
    }
    _flushTimer ??= Timer(_flushInterval, _flush);
  }

  // ---------------------------------------------------------------------------
  // Coalesced state updates
  // ---------------------------------------------------------------------------

  void _stageRows(List<dynamic> rows) {
    for (final raw in rows) {
      try {
        final info = PresenceInfo.fromMap(
          Map<String, dynamic>.from(raw as Map),
        );
        _stage(info);
        _pendingRemovals.remove(info.userId);
      } catch (e) {
        debugPrint('[PresenceCubit] bad presence row: $e');
      }
    }
  }

  void _stage(PresenceInfo incoming) {
    final staged = _pending[incoming.userId];
    final stagedAt = staged?.updatedAt;
    final incomingAt = incoming.updatedAt;
    if (stagedAt != null &&
        incomingAt != null &&
        incomingAt.isBefore(stagedAt)) {
      return;
    }
    _pending[incoming.userId] = incoming;
  }

  void _flush() {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (isClosed || (_pending.isEmpty && _pendingRemovals.isEmpty)) return;

    final next = Map<String, PresenceInfo>.of(state);
    for (final info in _pending.values) {
      final previousAt = next[info.userId]?.updatedAt;
      final incomingAt = info.updatedAt;
      if (previousAt != null &&
          incomingAt != null &&
          incomingAt.isBefore(previousAt)) {
        continue;
      }
      next[info.userId] = info;
    }
    for (final id in _pendingRemovals) {
      next.remove(id);
    }
    _pending.clear();
    _pendingRemovals.clear();
    emit(next);
  }

  // ---------------------------------------------------------------------------

  @override
  Future<void> close() async {
    _reconcileTimer?.cancel();
    _flushTimer?.cancel();
    _retryTimer?.cancel();
    await _authSub?.cancel();
    _generation++;
    await _teardownChannels();
    return super.close();
  }
}
