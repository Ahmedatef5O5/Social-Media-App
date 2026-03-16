import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  Future<void> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      if (response.user == null) throw Exception('User not found');
      await setUserData(name, email, response.user!.id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResponse> signInWithGoogle() async {
    try {
      const webClientId =
          '548020841452-cvtj4vs047g5acgtsmga02990tfagvg4.apps.googleusercontent.com';
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Sign in aborted by user';
        // return ;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found';
      }

      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signInWithFacebook() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'socialapp://login-callback',
        // authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Facebook Sign-In Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await FacebookAuth.instance.logOut();
      await GoogleSignIn().signOut();
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

  Future<void> setUserData(String name, String email, String userId) async {
    try {
      await _supabase.from('users').upsert({
        'name': name,
        'email': email,
        'id': userId,
      });
    } catch (e) {
      debugPrint('Error setting user data: $e');
      rethrow;
    }
  }

  User? fetchRawUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return user;
  }
}
