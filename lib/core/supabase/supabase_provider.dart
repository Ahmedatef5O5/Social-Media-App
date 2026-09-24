import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../observability/error_category.dart';
import '../observability/observability.dart';

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
      throw Exception(
        'Supabase must be initialized before accessing the client.',
      );
    }
  }

  /// Auth client
  static GoTrueClient get auth => client.auth;

  /// Current signed-in user
  static User? get user => auth.currentUser;

  /// Quick check for authentication status
  static bool get isAuthenticated => user != null;

  /// Current user id.
  ///
  /// Returns `''` when signed out. The empty string is NOT harmless: it
  /// flows into `ChatHelper.buildConversationId`, into Hive snapshot keys
  /// and into `.eq(user_id, '')` filters, where it silently produces empty
  /// results and mis-keyed caches instead of an error. The behaviour is
  /// preserved on purpose (changing it to a throw would break screens that
  /// work today) — but it is now REPORTED, so C-02 regressions surface in
  /// Crashlytics instead of in a user complaint.
  static String get id {
    final currentUser = user;
    if (currentUser == null) {
      debugPrint(
        '⚠️ Warning: SupabaseProvider.id was accessed while user is logged out.',
      );
      unawaited(
        obs.recordError(
          UnauthenticatedException(
            'SupabaseProvider.id accessed while signed out',
          ),
          StackTrace.current,
          category: ErrorCategory.authentication,
          feature: 'session',
          operation: 'resolve_user_id',
          reason: 'empty user id returned to caller',
        ),
      );
      return '';
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
