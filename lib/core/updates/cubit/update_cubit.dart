import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/shorebird_update_service.dart';
import 'update_state.dart';

/// Thin presentation layer over [ShorebirdUpdateService]. The app does not
/// have to show any UI for updates; provide this cubit only if you want a
/// settings row / debug screen. It also re-checks (throttled by the policy's
/// minimum interval) when the app returns to the foreground.

class UpdateCubit extends Cubit<UpdateState> with WidgetsBindingObserver {
  UpdateCubit({ShorebirdUpdateService? service})
    : _service = service ?? ShorebirdUpdateService.instance,
      super((service ?? ShorebirdUpdateService.instance).state) {
    _sub = _service.states.listen(emit);
    WidgetsBinding.instance.addObserver(this);
  }

  final ShorebirdUpdateService _service;
  late final StreamSubscription<UpdateState> _sub;

  /// Explicit user action: bypasses the interval and auto-check switch.
  Future<void> checkNow() => _service.checkForUpdate(force: true);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_service.telemetry.flush());
      unawaited(_service.checkForUpdate());
    }
  }

  @override
  Future<void> close() async {
    WidgetsBinding.instance.removeObserver(this);
    await _sub.cancel();
    return super.close();
  }
}
