import 'dart:async';
import 'package:flutter/foundation.dart';
import '../supabase/supabase_provider.dart';
import 'error_category.dart';
import 'observability.dart';

/// Lifecycle state of a Supabase Realtime channel as this app cares about
/// it. Deliberately not tied to `RealtimeSubscribeStatus` so the registry
/// stays unit-testable without the Supabase SDK.
enum ChannelPhase { creating, subscribed, errored, closed }

/// A channel as seen by the SDK, decoupled from `RealtimeChannel` so the
/// registry stays unit-testable without the Supabase SDK.
class ObservedChannel {
  const ObservedChannel(this.topic, this.phase);

  final String topic;
  final ChannelPhase phase;
}

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

  /// Clears the registry completely upon sign-out so no channels are leaked
  /// to the next account.
  void reset() {
    _channels.clear();
    _reportedDuplicates.clear();
    _pressureLatched = false;
    obs.setContext('realtime_active_channels', 0);
  }

  @visibleForTesting
  static void resetForTest() => instance.reset();

  final Map<String, ChannelRecord> _channels = {};

  /// Topics whose duplication has already been reported. Cleared per topic
  /// once the duplicate disappears, so a later recurrence is reported again.
  final Set<String> _reportedDuplicates = {};

  /// True while the pressure error has been sent and the count has not yet
  /// dropped back under [suspiciousChannelCount].
  bool _pressureLatched = false;

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

      // Self-Healing: close zombie channels and remove it
      for (final z in zombies) {
        try {
          final c = SupabaseProvider.client.channel(z.topic);
          unawaited(SupabaseProvider.client.removeChannel(c));
        } catch (_) {}
        _channels.remove(z.topic);
      }
      obs.setContext('realtime_active_channels', activeCount);
    }

    return zombies;
  }

  /// The SDK prefixes every topic with `realtime:`; explicit registrations
  /// use either form. Compare on the bare name.
  static String _normalize(String topic) =>
      topic.startsWith('realtime:') ? topic.substring(9) : topic;

  static bool _isLivePhase(ChannelPhase p) =>
      p == ChannelPhase.creating || p == ChannelPhase.subscribed;

  /// Reconciles the registry with what the SDK actually holds.
  ///
  /// [owner] is the account to attribute *newly discovered* channels to.
  /// Channels already registered keep their original owner, which is what
  /// makes a channel opened by account A and still alive after the switch
  /// to account B detectable as a zombie. With a null [owner] (signed out)
  /// unknown channels are not registered.
  void observe(Iterable<ObservedChannel> channels, {required String? owner}) {
    final livePerTopic = <String, int>{};
    final phaseOf = <String, ChannelPhase>{};
    final originalTopic = <String, String>{};

    for (final c in channels) {
      final key = _normalize(c.topic);
      originalTopic.putIfAbsent(key, () => c.topic);
      if (_isLivePhase(c.phase)) {
        livePerTopic[key] = (livePerTopic[key] ?? 0) + 1;
      }
      final prev = phaseOf[key];
      if (prev == null || !_isLivePhase(prev)) phaseOf[key] = c.phase;
    }

    // 1) Drop records whose channel no longer exists in the SDK.
    _channels.removeWhere(
      (topic, _) => !phaseOf.containsKey(_normalize(topic)),
    );

    // 2) Register unknown live channels and refresh known ones.
    for (final entry in phaseOf.entries) {
      final key = entry.key;
      final sdkPhase = entry.value;

      ChannelRecord? record;
      for (final e in _channels.entries) {
        if (_normalize(e.key) == key) {
          record = e.value;
          break;
        }
      }

      if (record == null) {
        if (owner == null || !_isLivePhase(sdkPhase)) continue;
        record = ChannelRecord(
          topic: originalTopic[key]!,
          ownerUserId: owner,
          createdAt: DateTime.now(),
          phase: sdkPhase,
        );
        _channels[record.topic] = record;
        continue;
      }

      // The SDK reporting "creating" says nothing new; keep our own phase.
      if (sdkPhase == ChannelPhase.creating) continue;
      if (record.phase == ChannelPhase.errored &&
          sdkPhase == ChannelPhase.subscribed) {
        record.reconnectCount++;
      }
      record.phase = sdkPhase;
    }

    // 3) Duplicate live topics: report once per topic.
    _reportedDuplicates.removeWhere((t) => (livePerTopic[t] ?? 0) < 2);
    for (final e in livePerTopic.entries) {
      if (e.value < 2 || !_reportedDuplicates.add(e.key)) continue;
      obs.recordError(
        DuplicateRealtimeSubscription(e.key),
        StackTrace.current,
        category: ErrorCategory.realtime,
        feature: 'realtime',
        operation: 'sample',
        reason: '${e.value} live channels share topic ${e.key}',
      );
    }

    // 4) Pressure: report once per excursion above the threshold.
    if (activeCount > suspiciousChannelCount) {
      if (!_pressureLatched) {
        _pressureLatched = true;
        _checkPressure();
      }
    } else {
      _pressureLatched = false;
    }

    obs.setContext('realtime_active_channels', activeCount);
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
