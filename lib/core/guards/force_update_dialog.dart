import 'package:flutter/material.dart';
import 'package:social_media_app/core/guards/blocking_screen_scaffold.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';
import 'package:social_media_app/core/services/app_system_status.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where "Update now" sends the user.
///
/// Android defaults to this app's Play Store page. iOS needs the numeric App
/// Store id, which is not in the repo: supply it at build time with
/// `--dart-define=IOS_APP_STORE_URL=https://apps.apple.com/app/id<ID>`.
/// `STORE_URL` overrides both platforms (e.g. for an alternative store).
class StoreLinks {
  StoreLinks._();

  static const String _override = String.fromEnvironment('STORE_URL');
  // static const String _ios = String.fromEnvironment('IOS_APP_STORE_URL');
  static const String _downloadUrl =
      'https://www.ahmedatef.tech/projects/social-mate#download-cards';

  /// Direct download page on portfolio.
  static String get url {
    if (_override.isNotEmpty) return _override;
    return _downloadUrl;
  }
}

/// Opens [url] in the store app/browser; returns false when it cannot.
typedef StoreOpener = Future<bool> Function(String url);

Future<bool> openStoreUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Blocking "update required" screen (`update_required == true`). There is no
/// dismiss action: the only way forward is installing a newer build.
class ForceUpdateDialog extends StatefulWidget {
  const ForceUpdateDialog({
    super.key,
    required this.status,
    this.storeUrl,
    this.openStore = openStoreUrl,
  });

  final AppSystemStatus status;

  /// Defaults to [StoreLinks.url].
  final String? storeUrl;
  final StoreOpener openStore;

  @override
  State<ForceUpdateDialog> createState() => _ForceUpdateDialogState();
}

class _ForceUpdateDialogState extends State<ForceUpdateDialog> {
  bool _failed = false;

  String get _url => widget.storeUrl ?? StoreLinks.url;

  Future<void> _update() async {
    final ok = await widget.openStore(_url);
    if (mounted) setState(() => _failed = !ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hasUrl = _url.isNotEmpty;
    final version = widget.status.minSupportedVersion ?? '';

    return BlockingScreenScaffold(
      icon: Icons.system_update_rounded,
      title: l10n.systemUpdateRequiredTitle,
      children: [
        Text(
          l10n.systemUpdateRequiredBody(version),
          textAlign: TextAlign.center,
          style: blockingBodyStyle(context),
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: hasUrl ? _update : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.download_rounded),
          label: Text(l10n.systemUpdateNow),
        ),
        if (!hasUrl || _failed) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              hasUrl
                  ? l10n.systemUpdateOpenStoreFailed
                  : l10n.systemUpdateStoreUnavailable,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
