import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/two_factor_failure.dart';
import '../services/two_factor_service.dart';
import 'two_factor_setup_state.dart';

class TwoFactorSetupCubit extends Cubit<TwoFactorSetupState> {
  final TwoFactorService _service;
  bool _verified = false;

  TwoFactorSetupCubit(this._service) : super(const TwoFactorSetupState());

  /// Intro -> QR. This is the first network call of the wizard.
  Future<void> begin() async {
    if (state.step == TwoFactorSetupStep.enrolling) return;
    emit(state.copyWith(step: TwoFactorSetupStep.enrolling, error: null));
    try {
      final enrollment = await _service.beginEnrollment();
      if (isClosed) {
        await _service.cancelEnrollment(enrollment.factorId);
        return;
      }
      emit(
        state.copyWith(
          step: TwoFactorSetupStep.scan,
          enrollment: enrollment,
          error: null,
        ),
      );
    } on TwoFactorFailure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(step: TwoFactorSetupStep.failure, error: f.message));
    }
  }

  void goToCodeEntry() {
    if (state.enrollment == null) return;
    emit(state.copyWith(step: TwoFactorSetupStep.enterCode, error: null));
  }

  void backToScan() {
    if (state.step != TwoFactorSetupStep.enterCode) return;
    emit(state.copyWith(step: TwoFactorSetupStep.scan, error: null));
  }

  Future<void> verify(String code) async {
    final enrollment = state.enrollment;
    if (enrollment == null || state.step == TwoFactorSetupStep.verifying)
      return;
    if (code.length != 6) return;

    emit(state.copyWith(step: TwoFactorSetupStep.verifying, error: null));
    try {
      await _service.confirmEnrollment(enrollment.factorId, code);
      _verified = true;
    } on TwoFactorFailure catch (f) {
      if (isClosed) return;
      emit(
        state.copyWith(
          step: TwoFactorSetupStep.enterCode,
          error: f.message,
          invalidAttempts:
              f.kind == TwoFactorFailureKind.invalidCode
                  ? state.invalidAttempts + 1
                  : state.invalidAttempts,
        ),
      );
      return;
    }
    await retryGenerateCodes();
  }

  Future<void> retryGenerateCodes() async {
    if (isClosed) return;
    emit(state.copyWith(step: TwoFactorSetupStep.generatingCodes, error: null));
    try {
      final codes = await _service.generateRecoveryCodes();
      if (isClosed) return;
      emit(
        state.copyWith(step: TwoFactorSetupStep.recoveryCodes, codes: codes),
      );
    } on TwoFactorFailure catch (f) {
      if (isClosed) return;
      emit(
        state.copyWith(step: TwoFactorSetupStep.codesError, error: f.message),
      );
    }
  }

  @override
  Future<void> close() {
    // Wizard abandoned before verification: do not leave a dangling factor.
    final enrollment = state.enrollment;
    if (!_verified && enrollment != null) {
      unawaited(_service.cancelEnrollment(enrollment.factorId));
    }
    return super.close();
  }
}
