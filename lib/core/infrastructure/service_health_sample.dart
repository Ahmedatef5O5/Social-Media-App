import '../observability/telemetry_scrubber.dart';

/// The eight services shown on the Infrastructure & Service Health Center.
///
/// [wireName] is the exact `service_key` accepted by the database
/// (`service_health_heartbeats.service_key`). `supabaseDb`, `supabaseAuth` and
/// `fcm` are measured server-side (active probes / `notification_dispatches`);
/// the client only reports the other five, but the enum keeps all eight so the
/// two sides can never drift apart.
enum HealthServiceKey {
  supabaseDb('supabase_db'),
  supabaseAuth('supabase_auth'),
  supabaseRealtime('supabase_realtime'),
  cloudinary('cloudinary'),
  livekit('livekit'),
  fcm('fcm'),
  aiGateway('ai_gateway'),
  hiveCache('hive_cache');

  const HealthServiceKey(this.wireName);

  final String wireName;
}

/// What `RealtimeDiagnostics` tells the health coordinator. Deliberately carries
/// NO topic: Realtime topics embed conversation / user ids, which must never
/// leave the device through the health pipeline.
enum RealtimeHealthEventType { subscribed, reconnected, errored }

typedef RealtimeHealthListener = void Function(RealtimeHealthEventType type);

/// One aggregated observation window for one service, as sent to
/// `public.record_service_telemetry_batch`.
///
/// PRIVACY CONTRACT (enforced here, again by the coordinator, and a third time
/// by the SQL function):
///  * no user id, device id, e-mail, topic, URL, file name or request body,
///  * free text is scrubbed with [TelemetryScrubber] and capped at 160 chars,
///  * [reasonCode] / [provider] are reduced to `[a-z0-9_.:-]`.
class ServiceHealthSample {
  const ServiceHealthSample({
    required this.service,
    required this.sampleCount,
    required this.errorCount,
    required this.observedAt,
    this.latencyP95Ms,
    this.reconnectsPerMin,
    this.degraded,
    this.reasonCode,
    this.provider,
    this.lastError,
  });

  final HealthServiceKey service;

  /// Number of calls / events folded into this window.
  final int sampleCount;

  /// How many of them failed. The server derives the error rate from the two
  /// counts; a rate computed on the client is never sent.
  final int errorCount;

  final DateTime observedAt;
  final int? latencyP95Ms;

  /// Realtime only.
  final double? reconnectsPerMin;

  /// `true` while the service works through a fallback (AI provider fallback,
  /// Hive box recreated). `null` means "no statement".
  final bool? degraded;

  final String? reasonCode;
  final String? provider;
  final String? lastError;

  static final RegExp _codeChars = RegExp(r'[^a-z0-9_.:\-]');

  /// Lower-cases and strips everything outside `[a-z0-9_.:-]`, then truncates.
  static String? sanitizeCode(String? value, {int maxLength = 64}) {
    if (value == null) return null;
    final cleaned = value.toLowerCase().replaceAll(_codeChars, '');
    if (cleaned.isEmpty) return null;
    return cleaned.length <= maxLength
        ? cleaned
        : cleaned.substring(0, maxLength);
  }

  /// JSON shape expected by the RPC. `null` fields are omitted.
  Map<String, dynamic> toJson() {
    final code = sanitizeCode(reasonCode);
    final prov = sanitizeCode(provider, maxLength: 32);
    final error = lastError == null
        ? null
        : TelemetryScrubber.scrubLine(lastError, maxLength: 160);

    return <String, dynamic>{
      'service_key': service.wireName,
      'sample_count': sampleCount,
      'error_count': errorCount,
      'observed_at': observedAt.toUtc().toIso8601String(),
      if (latencyP95Ms != null) 'latency_p95_ms': latencyP95Ms,
      if (reconnectsPerMin != null)
        'reconnects_per_min': double.parse(reconnectsPerMin!.toStringAsFixed(2)),
      if (degraded != null) 'degraded': degraded,
      if (code != null) 'reason_code': code,
      if (prov != null) 'provider': prov,
      if (error != null && error.isNotEmpty) 'last_error': error,
    };
  }

  @override
  String toString() =>
      'ServiceHealthSample(${service.wireName}, n=$sampleCount, errors=$errorCount)';
}
