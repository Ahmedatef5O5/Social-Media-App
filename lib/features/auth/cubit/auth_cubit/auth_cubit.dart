import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        // debugPrint("New user added to 'users' table successfully.");

        emit(AuthSuccess());
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

  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      await _authServices.signInWithEmail(email, password);
    } catch (e) {
      emit(AuthFailure(e.toString()));
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
      emit(AuthFailure(e.toString()));
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
        emit(AuthFailure(e.toString()));
      }
    }
  }

  Future<void> signInWithFacebook() async {
    emit(AuthLoading());
    try {
      await _authServices.signInWithFacebook();
    } catch (e) {
      debugPrint('Error in Cubit Facebook Sign-In: $e');
      if (e.toString().contains('aborted')) {
        emit(AuthInitial());
      } else {
        emit(AuthFailure(e.toString()));
      }
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await _authServices.signOut();
      emit(AuthSignedOut());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await _authServices.resetPassword(email);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  void checkAuthStatus() {
    final userData = _authServices.fetchRawUser();
    if (userData != null) {
      emit(AuthSuccess());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
