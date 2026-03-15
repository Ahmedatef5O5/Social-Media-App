import 'package:social_media_app/features/auth/data/models/user_data.dart';

abstract class AuthRepository {
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String name, String email, String password);
  Future<void> signInWithGoogle();
  // Future<void> signInWithFacebook();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<UserData?> getUserData();
}
