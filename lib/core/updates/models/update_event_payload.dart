import 'dart:convert';

enum UpdateEventType {
  patchAvailable('patch_available'),
  patchDownloaded('patch_downloaded'),
  patchInstalled('patch_installed'),
  confirmedRunning('confirmed_running'),
  updateFailed('update_failed');

  const UpdateEventType(this.wire);
  final String wire;

  static UpdateEventType? tryParse(String? raw) {
    for (final v in values) {
      if (v.wire == raw) return v;
    }
    return null;
  }
}

/// One telemetry event, exactly the arguments of `record_update_telemetry`.
class UpdateEventPayload {
  const UpdateEventPayload({
    required this.deviceId,
    required this.platform,
    required this.type,
    required this.releaseVersion,
    required this.appVersion,
    required this.osVersion,
    required this.deviceModel,
    required this.occurredAt,
    this.patchNumber,
    this.currentPatch,
    this.details = const {},
    this.errorMessage,
  });

  final String deviceId;
  final String platform;
  final UpdateEventType type;
  final String releaseVersion;
  final String appVersion;
  final String osVersion;
  final String deviceModel;
  final DateTime occurredAt;
  final int? patchNumber;
  final int? currentPatch;
  final Map<String, Object?> details;
  final String? errorMessage;

  /// RPC parameter map. The queue timestamp travels inside `details` so a
  /// replayed event can still be told apart from a live one.
  Map<String, Object?> toRpcParams() => {
    'p_device_id': deviceId,
    'p_platform': platform,
    'p_event_type': type.wire,
    'p_release_version': releaseVersion,
    'p_patch_number': patchNumber,
    'p_current_patch': currentPatch,
    'p_app_version': appVersion,
    'p_os_version': osVersion,
    'p_device_model': deviceModel,
    'p_details': {
      ...details,
      'client_ts': occurredAt.toUtc().toIso8601String(),
    },
    'p_error_message': errorMessage,
  };

  Map<String, Object?> toJson() => {
    'device_id': deviceId,
    'platform': platform,
    'type': type.wire,
    'release_version': releaseVersion,
    'app_version': appVersion,
    'os_version': osVersion,
    'device_model': deviceModel,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'patch_number': patchNumber,
    'current_patch': currentPatch,
    'details': details,
    'error_message': errorMessage,
  };

  /// Returns `null` for a corrupt entry so one bad row never poisons the queue.
  static UpdateEventPayload? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final type = UpdateEventType.tryParse(raw['type'] as String?);
    final occurred = DateTime.tryParse('${raw['occurred_at']}');
    final device = raw['device_id'];
    if (type == null || occurred == null || device is! String) return null;
    final details = raw['details'];
    return UpdateEventPayload(
      deviceId: device,
      platform: '${raw['platform']}',
      type: type,
      releaseVersion: '${raw['release_version'] ?? ''}',
      appVersion: '${raw['app_version'] ?? ''}',
      osVersion: '${raw['os_version'] ?? ''}',
      deviceModel: '${raw['device_model'] ?? ''}',
      occurredAt: occurred,
      patchNumber: raw['patch_number'] as int?,
      currentPatch: raw['current_patch'] as int?,
      details: details is Map ? Map<String, Object?>.from(details) : const {},
      errorMessage: raw['error_message'] as String?,
    );
  }

  static String encodeList(List<UpdateEventPayload> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<UpdateEventPayload> decodeList(String? source) {
    if (source == null || source.isEmpty) return const [];
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List) return const [];
      return decoded
          .map(UpdateEventPayload.tryFromJson)
          .whereType<UpdateEventPayload>()
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
