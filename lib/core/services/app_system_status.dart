import 'package:flutter/foundation.dart';

/// Severity of the broadcast banner (`app_system_control.banner_severity`).
enum SystemBannerSeverity {
  info,
  warning,
  critical;

  static SystemBannerSeverity parse(Object? raw) {
    switch (raw) {
      case 'warning':
        return SystemBannerSeverity.warning;
      case 'critical':
        return SystemBannerSeverity.critical;
      default:
        return SystemBannerSeverity.info;
    }
  }
}

/// Typed mirror of the JSON returned by `public.get_app_system_status`
/// (migration 015). Every field is optional-safe so a partial or older payload
/// can never crash the app: anything missing means "nothing is restricted".
@immutable
class AppSystemStatus {
  const AppSystemStatus({
    this.maintenanceEnabled = false,
    this.maintenanceActive = false,
    this.maintenanceBypassed = false,
    this.maintenanceMessage,
    this.maintenanceStartsAt,
    this.maintenanceEndsAt,
    this.minSupportedVersion,
    this.recommendedVersion,
    this.updateRequired = false,
    this.updateRecommended = false,
    this.bannerMessage,
    this.bannerSeverity = SystemBannerSeverity.info,
    this.isCallerSuspended = false,
    this.suspensionReason,
    this.suspensionExpiresAt,
    this.serverTime,
  });

  /// Nothing restricted. Used before the first successful fetch and whenever
  /// the backend cannot be reached (fail-open: telemetry of a control plane
  /// must never lock users out of an app that otherwise works offline).
  static const AppSystemStatus open = AppSystemStatus();

  final bool maintenanceEnabled;

  /// Master switch AND inside the optional time window (decided server-side).
  final bool maintenanceActive;

  /// The caller is on the bypass list (user id or admin role).
  final bool maintenanceBypassed;
  final String? maintenanceMessage;
  final DateTime? maintenanceStartsAt;
  final DateTime? maintenanceEndsAt;
  final String? minSupportedVersion;
  final String? recommendedVersion;
  final bool updateRequired;
  final bool updateRecommended;
  final String? bannerMessage;
  final SystemBannerSeverity bannerSeverity;
  final bool isCallerSuspended;
  final String? suspensionReason;

  /// null while suspended = permanent.
  final DateTime? suspensionExpiresAt;
  final DateTime? serverTime;

  /// Maintenance applies to this caller.
  bool get blocksForMaintenance => maintenanceActive && !maintenanceBypassed;

  bool get hasBanner => (bannerMessage ?? '').trim().isNotEmpty;

  /// Parses the RPC payload. Returns null when it is not a successful status
  /// object, so callers keep their last known state instead of resetting it.
  static AppSystemStatus? tryParse(Object? raw) {
    if (raw is! Map) return null;
    if (raw['ok'] != true) return null;

    bool flag(String key) => raw[key] == true;
    String? text(String key) {
      final v = raw[key];
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    DateTime? time(String key) {
      final v = raw[key];
      return v is String ? DateTime.tryParse(v)?.toLocal() : null;
    }

    return AppSystemStatus(
      maintenanceEnabled: flag('maintenance_enabled'),
      maintenanceActive: flag('maintenance_active'),
      maintenanceBypassed: flag('maintenance_bypassed'),
      maintenanceMessage: text('maintenance_message'),
      maintenanceStartsAt: time('maintenance_starts_at'),
      maintenanceEndsAt: time('maintenance_ends_at'),
      minSupportedVersion: text('min_supported_version'),
      recommendedVersion: text('recommended_version'),
      updateRequired: flag('update_required'),
      updateRecommended: flag('update_recommended'),
      bannerMessage: text('banner_message'),
      bannerSeverity: SystemBannerSeverity.parse(raw['banner_severity']),
      isCallerSuspended: flag('is_caller_suspended'),
      suspensionReason: text('suspension_reason'),
      suspensionExpiresAt: time('suspension_expires_at'),
      serverTime: time('server_time'),
    );
  }

  List<Object?> get _props => [
    maintenanceEnabled,
    maintenanceActive,
    maintenanceBypassed,
    maintenanceMessage,
    maintenanceStartsAt,
    maintenanceEndsAt,
    minSupportedVersion,
    recommendedVersion,
    updateRequired,
    updateRecommended,
    bannerMessage,
    bannerSeverity,
    isCallerSuspended,
    suspensionReason,
    suspensionExpiresAt,
  ];

  /// `serverTime` is deliberately excluded: it changes on every fetch and must
  /// not make listeners rebuild when nothing user-visible changed.
  @override
  bool operator ==(Object other) =>
      other is AppSystemStatus && listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);
}
