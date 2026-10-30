import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/core/guards/blocking_screen_scaffold.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import 'package:social_media_app/core/services/app_system_status.dart';
import 'package:social_media_app/core/services/system_control_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../localization/app_l10n.dart';
import '../toast/app_toast.dart';

/// Account suspension, client side.
///
/// ENFORCEMENT IS SERVER-SIDE: migration 015 adds RESTRICTIVE RLS policies, so
/// a suspended user's reads/writes on posts, comments, stories, messages and
/// likes are rejected by Postgres no matter what the client does. This file
/// only makes that state visible:
///   * [SuspensionScreen]: reason, expiry, sign-out (shown by the gate when
///     `is_caller_suspended == true`), and
///   * [SuspensionInterceptor]: when a request fails with an RLS/permission
///     error, re-check the status immediately instead of waiting for the next
///     poll, so the screen appears on the very first rejected action.
class SuspensionInterceptor {
  SuspensionInterceptor._();

  static DateTime? _lastCheck;
  static const Duration _minGap = Duration(seconds: 20);

  /// RLS rejections surface as SQLSTATE 42501 / "row-level security".
  /// They are not unique to suspension, which is why this only *triggers a
  /// status check* and never decides anything itself.
  static bool looksLikePermissionRejection(Object error) {
    if (error is! PostgrestException) return false;
    final msg = error.message.toLowerCase();
    return error.code == '42501' ||
        msg.contains('row-level security') ||
        msg.contains('permission denied');
  }

  /// Call from any catch block that sees a backend error. Cheap and safe to
  /// call often: throttled, fire-and-forget, never throws.
  static void onError(
    Object error, {
    SystemControlService? service,
    DateTime Function()? now,
  }) {
    if (!looksLikePermissionRejection(error)) return;
    final clock = (now ?? DateTime.now)();
    final last = _lastCheck;
    if (last != null && clock.difference(last) < _minGap) return;
    _lastCheck = clock;
    (service ?? SystemControlService.instance).refresh(force: true);
  }

  /// Wraps a backend call: runs [call], lets [onError] observe a failure, and
  /// rethrows it unchanged so existing error handling is unaffected.
  static Future<T> guard<T>(
    Future<T> Function() call, {
    SystemControlService? service,
  }) async {
    try {
      return await call();
    } catch (e) {
      onError(e, service: service);
      rethrow;
    }
  }

  @visibleForTesting
  static void resetThrottle() => _lastCheck = null;
}

/// Full-screen "account suspended" view with reason, expiry and sign-out.
class SuspensionScreen extends StatefulWidget {
  const SuspensionScreen({
    super.key,
    required this.status,
    required this.onSignOut,
    required this.onCheckAgain,
  });

  final AppSystemStatus status;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onCheckAgain;

  @override
  State<SuspensionScreen> createState() => _SuspensionScreenState();
}

class _SuspensionScreenState extends State<SuspensionScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleCheckAgain() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onCheckAgain();
      if (mounted) {
        final isStillSuspended =
            SystemControlService.instance.status.value.isCallerSuspended;
        if (isStillSuspended) {
          AppToast.warning(
            AppL10n.isArabic
                ? 'الحساب لا يزال موقوفاً'
                : 'Account is still suspended',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final expiresAt = widget.status.suspensionExpiresAt;
    final reason = widget.status.suspensionReason;
    final locale = Localizations.localeOf(context).toString();

    return BlockingScreenScaffold(
      icon: Icons.block_rounded,
      iconColor: theme.colorScheme.error,
      title: l10n.systemSuspendedTitle,
      children: [
        Text(
          l10n.systemSuspendedBody,
          textAlign: TextAlign.center,
          style: blockingBodyStyle(context),
        ),
        if (reason != null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.systemSuspendedReasonLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          expiresAt != null
              ? l10n.systemSuspendedUntil(
                DateFormat.yMMMd(locale).add_jm().format(expiresAt),
              )
              : l10n.systemSuspendedPermanent,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: _busy ? null : () => _run(widget.onSignOut),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: Text(l10n.systemSignOut),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _busy ? null : _handleCheckAgain,
          icon:
              _busy
                  ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.refresh_rounded, size: 18),
          label: Text(
            _busy
                ? (AppL10n.isArabic ? 'جاري التحقق...' : 'Checking...')
                : l10n.systemSuspendedCheckAgain,
          ),
        ),
      ],
    );
  }
}
