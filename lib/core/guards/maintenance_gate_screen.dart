import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/core/guards/blocking_screen_scaffold.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import 'package:social_media_app/core/services/app_system_status.dart';

/// Non-dismissible full-screen overlay shown while
/// `maintenance_active == true && maintenance_bypassed == false`.
///
/// Shows the admin-written message (falling back to a localized default), the
/// expected end time when the server knows one, a "Check again" button, and,
/// for signed-out staff, an entry to the login screen (see `decideGate`).
class MaintenanceGateScreen extends StatefulWidget {
  const MaintenanceGateScreen({
    super.key,
    required this.status,
    required this.onRetry,
    required this.isAuthenticated,
    this.onStaffSignIn,
    this.onSignOut,
  });

  final AppSystemStatus status;

  /// Re-fetches the status; the gate disappears by itself when it is lifted.
  final Future<void> Function() onRetry;
  final bool isAuthenticated;

  /// Offered to signed-out users only.
  final VoidCallback? onStaffSignIn;

  /// Offered to signed-in users who are not on the bypass list.
  final Future<void> Function()? onSignOut;

  @override
  State<MaintenanceGateScreen> createState() => _MaintenanceGateScreenState();
}

class _MaintenanceGateScreenState extends State<MaintenanceGateScreen> {
  bool _checking = false;

  Future<void> _retry() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final endsAt = widget.status.maintenanceEndsAt;
    final message = widget.status.maintenanceMessage;

    String? backAt;
    if (endsAt != null && endsAt.isAfter(DateTime.now())) {
      final locale = Localizations.localeOf(context).toString();
      backAt = l10n.systemMaintenanceBackAt(
        DateFormat.yMMMd(locale).add_jm().format(endsAt),
      );
    }

    return BlockingScreenScaffold(
      icon: Icons.construction_rounded,
      title: l10n.systemMaintenanceTitle,
      children: [
        Text(
          message ?? l10n.systemMaintenanceDefaultMessage,
          textAlign: TextAlign.center,
          style: blockingBodyStyle(context),
        ),
        if (backAt != null) ...[
          const SizedBox(height: 12),
          Text(
            backAt,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
        ],
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: _checking ? null : _retry,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon:
              _checking
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.refresh_rounded),
          label: Text(
            _checking
                ? l10n.systemMaintenanceChecking
                : l10n.systemMaintenanceRetry,
          ),
        ),
        const SizedBox(height: 8),
        if (!widget.isAuthenticated && widget.onStaffSignIn != null)
          TextButton(
            onPressed: widget.onStaffSignIn,
            child: Text(l10n.systemMaintenanceStaffSignIn),
          ),
        if (widget.isAuthenticated && widget.onSignOut != null)
          TextButton(
            onPressed: () => widget.onSignOut!(),
            child: Text(l10n.systemSignOut),
          ),
      ],
    );
  }
}
