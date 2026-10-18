import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/two_factor_failure.dart';
import '../services/two_factor_service.dart';

enum TwoFactorDisableMethod { password, totp }

class TwoFactorDisableState {
  final TwoFactorDisableMethod method;
  final bool submitting;
  final String? error;
  final bool done;

  const TwoFactorDisableState({
    required this.method,
    this.submitting = false,
    this.error,
    this.done = false,
  });

  static const Object _unset = Object();

  TwoFactorDisableState copyWith({
    TwoFactorDisableMethod? method,
    bool? submitting,
    Object? error = _unset,
    bool? done,
  }) => TwoFactorDisableState(
    method: method ?? this.method,
    submitting: submitting ?? this.submitting,
    error: identical(error, _unset) ? this.error : error as String?,
    done: done ?? this.done,
  );
}

/// Re-checks who is asking, then turns 2FA off.
///
/// A phone that is unlocked in someone else's hand also has the authenticator
/// app, so a live TOTP code alone proves little there; the password is the
/// stronger check and is the default whenever the account has one. OAuth-only
/// accounts have no password and use a live code instead.
class TwoFactorDisableCubit extends Cubit<TwoFactorDisableState> {
  final TwoFactorService _service;

  TwoFactorDisableCubit(this._service, {required bool hasPassword})
    : super(
        TwoFactorDisableState(
          method:
              hasPassword
                  ? TwoFactorDisableMethod.password
                  : TwoFactorDisableMethod.totp,
        ),
      );

  void setMethod(TwoFactorDisableMethod method) {
    if (state.submitting) return;
    emit(state.copyWith(method: method, error: null));
  }

  Future<void> submitPassword(String password) async {
    if (state.submitting) return;
    if (password.isEmpty) {
      emit(state.copyWith(error: 'Enter your current password.'));
      return;
    }
    await _run(() => _service.verifyPassword(password));
  }

  Future<void> submitTotp(String code) async {
    if (state.submitting || code.length != 6) return;
    await _run(() => _service.verifyLoginCode(code));
  }

  Future<void> _run(Future<void> Function() verifyIdentity) async {
    emit(state.copyWith(submitting: true, error: null));
    try {
      await verifyIdentity();
      await _service.disable();
      if (isClosed) return;
      emit(state.copyWith(submitting: false, done: true));
    } on TwoFactorFailure catch (f) {
      if (isClosed) return;
      if (f.kind == TwoFactorFailureKind.aalRequired) {
        // The session is not aal2: only a live code can lift it.
        emit(
          state.copyWith(
            submitting: false,
            method: TwoFactorDisableMethod.totp,
            error: f.message,
          ),
        );
      } else {
        emit(state.copyWith(submitting: false, error: f.message));
      }
    }
  }
}
