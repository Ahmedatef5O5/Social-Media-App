import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/connectivity/cubits/connectivity_state.dart';
import '../../services/network_status_service.dart';

class ConnectivityCubit extends Cubit<ConnectivityState>
    with WidgetsBindingObserver {
  ConnectivityCubit({NetworkStatusService? networkStatus})
    : _networkStatus = networkStatus ?? NetworkStatusService.instance,
      super(ConnectivityInitial()) {
    _init();
  }

  final NetworkStatusService _networkStatus;

  Timer? _pollTimer;
  Timer? _restoredResetTimer;
  bool _checking = false;
  int _consecutiveFailures = 0;

  static const int _consecutiveFailuresToGoOffline = 2;
  static const Duration _pollIntervalOnline = Duration(seconds: 20);
  static const Duration _pollIntervalOffline = Duration(seconds: 5);
  static const Duration _restoredBannerDuration = Duration(seconds: 3);

  void _init() {
    WidgetsBinding.instance.addObserver(this);
    _checkNow();
    _schedulePoll(_pollIntervalOnline);
  }

  void _schedulePoll(Duration interval) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => _checkNow());
  }

  Future<void> _checkNow() async {
    if (_checking || isClosed) return;
    _checking = true;
    try {
      final isOnline = await _networkStatus.isConnected();
      if (isClosed) return;
      _handleResult(isOnline);
    } finally {
      _checking = false;
    }
  }

  void _handleResult(bool isOnline) {
    if (isOnline) {
      _consecutiveFailures = 0;
      _schedulePoll(_pollIntervalOnline);

      if (state is ConnectivityOffline) {
        debugPrint('[ConnectivityCubit] Restored ✅');
        emit(ConnectivityRestored());
        _restoredResetTimer?.cancel();
        _restoredResetTimer = Timer(_restoredBannerDuration, () {
          if (!isClosed && state is ConnectivityRestored) {
            emit(ConnectivityOnline());
          }
        });
      } else if (state is ConnectivityInitial) {
        debugPrint('[ConnectivityCubit] online ✅');
        emit(ConnectivityOnline());
      }
      return;
    }

    _consecutiveFailures++;
    _schedulePoll(_pollIntervalOffline);

    final bool comingFromKnownOnline =
        state is ConnectivityOnline || state is ConnectivityRestored;
    final bool shouldDeclareOffline =
        !comingFromKnownOnline ||
        _consecutiveFailures >= _consecutiveFailuresToGoOffline;

    if (shouldDeclareOffline && state is! ConnectivityOffline) {
      debugPrint('[ConnectivityCubit] offline ⛔');
      emit(ConnectivityOffline());
    }
  }

  Future<void> checkNow() => _checkNow();

  bool get isOnline => state is ConnectivityOnline;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNow();
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _restoredResetTimer?.cancel();
    return super.close();
  }
}
