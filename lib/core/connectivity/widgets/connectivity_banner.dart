import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../router/app_routes.dart';
import '../../services/active_screen_tracker.dart';
import '../cubit/connectivity_cubit.dart';
import '../cubit/connectivity_state.dart';
import '../services/connectivity_banner_controller.dart';

enum _BannerMode { hidden, offline, restored }

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  _BannerMode _mode = _BannerMode.hidden;
  Timer? _autoHideTimer;
  bool _wasOffline = false;

  static const Duration _offlineVisibleFor = Duration(seconds: 5);
  static const Duration _restoredVisibleFor = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    ConnectivityBannerController.offlineFlashTrigger.addListener(
      _onOfflineFlashRequested,
    );
  }

  bool get _isOnSplashScreen =>
      ActiveScreenTracker.currentRoute == null ||
      ActiveScreenTracker.currentRoute == AppRoutes.splashViewRoute;

  void _onOfflineFlashRequested() {
    if (_isOnSplashScreen) return;
    _show(_BannerMode.offline, _offlineVisibleFor);
  }

  void _handleConnectivityChange(
    BuildContext context,
    ConnectivityState state,
  ) {
    if (state is ConnectivityOffline) {
      _wasOffline = true;
      return;
    }

    if (state is ConnectivityOnline) {
      if (!_wasOffline) return;
      _wasOffline = false;
      if (_isOnSplashScreen) return;
      _show(_BannerMode.restored, _restoredVisibleFor);
    }
  }

  void _show(_BannerMode mode, Duration visibleFor) {
    _autoHideTimer?.cancel();
    setState(() => _mode = mode);
    _controller.forward(from: 0);
    _autoHideTimer = Timer(visibleFor, _hide);
  }

  Future<void> _hide() async {
    _autoHideTimer?.cancel();
    await _controller.reverse();
    if (mounted) setState(() => _mode = _BannerMode.hidden);
  }

  @override
  void dispose() {
    ConnectivityBannerController.offlineFlashTrigger.removeListener(
      _onOfflineFlashRequested,
    );
    _autoHideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityCubit, ConnectivityState>(
      listener: _handleConnectivityChange,
      child: IgnorePointer(
        ignoring: _mode == _BannerMode.hidden,
        child: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child:
                _mode == _BannerMode.hidden
                    ? const SizedBox.shrink()
                    : SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _FloatingStatusCard(
                          key: ValueKey(_mode),
                          isOffline: _mode == _BannerMode.offline,
                          onDismiss: _hide,
                        ),
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

class _FloatingStatusCard extends StatelessWidget {
  const _FloatingStatusCard({
    super.key,
    required this.isOffline,
    required this.onDismiss,
  });

  final bool isOffline;
  final VoidCallback onDismiss;

  static const Color _restoredColor = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color background =
        isOffline ? theme.colorScheme.error : _restoredColor;
    final Color onBackground =
        isOffline ? theme.colorScheme.onError : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 14, right: 14),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap:
              isOffline
                  ? () => context.read<ConnectivityCubit>().checkNow()
                  : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                  size: 18,
                  color: onBackground,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isOffline ? 'No internet connection' : 'Back to internet',
                    style: TextStyle(
                      color: onBackground,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: onBackground.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
