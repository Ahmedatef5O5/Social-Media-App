import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:social_media_app/core/services/cloudinary_upload_result.dart';
import 'package:social_media_app/core/services/network_status_service.dart';
import '../../../core/services/cloudinary_storage_services.dart';
import '../../../core/services/media_cleanup_service.dart';
import '../../../core/services/supabase_database_services.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../social_graph/services/connections_service.dart';
import '../../../core/mentions/models/mention_ref.dart';
import '../models/story_model.dart';
import '../models/story_viewer_model.dart';

class StoriesServices {
  final _supabase = SupabaseProvider.client;
  final supabaseServices = SupabaseDatabaseServices.instance;
  final CloudinaryStorageServices storage = CloudinaryStorageServices.instance;

  Future<CloudinaryUploadResult> uploadStoryFile(
    File file,
    String userId, {
    void Function(double progress)? onProgress,
    dio_pkg.CancelToken? cancelToken,
  }) async {
    return await storage.uploadFile(
      file,
      'stories',
      userId,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<CloudinaryUploadResult> uploadStoryVideoFile(
    File file,
    String userId, {
    void Function(double progress)? onProgress,
    dio_pkg.CancelToken? cancelToken,
  }) async {
    return await storage.uploadFile(
      file,
      'stories',
      userId,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<void> setStoryAllowedViewers(
    String storyId,
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return;
    await _supabase
        .from(SupabaseConstants.storyAllowedViewers)
        .insert(
          userIds.map((id) => {'story_id': storyId, 'user_id': id}).toList(),
        );
  }

  Future<Set<String>> _getPrivateAllowedStoryIds(String userId) async {
    final rows = await _supabase
        .from(SupabaseConstants.storyAllowedViewers)
        .select('story_id')
        .eq('user_id', userId);
    return (rows as List).map((r) => r['story_id'] as String).toSet();
  }

  Future<List<StoryModel>> getAuthorStories(String authorId) async {
    if (!(await NetworkStatusService.instance.isConnected())) {
      throw Exception('no-internet');
    }

    try {
      final currentUserId = SupabaseProvider.id;
      final connectionIds = await ConnectionsService().getMyConnectionIds();
      final allowedPrivateIds = await _getPrivateAllowedStoryIds(currentUserId);

      final orParts = <String>[
        'privacy_type.eq.public',
        'author_id.eq.$currentUserId',
      ];
      if (connectionIds.isNotEmpty) {
        orParts.add(
          'and(privacy_type.eq.friends,author_id.in.(${connectionIds.join(',')}))',
        );
      }
      if (allowedPrivateIds.isNotEmpty) {
        orParts.add('id.in.(${allowedPrivateIds.join(',')})');
      }

      return await supabaseServices.fetchRows(
        table: SupabaseConstants.stories,
        columns:
            '*,'
            'story_mentions(${StoryMentionColumns.mentionedUserId},${StoryMentionColumns.startIndex},${StoryMentionColumns.endIndex}),'
            '${SupabaseConstants.users}!stories_author_id_fkey'
            '(${UserColumns.name}, ${UserColumns.imageUrl})',
        filter:
            (query) => query
                .eq(StoryColumns.authorId, authorId)
                .or(orParts.join(','))
                .order(StoryColumns.createdAt, ascending: false),
        builder: (data, id) => StoryModel.fromMap(data),
        primaryKey: StoryColumns.id,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<StoryModel>> fetchStories() async {
    if (!(await NetworkStatusService.instance.isConnected())) {
      throw Exception('no-internet');
    }

    try {
      final currentUserId = SupabaseProvider.id;
      final connectionIds = await ConnectionsService().getMyConnectionIds();
      final allowedPrivateIds = await _getPrivateAllowedStoryIds(currentUserId);

      final orParts = <String>[
        'privacy_type.eq.public',
        'author_id.eq.$currentUserId',
      ];
      if (connectionIds.isNotEmpty) {
        orParts.add(
          'and(privacy_type.eq.friends,author_id.in.(${connectionIds.join(',')}))',
        );
      }
      if (allowedPrivateIds.isNotEmpty) {
        orParts.add('id.in.(${allowedPrivateIds.join(',')})');
      }

      return await supabaseServices.fetchRows(
        table: SupabaseConstants.stories,
        columns:
            '*,'
            'story_mentions(${StoryMentionColumns.mentionedUserId},${StoryMentionColumns.startIndex},${StoryMentionColumns.endIndex}),'
            '${SupabaseConstants.users}!stories_author_id_fkey'
            '(${UserColumns.name}, ${UserColumns.imageUrl})',
        filter:
            (query) => query
                .or(orParts.join(','))
                .order(StoryColumns.createdAt, ascending: false),
        builder: (data, id) => StoryModel.fromMap(data),
        primaryKey: StoryColumns.id,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<StoryModel?> fetchStoryById(String storyId) async {
    try {
      final currentUserId = SupabaseProvider.id;
      final connectionIds = await ConnectionsService().getMyConnectionIds();
      final allowedPrivateIds = await _getPrivateAllowedStoryIds(currentUserId);

      final orParts = <String>[
        'privacy_type.eq.public',
        'author_id.eq.$currentUserId',
      ];
      if (connectionIds.isNotEmpty) {
        orParts.add(
          'and(privacy_type.eq.friends,author_id.in.(${connectionIds.join(',')}))',
        );
      }
      if (allowedPrivateIds.isNotEmpty) {
        orParts.add('id.in.(${allowedPrivateIds.join(',')})');
      }

      final rows = await supabaseServices.fetchRows(
        table: SupabaseConstants.stories,
        columns:
            '*,'
            '${SupabaseConstants.users}!stories_author_id_fkey'
            '(${UserColumns.name}, ${UserColumns.imageUrl})',
        filter:
            (query) => query.eq(StoryColumns.id, storyId).or(orParts.join(',')),
        builder: (data, id) => StoryModel.fromMap(data),
        primaryKey: StoryColumns.id,
      );

      return rows.isNotEmpty ? rows.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getMyReaction(String storyId) async {
    final userId = _supabase.auth.currentUser!.id;
    final row =
        await _supabase
            .from(SupabaseConstants.storyReactions)
            .select(StoryReactionColumns.reaction)
            .eq(StoryReactionColumns.storyId, storyId)
            .eq(StoryReactionColumns.userId, userId)
            .maybeSingle();
    return row?[StoryReactionColumns.reaction] as String?;
  }

  Future<String?> toggleStoryReaction({
    required String storyId,
    required String reaction,
  }) async {
    final result = await _supabase.rpc(
      SupabaseConstants.toggleStoryReactionRpc,
      params: {'p_story_id': storyId, 'p_reaction': reaction},
    );
    return result as String?;
  }

  Future<void> markStoryViewed(String storyId) async {
    try {
      await _supabase.rpc(
        SupabaseConstants.markStoryViewedRpc,
        params: {'p_story_id': storyId},
      );
    } catch (e) {
      debugPrint('markStoryViewed silent error: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getStoryViewsStream(String storyId) {
    return _supabase
        .from(SupabaseConstants.storyViews)
        .stream(primaryKey: [StoryColumns.id])
        .eq(StoryViewColumns.storyId, storyId);
  }

  Stream<List<Map<String, dynamic>>> getStoryReactionsStream(String storyId) {
    return _supabase
        .from(SupabaseConstants.storyReactions)
        .stream(primaryKey: [StoryReactionColumns.id])
        .eq(StoryReactionColumns.storyId, storyId);
  }

  Future<List<Map<String, dynamic>>> getMyStoriesOverview() async {
    final response = await _supabase.rpc(
      SupabaseConstants.getMyStoriesOverviewRpc,
    );
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<StoryViewerModel>> getStoryViewers(String storyId) async {
    final response = await _supabase.rpc(
      SupabaseConstants.getStoryViewersRpc,
      params: {'p_story_id': storyId},
    );
    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(StoryViewerModel.fromMap)
        .toList();
  }

  Future<void> createStory(StoryModel story) async {
    await _supabase.from(SupabaseConstants.stories).insert(story.toMap());
  }

  Future<void> insertStoryMentions({
    required String storyId,
    required List<MentionRef> mentions,
  }) async {
    if (mentions.isEmpty) return;
    try {
      await _supabase
          .from(SupabaseConstants.storyMentions)
          .insert(
            mentions
                .map(
                  (m) => {
                    StoryMentionColumns.storyId: storyId,
                    StoryMentionColumns.mentionedUserId: m.mentionedUserId,
                    StoryMentionColumns.startIndex: m.startIndex,
                    StoryMentionColumns.endIndex: m.endIndex,
                  },
                )
                .toList(),
          );
    } catch (e) {
      debugPrint('Error inserting story mentions: $e');
      rethrow;
    }
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await MediaCleanupService.instance.deleteWithMedia(
        table: SupabaseConstants.stories,
        id: storyId,
      );
    } catch (e) {
      rethrow;
    }
  }
}
