import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, User;
import '../../../core/helpers/safe_emit_mixin.dart';
import '../../auth/handlers/auth_exception_handler.dart';
import '../../auth/services/supabase_auth_services.dart';
part 'account_security_state.dart';

/// Screen-scoped cubit for Change Password / Email Address.

class AccountSecurityCubit extends Cubit<AccountSecurityState>
    with SafeEmitMixin<AccountSecurityState> {
  final SupabaseAuthServices _services;

  AccountSecurityCubit(this._services) : super(const AccountSecurityIdle());

  Future<void> _run(AccountAction action, Future<User?> Function() body) async {
    if (state is AccountSecurityBusy) return;
    emit(AccountSecurityBusy(action));
    try {
      final user = await body();
      emit(AccountSecuritySuccess(action, user: user));
    } catch (e) {
      emit(_toFailure(action, e));
    }
  }

  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
  }) => _run(AccountAction.changePassword, () async {
    await _services.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    return null;
  });

  Future<void> sendPasswordResetLink() =>
      _run(AccountAction.sendResetLink, () async {
        final email = _services.currentUser?.email;
        if (email == null || email.isEmpty) {
          throw AuthException(
            'Your session has expired.',
            code: 'session_expired',
          );
        }
        await _services.resetPassword(email);
        return null;
      });

  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) => _run(
    AccountAction.changeEmail,
    () => _services.changeEmail(
      currentPassword: currentPassword,
      newEmail: newEmail,
    ),
  );

  Future<void> resendEmailChange(String pendingEmail) => _run(
    AccountAction.resendEmailChange,
    () => _services.resendEmailChange(pendingEmail),
  );

  Future<void> cancelEmailChange() =>
      _run(AccountAction.cancelEmailChange, () async {
        await _services.cancelEmailChange();
        return null;
      });

  Future<void> resendVerification() =>
      _run(AccountAction.resendVerification, () async {
        await _services.resendSignupVerification();
        return null;
      });

  // ───────────────────────── error mapping ─────────────────────────

  AccountSecurityFailure _toFailure(AccountAction action, Object e) {
    if (e is WrongCurrentPasswordException) {
      return AccountSecurityFailure(
        action,
        'The current password you entered is incorrect.',
        kind: AccountFailureKind.wrongCurrentPassword,
      );
    }

    final handled = AuthExceptionHandler.handle(e);
    if (handled == 'no-internet') {
      return AccountSecurityFailure(
        action,
        'No internet connection. Please check your network.',
      );
    }

    if (e is AuthException) {
      final code = (e.code ?? '').toLowerCase();
      final msg = e.message.toLowerCase();

      if (code == 'email_exists' ||
          code == 'user_already_exists' ||
          msg.contains('already been registered') ||
          msg.contains('already registered')) {
        return AccountSecurityFailure(
          action,
          'This email is already registered with another account.',
          kind: AccountFailureKind.emailTaken,
        );
      }

      if (code == 'over_email_send_rate_limit' ||
          code == 'over_request_rate_limit' ||
          msg.contains('rate limit') ||
          (msg.contains('only request this after') && msg.contains('second'))) {
        final seconds = _extractSeconds(msg);
        return AccountSecurityFailure(
          action,
          seconds != null
              ? 'Too many requests. Please try again in ${seconds}s.'
              : 'Too many requests. Please wait a minute and try again.',
          kind: AccountFailureKind.rateLimited,
          retryAfterSeconds: seconds,
        );
      }

      if (code == 'reauthentication_needed' ||
          code == 'reauthentication_not_valid') {
        return AccountSecurityFailure(
          action,
          'For your security, please sign out and sign back in, then try again.',
          kind: AccountFailureKind.reauthRequired,
        );
      }

      if (code == 'same_password' || msg.contains('same password')) {
        return AccountSecurityFailure(
          action,
          'New password must be different from current password',
        );
      }
    }

    return AccountSecurityFailure(action, handled);
  }

  int? _extractSeconds(String message) {
    final match = RegExp(r'(\d+)\s*second').firstMatch(message);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }
}
