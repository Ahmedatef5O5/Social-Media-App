import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/guards/force_update_dialog.dart';
import 'package:social_media_app/core/guards/maintenance_gate_screen.dart';
import 'package:social_media_app/core/guards/suspension_interceptor.dart';
import 'package:social_media_app/core/guards/system_banner.dart';
import 'package:social_media_app/core/guards/system_gate_decision.dart';
import 'package:social_media_app/core/services/system_control_service.dart';
import 'package:social_media_app/features/auth/cubits/auth_cubit/auth_cubit.dart';

/// Hosts Remote App Control (Feature B) around the app.
///
/// Mount it in `MaterialApp.builder`, wrapping the navigator:
///
///     SystemControlGate(child: activeChild)
///
/// It lays out `[banners, app]`, and when [decideGate] says the app is blocked
/// it draws the matching screen over the app and removes the app from focus and
/// semantics. The app subtree itself is never rebuilt or re-parented, so
/// navigation state, calls and playback survive a maintenance window.
class SystemControlGate extends StatefulWidget {
  const SystemControlGate({
    super.key,
    required this.child,
    this.service,
    this.onSignOut,
    this.openStore = openStoreUrl,
    this.storeUrl,
  });

  final Widget child;

  /// Defaults to [SystemControlService.instance].
  final SystemControlService? service;

  /// Defaults to `AuthCubit.signOut()`.
  final Future<void> Function(BuildContext context)? onSignOut;
  final StoreOpener openStore;
  final String? storeUrl;

  @override
  State<SystemControlGate> createState() => _SystemControlGateState();
}

class _SystemControlGateState extends State<SystemControlGate> {
  final Set<String> _dismissed = <String>{};

  SystemControlService get _service =>
      widget.service ?? SystemControlService.instance;

  Future<void> _signOut() async {
    final custom = widget.onSignOut;
    if (custom != null) return custom(context);
    try {
      await context.read<AuthCubit>().signOut();
    } catch (e) {
      debugPrint('[SystemControlGate] sign out failed: $e');
    }
  }

  void _openStore() {
    final url = widget.storeUrl ?? StoreLinks.url;
    if (url.isEmpty) return;
    widget.openStore(url);
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    return ListenableBuilder(
      listenable: Listenable.merge([
        service.status,
        service.staffSignInMode,
        service.authEpoch,
      ]),
      builder: (context, _) {
        final status = service.status.value;
        final authenticated = service.isAuthenticated;
        final gate = decideGate(
          status,
          authenticated: authenticated,
          staffSignInMode: service.staffSignInMode.value,
        );
        final blocked = gate != GateScreen.none;

        final bannerVisible =
            !blocked &&
            (shouldShowBroadcastBanner(status, _dismissed) ||
                shouldShowRecommendedUpdate(status, _dismissed));

        final content = Column(
          children: [
            if (bannerVisible)
              SafeArea(
                bottom: false,
                child: SystemBannerStack(
                  status: status,
                  dismissed: _dismissed,
                  onDismiss: (key) => setState(() => _dismissed.add(key)),
                  onUpdate:
                      (widget.storeUrl ?? StoreLinks.url).isEmpty
                          ? null
                          : _openStore,
                ),
              )
            else
              const SizedBox.shrink(),
            Expanded(
              // The banner already consumed the status-bar inset.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: bannerVisible,
                child: widget.child,
              ),
            ),
          ],
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            ExcludeFocus(
              excluding: blocked,
              child: ExcludeSemantics(excluding: blocked, child: content),
            ),
            if (blocked)
              Positioned.fill(child: _screenFor(gate, authenticated)),
          ],
        );
      },
    );
  }

  Widget _screenFor(GateScreen gate, bool authenticated) {
    final service = _service;
    switch (gate) {
      case GateScreen.maintenance:
        return MaintenanceGateScreen(
          key: const ValueKey('gate-maintenance'),
          status: service.status.value,
          isAuthenticated: authenticated,
          onRetry: () => service.refresh(force: true),
          onStaffSignIn: service.enterStaffSignInMode,
          onSignOut: _signOut,
        );
      case GateScreen.forceUpdate:
        return ForceUpdateDialog(
          key: const ValueKey('gate-update'),
          status: service.status.value,
          storeUrl: widget.storeUrl,
          openStore: widget.openStore,
        );
      case GateScreen.suspended:
        return SuspensionScreen(
          key: const ValueKey('gate-suspended'),
          status: service.status.value,
          onSignOut: _signOut,
          onCheckAgain: () => service.refresh(force: true),
        );
      case GateScreen.none:
        return const SizedBox.shrink();
    }
  }
}
