import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/connectivity/cubit/connectivity_state.dart';
import '../../services/network_status_service.dart';

class ConnectivityCubit extends Cubit<ConnectivityState>
    with WidgetsBindingObserver {
  ConnectivityCubit({NetworkStatusService? networkStatus})
    : _networkStatus = networkStatus ?? NetworkStatusService.instance,
      super(ConnectivityInitial()) {
    _init();
  }

  final NetworkStatusService _networkStatus;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _heartbeatTimer;
  Timer? _debounceTimer;

  static const Duration _heartbeatInterval = Duration(seconds: 15);
  static const Duration _debounceDelay = Duration(milliseconds: 600);

  void _init() {
    WidgetsBinding.instance.addObserver(this);

    _checkNow(forceRefresh: true);

    _connectivitySub = Connectivity().onConnectivityChanged.listen((_) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(
        _debounceDelay,
        () => _checkNow(forceRefresh: true),
      );
    });

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) => _checkNow());
  }

  Future<void> _checkNow({bool forceRefresh = false}) async {
    final isOnline = await _networkStatus.isConnected(
      // forceRefresh: forceRefresh,
    );
    if (isClosed) return;

    if (isOnline) {
      if (state is ConnectivityOffline) {
        debugPrint('[ConnectivityCubit] Restored ✅');
        emit(ConnectivityRestored());

        Future.delayed(const Duration(seconds: 3), () {
          if (!isClosed && state is ConnectivityRestored) {
            emit(ConnectivityOnline());
          }
        });
      } else if (state is ConnectivityInitial) {
        debugPrint('[ConnectivityCubit] online ✅');
        emit(ConnectivityOnline());
      }
    } else {
      if (state is! ConnectivityOffline) {
        debugPrint('[ConnectivityCubit] offline ⛔');
        emit(ConnectivityOffline());
      }
    }
    // final nextState = isOnline ? ConnectivityOnline() : ConnectivityOffline();
    // if (state.runtimeType == nextState.runtimeType) return;
    // debugPrint('[ConnectivityCubit] ${isOnline ? "online ✅" : "offline ⛔"}');
    // emit(nextState);
  }

  Future<void> checkNow() => _checkNow(forceRefresh: true);

  bool get isOnline => state is ConnectivityOnline;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNow(forceRefresh: true);
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _heartbeatTimer?.cancel();
    _debounceTimer?.cancel();
    return super.close();
  }
}
