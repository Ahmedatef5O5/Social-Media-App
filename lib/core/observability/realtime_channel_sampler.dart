import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_provider.dart';
import 'realtime_diagnostics.dart';

class RealtimeChannelSampler {
  RealtimeChannelSampler._();

  static final RealtimeChannelSampler instance = RealtimeChannelSampler._();

  static const Duration interval = Duration(seconds: 30);

  Timer? _timer;
  String? _owner;

  /// Idempotent. Safe to call once Supabase is initialized.
  void start() {
    _timer ??= Timer.periodic(interval, (_) => sample());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Account that newly discovered channels are attributed to.
  /// Null while signed out.
  void setOwner(String? userId) => _owner = userId;

  /// Takes one snapshot. Never throws: diagnostics must not break the app.
  void sample() {
    try {
      final channels = SupabaseProvider.client.getChannels();
      RealtimeDiagnostics.instance.observe(
        channels.map((c) => ObservedChannel(c.topic, _phaseOf(c))),
        owner: _owner,
      );
    } catch (_) {
      // Client not ready or being torn down; the next tick will retry.
    }
  }

  static ChannelPhase _phaseOf(RealtimeChannel c) {
    if (c.isJoined) return ChannelPhase.subscribed;
    if (c.isErrored) return ChannelPhase.errored;
    if (c.isClosed || c.isLeaving) return ChannelPhase.closed;
    return ChannelPhase.creating;
  }
}
