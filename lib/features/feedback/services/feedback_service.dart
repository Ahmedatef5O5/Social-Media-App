import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:social_media_app/core/services/cloudinary_storage_services.dart';
import 'package:social_media_app/core/services/cloudinary_upload_result.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feedback_models.dart';

class FeedbackRateLimitException implements Exception {
  const FeedbackRateLimitException();
  @override
  String toString() => 'feedback_rate_limit_exceeded';
}

class FeedbackService {
  FeedbackService({CloudinaryStorageServices? storage})
    : _storage = storage ?? CloudinaryStorageServices.instance;

  final CloudinaryStorageServices _storage;

  static const String _table = 'user_feedbacks';

  // Explicit column list: `responded_by` is deliberately not granted to
  // clients, so `select('*')` would be rejected by the database.
  static const String _columns =
      'id, category, message, rating, image_url, audio_url, '
      'audio_duration_seconds, contact_method, status, admin_response, '
      'responded_at, created_at';

  SupabaseClient get _client => SupabaseProvider.client;

  Future<FeedbackQuota> fetchQuota() async {
    final res = await _client.rpc('get_my_feedback_quota');
    return FeedbackQuota.fromMap(Map<String, dynamic>.from(res as Map));
  }

  Future<List<UserFeedback>> fetchMyFeedbacks({int limit = 50}) async {
    final rows = await _client
        .from(_table)
        .select(_columns)
        .eq('user_id', SupabaseProvider.id)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => UserFeedback.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<UserFeedback?> fetchById(String id) async {
    final row =
        await _client
            .from(_table)
            .select(_columns)
            .eq('id', id)
            .eq('user_id', SupabaseProvider.id)
            .maybeSingle();
    return row == null ? null : UserFeedback.fromMap(row);
  }

  Future<CloudinaryUploadResult> uploadAttachment(
    File file, {
    required String kind, // 'image' | 'audio'
    void Function(double progress)? onProgress,
  }) {
    return _storage.uploadFile(
      file,
      'feedback',
      SupabaseProvider.id,
      filePrefix: '${kind}_',
      onProgress: onProgress,
    );
  }

  Future<UserFeedback> submit({
    required FeedbackCategory category,
    required String message,
    int? rating,
    CloudinaryUploadResult? image,
    CloudinaryUploadResult? audio,
    int? audioDurationSeconds,
    String? contactMethod,
  }) async {
    final contact = contactMethod?.trim();
    try {
      final row =
          await _client
              .from(_table)
              .insert({
                'user_id': SupabaseProvider.id,
                'category': category.value,
                'message': message.trim(),
                'rating': rating,
                'image_url': image?.secureUrl,
                'image_public_id': image?.publicId,
                'audio_url': audio?.secureUrl,
                'audio_public_id': audio?.publicId,
                'audio_duration_seconds': audioDurationSeconds,
                'contact_method':
                    (contact == null || contact.isEmpty) ? null : contact,
              })
              .select(_columns)
              .single();
      return UserFeedback.fromMap(row);
    } on PostgrestException catch (e) {
      if (e.message.contains('feedback_rate_limit_exceeded') ||
          e.code == 'P0429') {
        throw const FeedbackRateLimitException();
      }
      rethrow;
    }
  }

  /// Live updates. The payload is intentionally ignored (it is only a signal):
  /// callers refetch through the column-restricted SELECT above.
  RealtimeChannel subscribe({
    required VoidCallback onChange,
    String? feedbackId,
  }) {
    final uid = SupabaseProvider.id;
    final channel = _client.channel(
      'user_feedbacks:$uid:${feedbackId ?? 'all'}',
    );
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
    return channel;
  }

  Future<void> unsubscribe(RealtimeChannel? channel) async {
    if (channel == null) return;
    try {
      await _client.removeChannel(channel);
    } catch (e) {
      debugPrint('[FeedbackService] removeChannel failed: $e');
    }
  }
}
