import 'package:social_media_app/features/auth/data/models/user_data.dart';

abstract class AuthRepository {
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String email, String password);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<UserData?> getUserData();
}
