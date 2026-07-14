import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnauthenticatedException implements Exception {
  final String message;
  UnauthenticatedException([this.message = 'User is not authenticated.']);
  
  @override
  String toString() => 'UnauthenticatedException: $message';
}

class SupabaseProvider {
  SupabaseProvider._();

  /// Safely get the Supabase instance.
  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      debugPrint('⚠️ Supabase accessed before initialization: $e');
      throw Exception('Supabase must be initialized before accessing the client.');
    }
  }

  /// Auth client
  static GoTrueClient get auth => client.auth;

  /// Current signed-in user
  static User? get user => auth.currentUser;

  /// Quick check for authentication status
  static bool get isAuthenticated => user != null;

  /// Current user id.
  static String get id {
    final currentUser = user;
    if (currentUser == null) {
      throw UnauthenticatedException(
        'SupabaseProvider.id was accessed but the user is logged out or not registered yet.',
      );
    }
    return currentUser.id;
  }

  /// Current user id or null
  static String? get idOrNull => user?.id;

  /// Current session
  static Session? get currentSession => auth.currentSession;

  /// Auth state changes (Listening to login/logout events)
  static Stream<AuthState> get authChanges => auth.onAuthStateChange;
}