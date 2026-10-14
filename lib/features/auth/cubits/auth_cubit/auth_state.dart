part of 'auth_cubit.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthSuccess extends AuthState {}

final class AuthFailure extends AuthState {
  final String errMsg;
  AuthFailure(this.errMsg);
}

final class AuthSignedOut extends AuthState {}

final class PasswordResetEmailSent extends AuthState {}

final class PasswordUpdateSuccess extends AuthState {}

final class AuthAccountDeleted extends AuthState {}
