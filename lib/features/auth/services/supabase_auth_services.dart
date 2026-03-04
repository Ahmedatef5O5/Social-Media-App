import 'package:social_media_app/features/auth/data/repository/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/user_data.dart';

class SupabaseAuthServices implements AuthRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) throw Exception('User not found');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) throw Exception('User not found');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserData?> getUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response =
          await _supabase.from('users').select().eq('id', user.id).single();
      if (response.keys.isEmpty) {
        throw Exception('Failed to fetch user data');
      }
      return UserData.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }
}
