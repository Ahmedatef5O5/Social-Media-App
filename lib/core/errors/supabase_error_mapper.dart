import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/handlers/auth_exception_handler.dart';
import 'network_error_utils.dart';

/// Single entry point every non-auth Cubit/Repository should route
/// caught exceptions through before showing anything to the user.
/// Auth-specific exceptions are delegated to AuthExceptionHandler so
/// its existing, already-correct mapping stays the single source of
/// truth for auth copy.
class SupabaseErrorMapper {
  SupabaseErrorMapper._();

  static String toUserMessage(Object e) {
    if (NetworkErrorUtils.isNetworkError(e)) {
      return 'no-internet';
    }

    if (e is AuthException) {
      return AuthExceptionHandler.handle(e);
    }

    if (e is PostgrestException) {
      return _handlePostgrestException(e);
    }

    if (e is StorageException) {
      return 'File upload/download failed. Please try again.';
    }

    if (NetworkErrorUtils.isNetworkError(e)) {
      return 'No internet connection. Please check your network.';
    }

    if (NetworkErrorUtils.isTimeoutError(e)) {
      return 'Server is taking too long to respond. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  static String _handlePostgrestException(PostgrestException e) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();

    // Server Down
    if (code == '503' || code == '500' || msg.contains('service unavailable')) {
      return 'Our servers are currently on a break. We will be back shortly.';
    }
    // RLS / permission
    if (code == '42501' || msg.contains('permission denied')) {
      return 'You don\'t have permission to do this.';
    }

    // Connection-level Postgres errors surfaced through PostgREST
    if (code == '08000' || code == '08006' || msg.contains('connection')) {
      return 'Server is currently unavailable. Please try again shortly.';
    }

    // Row not found via .single()/.maybeSingle() mismatch
    if (code == 'PGRST116') {
      return 'The requested data was not found.';
    }

    // Foreign key / constraint violations — rare to surface to users,
    // but better a generic message than raw SQL error text.
    if (code.startsWith('23')) {
      return 'This action couldn\'t be completed due to a data conflict.';
    }

    return 'We couldn\'t complete this request. Please try again.';
  }
}
