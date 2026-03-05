import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/auth/services/supabase_auth_services.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());
  final authServices = SupabaseAuthServices();

  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      await authServices.signInWithEmail(email, password);
      emit(AuthSuccess());
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
      await authServices.signUpWithEmail(name, email, password);
      debugPrint("DEBUG: Registration Success! Navigating now...");
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await authServices.signOut();
      emit(AuthSignedOut());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await authServices.resetPassword(email);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  // Future<void> getUserData() async {
  //   emit(AuthLoading());
  //   try {
  //     final userData = await authServices.getUserData();
  //     if (userData != null) {
  //       emit(AuthSuccess());
  //     } else {
  //       emit(AuthFailure('User not found'));
  //     }
  //   } catch (e) {
  //     emit(AuthFailure(e.toString()));
  //   }
  // }

  void checkAuthStatus() {
    final userData = authServices.fetchRawUser();
    if (userData != null) {
      emit(AuthSuccess());
    }
  }
}
