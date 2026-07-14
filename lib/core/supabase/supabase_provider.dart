import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProvider {
  SupabaseProvider._();

  /// Supabase client
  static SupabaseClient get client => Supabase.instance.client;

  /// Auth client
  static GoTrueClient get auth => client.auth;

  /// Current signed-in user
  static User? get user => auth.currentUser;

  /// Current user id
  static String get id {
    final currentUser = user;
    if (currentUser == null) {
      throw StateError(
        'SupabaseProvider.id was accessed while no user is authenticated.',
      );
    }
    return currentUser.id;
  }

  /// Current user id or null
  static String? get idOrNull => user?.id;

  /// Current session
  static Session? get currentSession => auth.currentSession;

  /// Auth state changes
  static Stream<AuthState> get authChanges => auth.onAuthStateChange;
}
