import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/connectivity_cubit.dart';
import '../cubit/connectivity_state.dart';

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

enum _BannerMode { hidden, offline, restored }

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  _BannerMode _mode = _BannerMode.hidden;
  Timer? _restoredTimer;

  static const Duration _restoredVisibleFor = Duration(
    seconds: 2,
    milliseconds: 500,
  );

  void _handleStateChange(BuildContext context, ConnectivityState state) {
    final wasOffline = _mode == _BannerMode.offline;

    if (state is ConnectivityOffline) {
      _restoredTimer?.cancel();
      setState(() => _mode = _BannerMode.offline);
      return;
    }

    if (state is ConnectivityOnline) {
      if (!wasOffline) return; // quiet startup — nothing to celebrate

      setState(() => _mode = _BannerMode.restored);
      _restoredTimer?.cancel();
      _restoredTimer = Timer(_restoredVisibleFor, () {
        if (mounted) setState(() => _mode = _BannerMode.hidden);
      });
    }
  }

  @override
  void dispose() {
    _restoredTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityCubit, ConnectivityState>(
      listener: _handleStateChange,
      child: IgnorePointer(
        ignoring: _mode == _BannerMode.hidden,
        child: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child:
                  _mode == _BannerMode.hidden
                      ? const SizedBox(width: double.infinity, height: 0)
                      : _StatusBar(
                        key: ValueKey(_mode),
                        isOffline: _mode == _BannerMode.offline,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({super.key, required this.isOffline});

  final bool isOffline;

  static const Color _restoredColor = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color background =
        isOffline ? theme.colorScheme.error : _restoredColor;

    return GestureDetector(
      onTap:
          isOffline ? () => context.read<ConnectivityCubit>().checkNow() : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 7),
        color: background,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 7),
            Text(
              isOffline ? 'No internet connection' : 'Back online',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
