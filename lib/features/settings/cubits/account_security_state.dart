part of 'account_security_cubit.dart';

enum AccountAction {
  changePassword,
  sendResetLink,
  changeEmail,
  resendEmailChange,
  cancelEmailChange,
  resendVerification,
}

enum AccountFailureKind {
  wrongCurrentPassword,
  emailTaken,
  rateLimited,
  reauthRequired,
  generic,
}

sealed class AccountSecurityState {
  const AccountSecurityState();
}

final class AccountSecurityIdle extends AccountSecurityState {
  const AccountSecurityIdle();
}

final class AccountSecurityBusy extends AccountSecurityState {
  final AccountAction action;
  const AccountSecurityBusy(this.action);
}

final class AccountSecuritySuccess extends AccountSecurityState {
  final AccountAction action;
  final User? user;
  const AccountSecuritySuccess(this.action, {this.user});
}

final class AccountSecurityFailure extends AccountSecurityState {
  final AccountAction action;
  final String message;
  final AccountFailureKind kind;
  final int? retryAfterSeconds;
  const AccountSecurityFailure(
    this.action,
    this.message, {
    this.kind = AccountFailureKind.generic,
    this.retryAfterSeconds,
  });
}
