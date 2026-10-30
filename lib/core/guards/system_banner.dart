import 'package:flutter/material.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import 'package:social_media_app/core/services/app_system_status.dart';

/// Stable keys used to remember what the user dismissed this session.
String broadcastBannerKey(AppSystemStatus s) =>
    'banner:${s.bannerSeverity.name}:${s.bannerMessage}';
String recommendedUpdateKey(AppSystemStatus s) =>
    'update:${s.recommendedVersion}';

/// What is visible given the status and the session's dismissals.
bool shouldShowBroadcastBanner(AppSystemStatus s, Set<String> dismissed) =>
    s.hasBanner && !dismissed.contains(broadcastBannerKey(s));

bool shouldShowRecommendedUpdate(AppSystemStatus s, Set<String> dismissed) =>
    s.updateRecommended &&
    !s.updateRequired &&
    !dismissed.contains(recommendedUpdateKey(s));

/// Top-of-app notices: the admin's in-app broadcast banner and, when
/// `update_recommended == true`, a dismissible "new version" bar.
/// `critical` broadcasts cannot be dismissed.
class SystemBannerStack extends StatelessWidget {
  const SystemBannerStack({
    super.key,
    required this.status,
    required this.dismissed,
    required this.onDismiss,
    required this.onUpdate,
  });

  final AppSystemStatus status;
  final Set<String> dismissed;
  final ValueChanged<String> onDismiss;

  /// Opens the store. Null hides the "Update" action.
  final VoidCallback? onUpdate;

  @override
  Widget build(BuildContext context) {
    final showBroadcast = shouldShowBroadcastBanner(status, dismissed);
    final showUpdate = shouldShowRecommendedUpdate(status, dismissed);
    if (!showBroadcast && !showUpdate) return const SizedBox.shrink();

    final l10n = context.l10n;
    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBroadcast)
            _BannerTile(
              key: const ValueKey('broadcast-banner'),
              color: _colorFor(status.bannerSeverity),
              foreground:
                  status.bannerSeverity == SystemBannerSeverity.warning
                      ? Colors.black87
                      : Colors.white,
              icon: _iconFor(status.bannerSeverity),
              message: status.bannerMessage!,
              dismissLabel: l10n.systemBannerDismiss,
              onDismiss:
                  status.bannerSeverity == SystemBannerSeverity.critical
                      ? null
                      : () => onDismiss(broadcastBannerKey(status)),
            ),
          if (showUpdate)
            _BannerTile(
              key: const ValueKey('update-banner'),
              color: Theme.of(context).primaryColor,
              foreground: Colors.white,
              icon: Icons.system_update_rounded,
              message: l10n.systemUpdateRecommendedMessage(
                status.recommendedVersion ?? '',
              ),
              actionLabel: onUpdate == null ? null : l10n.systemUpdateAction,
              onAction: onUpdate,
              dismissLabel: l10n.systemBannerDismiss,
              onDismiss: () => onDismiss(recommendedUpdateKey(status)),
            ),
        ],
      ),
    );
  }

  static Color _colorFor(SystemBannerSeverity s) {
    switch (s) {
      case SystemBannerSeverity.critical:
        return const Color(0xFFDC2626);
      case SystemBannerSeverity.warning:
        return const Color(0xFFF59E0B);
      case SystemBannerSeverity.info:
        return const Color(0xFF2563EB);
    }
  }

  static IconData _iconFor(SystemBannerSeverity s) {
    switch (s) {
      case SystemBannerSeverity.critical:
        return Icons.error_rounded;
      case SystemBannerSeverity.warning:
        return Icons.warning_amber_rounded;
      case SystemBannerSeverity.info:
        return Icons.info_rounded;
    }
  }
}

class _BannerTile extends StatelessWidget {
  const _BannerTile({
    super.key,
    required this.color,
    required this.foreground,
    required this.icon,
    required this.message,
    required this.dismissLabel,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final Color color;
  final Color foreground;
  final IconData icon;
  final String message;
  final String dismissLabel;
  final VoidCallback? onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: color,
        padding: const EdgeInsetsDirectional.only(start: 14, end: 4),
        child: Row(
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  message,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: foreground),
                child: Text(actionLabel!),
              ),
            if (onDismiss != null)
              Semantics(
                label: dismissLabel,
                button: true,
                child: IconButton(
                  onPressed: onDismiss,
                  icon: Icon(Icons.close_rounded, color: foreground, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
