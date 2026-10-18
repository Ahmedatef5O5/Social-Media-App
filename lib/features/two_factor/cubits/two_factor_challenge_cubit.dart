import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/two_factor_failure.dart';
import '../services/two_factor_lockout_store.dart';
import '../services/two_factor_service.dart';
import 'two_factor_challenge_state.dart';

class TwoFactorChallengeCubit extends Cubit<TwoFactorChallengeState> {
  final TwoFactorService _service;
  final TwoFactorLockoutStore _lockout;
  final String _userId;
  Timer? _timer;

  TwoFactorChallengeCubit({
    required TwoFactorService service,
    required TwoFactorLockoutStore lockout,
    required String userId,
  }) : _service = service,
       _lockout = lockout,
       _userId = userId,
       super(const TwoFactorChallengeState());

  /// Restores a pause that was running when the app was closed.
  Future<void> init() async {
    final left = await _lockout.remaining(_userId);
    if (left != null && !isClosed) {
      _startCountdown(left, TwoFactorChallengeMode.totp);
    }
  }

  void setMode(TwoFactorChallengeMode mode) {
    if (state.submitting || mode == state.mode) return;
    emit(state.copyWith(mode: mode, error: null));
  }

  Future<void> submitTotp(String code) async {
    if (state.submitting || state.isLocked || code.length != 6) return;
    emit(state.copyWith(submitting: true, error: null));
    try {
      await _service.verifyLoginCode(code);
      await _lockout.reset(_userId);
      if (isClosed) return;
      emit(state.copyWith(submitting: false, completed: true));
    } on TwoFactorFailure catch (f) {
      if (isClosed) return;
      if (f.kind == TwoFactorFailureKind.invalidCode) {
        final pause = await _lockout.recordFailure(_userId);
        if (isClosed) return;
        emit(
          state.copyWith(
            submitting: false,
            error: f.message,
            consecutiveInvalid: state.consecutiveInvalid + 1,
          ),
        );
        if (pause != null) _startCountdown(pause, TwoFactorChallengeMode.totp);
      } else {
        emit(state.copyWith(submitting: false, error: f.message));
      }
    }
  }

  Future<void> submitBackup(String raw) async {
    if (state.submitting || state.isLocked) return;
    final normalized = raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (normalized.length != 10) {
      emit(state.copyWith(error: 'Enter the 10-character recovery code.'));
      return;
    }

    emit(state.copyWith(submitting: true, error: null));
    try {
      final result = await _service.redeemBackupCode(raw);
      if (isClosed) return;

      if (result.ok) {
        await _lockout.reset(_userId);
        if (isClosed) return;
        emit(
          state.copyWith(
            submitting: false,
            completed: true,
            reenrollRequired: true,
          ),
        );
      } else if (result.isLocked) {
        emit(
          state.copyWith(
            submitting: false,
            error: 'Too many attempts. Please wait before trying again.',
          ),
        );
        _startCountdown(
          Duration(seconds: result.retryAfterSeconds ?? 900),
          TwoFactorChallengeMode.backup,
        );
      } else {
        final left = result.attemptsLeft;
        emit(
          state.copyWith(
            submitting: false,
            error:
                left == null
                    ? 'Invalid recovery code.'
                    : 'Invalid recovery code. $left '
                        '${left == 1 ? 'attempt' : 'attempts'} left.',
          ),
        );
      }
    } on TwoFactorFailure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(submitting: false, error: f.message));
    }
  }

  void _startCountdown(Duration d, TwoFactorChallengeMode mode) {
    _timer?.cancel();
    final end = DateTime.now().add(d);
    emit(state.copyWith(lockRemaining: d, lockMode: mode));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (isClosed) return t.cancel();
      final left = end.difference(DateTime.now());
      if (left <= Duration.zero) {
        t.cancel();
        emit(state.copyWith(lockRemaining: null, lockMode: null, error: null));
      } else {
        emit(state.copyWith(lockRemaining: left));
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
