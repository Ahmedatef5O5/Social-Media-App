import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:social_media_app/features/auth/handler/auth_exception_handler.dart';
import 'package:social_media_app/features/auth/services/supabase_auth_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/presence/services/presence_service.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SupabaseAuthServices _authServices;
  StreamSubscription? _authSubscription;

  AuthCubit(this._authServices) : super(AuthInitial()) {
    _monitorAuthState();
  }

  void _monitorAuthState() {
    _authSubscription = _authServices.authStateStream.listen((data) async {
      final session = data.session;
      final event = data.event;

      if (session != null &&
          (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.initialSession)) {
        final user = session.user;
        emit(AuthSuccess());

        unawaited(
          _authServices.ensureUserExistsInDb(user).catchError((e) {
            debugPrint(
              '⚠️ ensureUserExistsInDb failed (likely offline), will retry naturally on next auth event: $e',
            );
          }),
        );
      } else if (event == AuthChangeEvent.signedOut) {
        emit(AuthSignedOut());
      }
    });
  }

  void _handleError(Object e) {
    final message = AuthExceptionHandler.handle(e);
    if (message.isEmpty ||
        message.contains('cancelled') ||
        message.contains('aborted') ||
        message.contains('cancel') ||
        message.contains('user_cancelled')) {
      emit(AuthInitial());
      return;
    }
    emit(AuthFailure(AuthExceptionHandler.handle(e)));
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      await _authServices.signInWithEmail(email, password);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    emit(AuthLoading());
    try {
      await _authServices.signUpWithEmail(name, email, password);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      await _authServices.signInWithGoogle();
    } catch (e) {
      debugPrint('Error in Cubit Google Sign-In: $e');
      if (e.toString().contains('aborted')) {
        emit(AuthInitial());
      } else {
        _handleError(e);
      }
    }
  }

  Future<void> signInWithFacebook() async {
    emit(AuthLoading());
    try {
      await _authServices.signInWithFacebook();

      await Future.delayed(const Duration(seconds: 10));
      if (state is AuthLoading) {
        emit(AuthInitial());
      }
    } catch (e) {
      debugPrint('Facebook Sign-In Error: $e');
      _handleError(e);
    }
  }

  Future<void> signInWithMicrosoft() async {
    emit(AuthLoading());
    try {
      await _authServices.signInWithMicrosoft();

      await Future.delayed(const Duration(seconds: 10));
      if (state is AuthLoading) {
        emit(AuthInitial());
      }
    } catch (e) {
      debugPrint('Microsoft Sign-In Error: $e');
      _handleError(e);
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await PresenceService.instance.setVisibility(false);
      await _authServices.signOut();
      emit(AuthSignedOut());
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await _authServices.resetPassword(email);
      emit(AuthSuccess());
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> checkAuthStatus() async {
    final session = _authServices.currentSession;

    if (session == null) {
      emit(AuthInitial());
      return;
    }

    if (!session.isExpired) {
      emit(AuthSuccess());
      return;
    }

    final isOnline = await NetworkStatusService.instance.isConnected();

    if (!isOnline) {
      debugPrint(
        '⚠️ Access token looks expired but device is offline — '
        'keeping the cached session. It will refresh automatically '
        'once connectivity returns.',
      );
      emit(AuthSuccess());
      return;
    }
    try {
      final response = await _authServices.refreshSession();
      if (response.session != null) {
        emit(AuthSuccess());
      } else {
        debugPrint(
          '⚠️ Session expired and refresh returned no session! Forcing Sign Out...',
        );
        await signOut();
      }
    } catch (e) {
      debugPrint('⚠️ Session refresh failed: $e — Forcing Sign Out...');
      await signOut();
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
