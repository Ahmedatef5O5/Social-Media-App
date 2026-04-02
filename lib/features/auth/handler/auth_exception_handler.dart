import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles and maps all Supabase authentication exceptions
class AuthExceptionHandler {
  /// Pass any caught exception from AuthCubit and get a clean message back.
  static String handle(Object e) {
    if (e is AuthException) {
      return _handleAuthException(e);
    }

    final msg = e.toString().toLowerCase();

    // ─── Network ───────────────────────────────────────────────
    if (msg.contains('socketexception') ||
        msg.contains('network') ||
        msg.contains('failed host lookup')) {
      return 'No internet connection. Please check your network.';
    }

    // ─── Timeout ───────────────────────────────────────────────
    if (msg.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    // ─── Aborted (Google / Facebook OAuth) ─────────────────────
    if (msg.contains('aborted')) {
      return 'Sign-in was cancelled.';
    }

    return 'Something went wrong. Please try again.';
  }

  // ─────────────────────────────────────────────────────────────
  // Supabase AuthException mapper
  // ─────────────────────────────────────────────────────────────
  static String _handleAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    final code = e.code?.toLowerCase() ?? '';

    // ── Email / format ─────────────────────────────────────────
    if (code == 'validation_failed' ||
        msg.contains('invalid format') ||
        msg.contains('unable to validate email')) {
      return 'Please enter a valid email address.';
    }

    if (msg.contains('email not confirmed') || code == 'email_not_confirmed') {
      return 'Your email is not verified yet. Please check your inbox.';
    }

    if (msg.contains('email already registered') ||
        msg.contains('user already registered') ||
        code == 'email_exists') {
      return 'This email is already registered. Try signing in instead.';
    }

    if (msg.contains('email link is invalid or has expired') ||
        code == 'otp_expired') {
      return 'The verification link has expired. Please request a new one.';
    }

    // ── Password ───────────────────────────────────────────────
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials') ||
        code == 'invalid_credentials') {
      return 'Incorrect email or password. Please try again.';
    }

    if (msg.contains('too many invalid password attempts') ||
        code == 'too_many_attempts') {
      return 'Account temporarily locked due to many failed attempts. Try again later.';
    }

    if (msg.contains('password should be at least') ||
        msg.contains('weak password') ||
        code == 'weak_password') {
      return 'Password is too weak. Use at least 6 characters.';
    }

    if (msg.contains('same password') || code == 'same_password') {
      return 'New password must be different from the current one.';
    }

    // ── Account / session ──────────────────────────────────────
    if (msg.contains('user not found') || code == 'user_not_found') {
      return 'No account found with this email.';
    }

    if (msg.contains('email change') && msg.contains('disabled')) {
      return 'Email change is currently disabled.';
    }

    if (msg.contains('signup') && msg.contains('disabled') ||
        code == 'signup_disabled') {
      return 'New registrations are currently disabled. Try again later.';
    }

    if (msg.contains('too many requests') ||
        code == 'over_request_rate_limit' ||
        code == 'over_email_send_rate_limit') {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    if (msg.contains('session expired') ||
        msg.contains('jwt expired') ||
        code == 'session_expired') {
      return 'Your session has expired. Please sign in again.';
    }

    if (msg.contains('not authorized') || code == 'not_authorized') {
      return 'You are not authorized to perform this action.';
    }

    if (msg.contains('database error') ||
        msg.contains('api key not found') ||
        msg.contains('service unavailable')) {
      return 'Our services are currently under maintenance. Please try again in a few minutes.';
    }

    if (msg.contains('postgrestexception') ||
        msg.contains('permission denied')) {
      return 'We couldn\'t sync your profile data. Please contact support.';
    }

    // ── Phone ──────────────────────────────────────────────────
    if (msg.contains('phone') && msg.contains('invalid')) {
      return 'Please enter a valid phone number.';
    }

    if (msg.contains('otp') ||
        msg.contains('token') && msg.contains('invalid')) {
      return 'Invalid or expired verification code.';
    }

    // ── OAuth (Google / Facebook / Apple) ─────────────────────
    if (msg.contains('provider') && msg.contains('disabled')) {
      return 'This sign-in method is currently unavailable.';
    }

    if (msg.contains('id_token') || msg.contains('no id token')) {
      return 'Social sign-in failed. Please try again.';
    }

    // ── Fallback ───────────────────────────────────────────────
    return e.message.isNotEmpty
        ? e.message
        : 'An authentication error occurred. Please try again.';
  }
}
