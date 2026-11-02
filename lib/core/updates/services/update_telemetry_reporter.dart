import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/network_status_service.dart';
import '../models/update_event_payload.dart';

typedef TelemetrySender = Future<void> Function(UpdateEventPayload event);

/// Sends update lifecycle events through `record_update_telemetry`.
///
/// * [report] never throws; the only network work is one flush attempt.
/// * Offline / failing sends are queued in a ring buffer (max [maxQueue], oldest
///   dropped) and mirrored to SharedPreferences so a restart does not lose them
///   (a failed patch often ends in a restart).
class UpdateTelemetryReporter {
  UpdateTelemetryReporter({
    TelemetrySender? sender,
    Future<bool> Function()? isOnline,
    SharedPreferences? prefs,
    this.maxQueue = 30,
  }) : _sender = sender ?? _defaultSender,
       _isOnline = isOnline ?? NetworkStatusService.instance.isConnected,
       _prefs = prefs;

  static const String queuePrefsKey = 'update_telemetry_queue_v1';

  final TelemetrySender _sender;
  final Future<bool> Function() _isOnline;
  final SharedPreferences? _prefs;
  final int maxQueue;

  final Queue<UpdateEventPayload> _queue = Queue<UpdateEventPayload>();
  bool _loaded = false;
  bool _flushing = false;
  bool enabled = true;

  @visibleForTesting
  List<UpdateEventPayload> get pending => List.unmodifiable(_queue);

  static Future<void> _defaultSender(UpdateEventPayload event) async {
    await Supabase.instance.client.rpc(
      'record_update_telemetry',
      params: event.toRpcParams(),
    );
  }

  /// Enqueues [event] and tries to deliver the queue. Never throws.
  Future<void> report(UpdateEventPayload event) async {
    if (!enabled) return;
    try {
      await _ensureLoaded();
      _enqueue(event);
      await _persist();
      await flush();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ update telemetry report failed: $e');
    }
  }

  /// Delivers queued events oldest-first; stops at the first failure so order
  /// is preserved. Safe to call concurrently (second caller returns at once).
  Future<void> flush() async {
    if (_flushing || !enabled) return;
    _flushing = true;
    try {
      await _ensureLoaded();
      if (_queue.isEmpty) return;
      if (!await _isOnline()) return;
      while (_queue.isNotEmpty) {
        final next = _queue.first;
        try {
          await _sender(next);
        } catch (_) {
          break; // keep it (and everything behind it) for the next attempt
        }
        _queue.removeFirst();
      }
      await _persist();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ update telemetry flush failed: $e');
    } finally {
      _flushing = false;
    }
  }

  void _enqueue(UpdateEventPayload event) {
    while (_queue.length >= maxQueue) {
      _queue.removeFirst();
    }
    _queue.addLast(event);
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final restored = UpdateEventPayload.decodeList(prefs.getString(queuePrefsKey));
      for (final e in restored) {
        _enqueue(e);
      }
    } catch (_) {
      // Corrupt / unavailable storage: start with an empty queue.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      if (_queue.isEmpty) {
        await prefs.remove(queuePrefsKey);
      } else {
        await prefs.setString(
          queuePrefsKey,
          UpdateEventPayload.encodeList(_queue.toList()),
        );
      }
    } catch (_) {
      // In-memory queue still works.
    }
  }
}
