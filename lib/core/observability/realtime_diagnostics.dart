import 'package:flutter/foundation.dart';

import 'error_category.dart';
import 'observability.dart';

/// Lifecycle state of a Supabase Realtime channel as this app cares about
/// it. Deliberately not tied to `RealtimeSubscribeStatus` so the registry
/// stays unit-testable without the Supabase SDK.
enum ChannelPhase { creating, subscribed, errored, closed }

class ChannelRecord {
  ChannelRecord({
    required this.topic,
    required this.ownerUserId,
    required this.createdAt,
    this.phase = ChannelPhase.creating,
  });

  final String topic;

  /// The account this channel belongs to. This is the field that makes
  /// account-switch leaks detectable: a channel whose owner is not the
  /// current user is, by definition, a zombie.
  final String ownerUserId;

  final DateTime createdAt;
  ChannelPhase phase;
  int errorCount = 0;
  int reconnectCount = 0;

  bool get isLive =>
      phase == ChannelPhase.creating || phase == ChannelPhase.subscribed;

  @override
  String toString() => '$topic(${phase.name}, owner=$ownerUserId)';
}

/// Central registry for every Realtime channel the app opens.
///
/// WHY THIS EXISTS
/// ───────────────
/// The app opens channels from 12 different files (`chat_list_service`,
/// `chat_block_service`, `chat_presence_service`, `posts_services`,
/// `stories_cubit`, `group_membership_service`,
/// `group_realtime_sync_mixin`, `comments_cubit`, `chat_mute_service`,
/// `conversations_cubit`, ...). Several of them defensively loop over
/// `getChannels()` and remove a same-named channel before creating a new
/// one — which is itself evidence that duplicate/zombie channels were a
/// real production problem (V6: H-02/H-03, C-02).
///
/// Nothing in the app currently knows how many channels are open, who owns
/// them, or whether yesterday's account still has some. This registry
/// answers exactly those questions and turns each of them into a
/// Crashlytics signal.
class RealtimeDiagnostics {
  RealtimeDiagnostics._();

  static final RealtimeDiagnostics instance = RealtimeDiagnostics._();

  @visibleForTesting
  static void resetForTest() => instance._channels.clear();

  final Map<String, ChannelRecord> _channels = {};

  /// Above this, something is leaking. Sized generously: a busy session
  /// legitimately holds feed + conversations + presence + mute + block +
  /// an open chat + an open group + comments.
  static const int suspiciousChannelCount = 24;

  List<ChannelRecord> get active =>
      _channels.values.where((c) => c.isLive).toList(growable: false);

  int get activeCount => active.length;

  ChannelRecord? recordFor(String topic) => _channels[topic];

  /// Call immediately before `.subscribe()`.
  void onChannelCreated(String topic, {required String ownerUserId}) {
    final existing = _channels[topic];
    if (existing != null && existing.isLive) {
      // A second live channel on the same topic means two subscriptions are
      // racing: duplicate Realtime events, doubled unread counts, and the
      // "message appears twice" class of bug.
      obs.recordError(
        DuplicateRealtimeSubscription(topic),
        StackTrace.current,
        category: ErrorCategory.realtime,
        feature: 'realtime',
        operation: 'subscribe',
        reason: 'duplicate subscription on $topic',
      );
    }

    _channels[topic] = ChannelRecord(
      topic: topic,
      ownerUserId: ownerUserId,
      createdAt: DateTime.now(),
    );

    obs.breadcrumb('channel created: $topic', feature: 'realtime');
    _checkPressure();
  }

  void onChannelSubscribed(String topic) {
    final record = _channels[topic];
    if (record == null) return;
    if (record.phase == ChannelPhase.errored) {
      record.reconnectCount++;
      obs.breadcrumb(
        'channel recovered: $topic (reconnect #${record.reconnectCount})',
        feature: 'realtime',
      );
    }
    record.phase = ChannelPhase.subscribed;
    obs.setContext('realtime_active_channels', activeCount);
  }

  void onChannelError(String topic, Object error, StackTrace? stack) {
    final record = _channels[topic];
    record?.phase = ChannelPhase.errored;
    record?.errorCount++;

    obs.recordError(
      error,
      stack,
      category: ErrorCategory.realtime,
      feature: 'realtime',
      operation: 'channel_error',
      reason: 'topic=$topic errors=${record?.errorCount ?? 0}',
    );
  }

  void onChannelClosed(String topic) {
    final record = _channels[topic];
    if (record == null) return;
    record.phase = ChannelPhase.closed;
    _channels.remove(topic);
    obs.breadcrumb('channel closed: $topic', feature: 'realtime');
    obs.setContext('realtime_active_channels', activeCount);
  }

  /// Called right after an account switch completes.
  ///
  /// Any channel still live but owned by a different account is a zombie:
  /// it will keep delivering the previous user's rows into the new user's
  /// UI. This is the mechanism behind V6 finding C-02.
  List<ChannelRecord> detectZombies(String currentUserId) {
    final zombies =
        active.where((c) => c.ownerUserId != currentUserId).toList();

    if (zombies.isNotEmpty) {
      obs.recordError(
        ZombieRealtimeChannels(zombies.map((z) => z.topic).toList()),
        StackTrace.current,
        category: ErrorCategory.realtime,
        feature: 'realtime',
        operation: 'account_switch',
        reason: '${zombies.length} channel(s) survived an account switch',
      );
    }

    return zombies;
  }

  void _checkPressure() {
    if (activeCount <= suspiciousChannelCount) return;
    obs.recordError(
      RealtimeChannelPressure(activeCount),
      StackTrace.current,
      category: ErrorCategory.realtime,
      feature: 'realtime',
      operation: 'pressure_check',
      reason: 'active=$activeCount topics=${active.map((c) => c.topic)}',
    );
  }
}

class DuplicateRealtimeSubscription implements Exception {
  const DuplicateRealtimeSubscription(this.topic);
  final String topic;

  @override
  String toString() => 'DuplicateRealtimeSubscription: $topic';
}

class ZombieRealtimeChannels implements Exception {
  const ZombieRealtimeChannels(this.topics);
  final List<String> topics;

  @override
  String toString() =>
      'ZombieRealtimeChannels: ${topics.length} channel(s) survived an '
      'account switch';
}

class RealtimeChannelPressure implements Exception {
  const RealtimeChannelPressure(this.activeCount);
  final int activeCount;

  @override
  String toString() => 'RealtimeChannelPressure: $activeCount active channels';
}
