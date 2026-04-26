import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/auth/handler/auth_exception_handler.dart';
import 'package:social_media_app/features/auth/services/supabase_auth_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utilities/supabase_constants.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SupabaseAuthServices _authServices;
  StreamSubscription? _authSubscription;

  AuthCubit(this._authServices) : super(AuthInitial()) {
    _monitorAuthState();
  }

  void _monitorAuthState() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final session = data.session;
      final event = data.event;

      if (session != null &&
          (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.initialSession)) {
        final user = session.user;
        await _ensureUserExistsInDb(user);
        emit(AuthSuccess());
      } else if (event == AuthChangeEvent.signedOut) {
        emit(AuthSignedOut());
      }
    });
  }

  Future<void> _ensureUserExistsInDb(User user) async {
    final existingUser =
        await Supabase.instance.client
            .from(SupabaseConstants.users)
            .select()
            .eq(UserColumns.id, user.id)
            .maybeSingle();

    if (existingUser == null) {
      final String userName =
          user.userMetadata?[UserColumns.name] ??
          user.userMetadata?['full_name'] ??
          user.userMetadata?['display_name'] ??
          'Social User';

      await _authServices.setUserData(userName, user.email ?? '', user.id);
    }
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

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
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

<<<<<<< HEAD
=======
  // void checkAuthStatus() {
  //   final userData = _authServices.fetchRawUser();
  //   if (userData != null) {
  //     emit(AuthSuccess());
  //   }
  // }

>>>>>>> 2cb77de172f6ae74c5597ffcdd4db6cd035b3990
  Future<void> checkAuthStatus() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      if (session.isExpired) {
        debugPrint('⚠️ Session Expired! Forcing Sign Out...');
        await signOut();
      } else {
        emit(AuthSuccess());
      }
    } else {
      emit(AuthInitial());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
