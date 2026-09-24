import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/features/posts/models/feed_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/media_cleanup_service.dart';
import '../../../core/services/network_status_service.dart';
import '../../../core/presence/services/presence_service.dart';
import '../../../core/services/supabase_database_services.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utilities/supabase_constants.dart';
import '../../comments/helpers/comment_tree_builder.dart';
import '../../comments/models/comment_model.dart';
import '../../social_graph/models/content_privacy.dart';
import '../../../core/mentions/models/mention_ref.dart';
import '../models/post_model.dart';
import '../models/post_request_body.dart';
import '../models/profile_posts_page.dart';

class PostsServices {
  final supabaseServices = SupabaseDatabaseServices.instance;
  final _supabase = SupabaseProvider.client;
  final NetworkStatusService _networkStatus;

  PostsServices({NetworkStatusService? networkStatus})
    : _networkStatus = networkStatus ?? NetworkStatusService.instance;

  static const String _postFields = ''' 
  *,
  saved_count,
  is_post_saved,
  shares_count,
  is_post_shared,
  post_mentions(${PostMentionColumns.mentionedUserId},${PostMentionColumns.startIndex},${PostMentionColumns.endIndex}),
  ${SupabaseConstants.users}!posts_author_id_fkey (${UserColumns.name}, ${UserColumns.imageUrl}, ${UserColumns.lastSeen}),
  ${SupabaseConstants.reelsCache}!posts_shared_reel_id_fkey (
    ${ReelColumns.id},
    ${ReelColumns.youtubeVideoId},
    ${ReelColumns.title},
    ${ReelColumns.description},
    ${ReelColumns.thumbnailUrl},
    ${ReelColumns.originalLikeCount},
    ${ReelColumns.originalViewCount},
    ${ReelColumns.publishedAt},
    ${SupabaseConstants.reelChannels} (
      ${ReelChannelColumns.id},
      ${ReelChannelColumns.channelName},
      ${ReelChannelColumns.channelAvatarUrl}
    )
  ),
  ${SupabaseConstants.comments} (
  *,
  ${SupabaseConstants.users} (${UserColumns.name}, ${UserColumns.imageUrl}), 
  comment_reactions (*)
  ),
  ${SupabaseConstants.likes} (
  ${LikeColumns.userId}, 
  ${LikeColumns.reaction},
  ${SupabaseConstants.users} (${UserColumns.imageUrl}))
''';

  static const String _postsQuery = _postFields;

  PostModel _hydratePost(Map<String, dynamic> data) {
    final post = PostModel.fromMap(data);

    final flatComments =
        (data['comments'] as List? ?? [])
            .map((e) => CommentModel.fromMap(e))
            .toList();
    final tree = CommentTreeBuilder.build(flatComments);

    PostModel? hydratedOriginal;
    final originalData =
        data[PostColumns.originalPostRelation] as Map<String, dynamic>?;
    if (originalData != null) {
      hydratedOriginal = _hydratePost(originalData);
    }
    return post.copyWith(
      comments: tree,
      originalPost: hydratedOriginal ?? post.originalPost,
    );
  }

  Future<List<PostModel>> _resolveSharedPostsAndHydrate(
    List<Map<String, dynamic>> rawPostsData,
  ) async {
    if (rawPostsData.isEmpty) return [];

    final Set<String> sharedPostIds =
        rawPostsData
            .map((p) => p['shared_post_id'] as String?)
            .whereType<String>()
            .toSet();

    final Map<String, Map<String, dynamic>> originalsDataMap = {};

    if (sharedPostIds.isNotEmpty) {
      try {
        final originalsResponse = await _supabase
            .from(SupabaseConstants.posts)
            .select(_postsQuery)
            .inFilter(PostColumns.id, sharedPostIds.toList());

        for (final org in originalsResponse as List) {
          originalsDataMap[org[PostColumns.id] as String] =
              org as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('Error fetching original posts batch: $e');
      }
    }

    return rawPostsData.map((data) {
      final mutableData = Map<String, dynamic>.from(data);
      final sharedId = mutableData['shared_post_id'] as String?;

      if (sharedId != null && originalsDataMap.containsKey(sharedId)) {
        mutableData[PostColumns.originalPostRelation] =
            originalsDataMap[sharedId];
      }
      return _hydratePost(mutableData);
    }).toList();
  }

  Future<Map<String, bool>> _fetchOnlineMap(List<String> authorIds) async {
    if (authorIds.isEmpty) return {};
    final presenceRows = await _supabase
        .from(SupabaseConstants.userPresence)
        .select('user_id, is_online, updated_at')
        .inFilter(GroupMemberColumns.userId, authorIds);

    final onlineSet = <String>{
      for (final row in presenceRows as List)
        if (PresenceService.isConsideredOnline(
          isOnline: row[PresenceColumns.isOnline] as bool? ?? false,
          updatedAt:
              row[PresenceColumns.updatedAt] != null
                  ? DateTime.parse(row[PresenceColumns.updatedAt].toString())
                  : null,
        ))
          row[GroupMemberColumns.userId] as String,
    };
    return {for (final id in authorIds) id: onlineSet.contains(id)};
  }

  PostModel _applyOnline(PostModel post, Map<String, bool> onlineMap) {
    final withOnline = post.copyWith(
      isOnline: onlineMap[post.authorId] ?? false,
    );
    if (withOnline.originalPost == null) return withOnline;
    return withOnline.copyWith(
      originalPost: withOnline.originalPost!.copyWith(
        isOnline: onlineMap[withOnline.originalPost!.authorId] ?? false,
      ),
    );
  }

  Future<ProfilePostsPage> fetchUserProfilePosts(
    String userId, {
    int pageSize = 15,
    bool? beforeIsPinned,
    String? beforeCreatedAt,
    String? beforeId,
  }) async {
    if (!(await _networkStatus.isConnected())) {
      throw Exception('no-internet');
    }

    final rows = await _supabase.rpc(
      SupabaseConstants.getUserProfilePostIdsRpc,
      params: {
        'p_user_id': userId,
        'p_limit': pageSize + 1,
        if (beforeCreatedAt != null && beforeId != null) ...{
          'p_before_is_pinned': beforeIsPinned ?? false,
          'p_before_created_at': beforeCreatedAt,
          'p_before_id': beforeId,
        },
      },
    );

    final all = (rows as List).cast<Map<String, dynamic>>();
    final hasMore = all.length > pageSize;
    final page = hasMore ? all.sublist(0, pageSize) : all;
    if (page.isEmpty) return ProfilePostsPage.empty;

    final ids = [for (final r in page) r['post_id'] as String];
    final posts = await fetchPostsByIds(ids); // keeps the RPC order
    if (posts.isEmpty) throw Exception('profile-posts-hydration-failed');

    return ProfilePostsPage(
      posts: posts,
      hasMore: hasMore,
      nextCursorIsPinned: page.last['post_is_pinned'] as bool? ?? false,
      nextCursorCreatedAt: page.last['post_created_at'] as String,
      nextCursorId: page.last['post_id'] as String,
    );
  }

  Future<({bool pinned, int pinnedCount})> setPostPinned(
    String postId,
    bool pinned,
  ) async {
    final rows = await _supabase.rpc(
      SupabaseConstants.setPostPinnedRpc,
      params: {'p_post_id': postId, 'p_pinned': pinned},
    );
    final row = (rows as List).first as Map<String, dynamic>;
    return (
      pinned: row['pinned'] as bool,
      pinnedCount: (row['pinned_count'] as num).toInt(),
    );
  }

  Future<PostModel?> fetchPostById(String postId) async {
    try {
      final rows = await _supabase
          .from(SupabaseConstants.posts)
          .select(_postsQuery)
          .eq(PostColumns.id, postId)
          .limit(1);

      if (rows.isEmpty) return null;

      final hydratedList = await _resolveSharedPostsAndHydrate(
        List<Map<String, dynamic>>.from(rows),
      );
      if (hydratedList.isEmpty) return null;

      final postWithComments = hydratedList.first;
      final authorIds =
          <String>{
            postWithComments.authorId,
            if (postWithComments.originalPost != null)
              postWithComments.originalPost!.authorId,
          }.toList();

      final onlineMap = await _fetchOnlineMap(authorIds);
      return _applyOnline(postWithComments, onlineMap);
    } catch (e) {
      debugPrint('fetchPostById error: $e');
      return null;
    }
  }

  Future<void> setPostAllowedViewers(
    String postId,
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return;
    await _supabase
        .from(SupabaseConstants.postAllowedViewers)
        .insert(
          userIds.map((id) => {'post_id': postId, 'user_id': id}).toList(),
        );
  }

  Future<List<PostModel>> fetchPostsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final response = await _supabase
          .from(SupabaseConstants.posts)
          .select(_postsQuery)
          .inFilter(PostColumns.id, ids);

      final rawPosts = List<Map<String, dynamic>>.from(response);
      final posts = await _resolveSharedPostsAndHydrate(rawPosts);
      if (posts.isEmpty) return posts;

      final authorIds =
          <String>{
            for (final p in posts) ...[
              p.authorId,
              if (p.originalPost != null) p.originalPost!.authorId,
            ],
          }.toList();
      final onlineMap = await _fetchOnlineMap(authorIds);
      final hydrated = posts.map((p) => _applyOnline(p, onlineMap)).toList();

      final byId = {for (final p in hydrated) p.id: p};
      return ids.map((id) => byId[id]).whereType<PostModel>().toList();
    } catch (e) {
      debugPrint('fetchPostsByIds error: $e');
      return [];
    }
  }

  Future<List<String>> searchPostIds({
    required String query,
    int limit = 12,
    int offset = 0,
  }) async {
    final rows = await _supabase.rpc(
      'search_posts',
      params: {
        'p_query': query,
        'p_user_id': SupabaseProvider.id,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return (rows as List).map((r) => r['id'] as String).toList();
  }

  Future<List<PostModel>> fetchRankedHomeFeed({int limit = 50}) async {
    if (!(await _networkStatus.isConnected())) {
      throw Exception('no-internet');
    }
    try {
      final currentUserId = SupabaseProvider.id;

      final rankedRows = await _supabase.rpc(
        SupabaseConstants.getRankedHomeFeedRpc,
        params: {'p_user_id': currentUserId, 'p_limit': limit},
      );

      final ranked = (rankedRows as List).cast<Map<String, dynamic>>();
      if (ranked.isEmpty) return [];

      final orderedIds = ranked.map((r) => r['post_id'] as String).toList();
      final suggestedById = {
        for (final r in ranked)
          r['post_id'] as String: r['is_suggested_for_you'] as bool? ?? false,
      };

      final hydrated = await fetchPostsByIds(orderedIds);

      final flagged =
          hydrated
              .map(
                (p) =>
                    p.copyWith(isSuggestedForYou: suggestedById[p.id] ?? false),
              )
              .toList();

      return _spreadOutByAuthor(flagged);
    } catch (e) {
      rethrow;
    }
  }

  List<PostModel> _spreadOutByAuthor(
    List<PostModel> ranked, {
    int minGap = 2,
    int lookahead = 15,
  }) {
    final remaining = List<PostModel>.of(ranked);
    final result = <PostModel>[];

    bool authorAllowed(String authorId) {
      final start = result.length - minGap;
      for (var i = result.length - 1; i >= 0 && i >= start; i--) {
        if (result[i].authorId == authorId) return false;
      }
      return true;
    }

    while (remaining.isNotEmpty) {
      if (authorAllowed(remaining.first.authorId)) {
        result.add(remaining.removeAt(0));
        continue;
      }

      final searchLimit =
          remaining.length < lookahead ? remaining.length : lookahead;
      var swapIndex = -1;
      for (var i = 1; i < searchLimit; i++) {
        if (authorAllowed(remaining[i].authorId)) {
          swapIndex = i;
          break;
        }
      }

      if (swapIndex != -1) {
        result.add(remaining.removeAt(swapIndex));
      } else {
        // No eligible alternative nearby (e.g. this author dominates
        // the whole remaining pool) — place it anyway rather than
        // stall or drop content.
        result.add(remaining.removeAt(0));
      }
    }

    return result;
  }

  Stream<FeedEvent> getPostsStream() {
    final controller = StreamController<FeedEvent>.broadcast();

    const channelName = 'home_feed_watcher';
    final existingChannels = _supabase.getChannels();
    for (final c in existingChannels) {
      // ignore: invalid_use_of_internal_member
      if (c.topic == 'realtime:$channelName') {
        _supabase.removeChannel(c);
      }
    }

    final channel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConstants.posts,
          callback: (payload) {
            debugPrint('📥 Payload Received: \${payload.newRecord}');
            final postId = payload.newRecord[PostColumns.id] as String?;
            if (postId != null && !controller.isClosed) {
              controller.add(PostInsertedEvent(postId));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseConstants.posts,
          callback: (payload) {
            final postId = payload.newRecord[PostColumns.id] as String?;
            if (postId != null && !controller.isClosed) {
              controller.add(PostUpdatedEvent(postId));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: SupabaseConstants.posts,
          callback: (payload) {
            final postId = payload.oldRecord[PostColumns.id] as String?;
            if (postId != null && !controller.isClosed) {
              controller.add(PostDeletedEvent(postId));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.likes,
          callback: (payload) {
            final record =
                payload.newRecord.isNotEmpty
                    ? payload.newRecord
                    : payload.oldRecord;
            final postId = record[LikeColumns.postId] as String?;
            if (postId != null && !controller.isClosed) {
              controller.add(LikeChangedEvent(postId, payload.eventType));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.comments,
          callback: (payload) {
            final record =
                payload.newRecord.isNotEmpty
                    ? payload.newRecord
                    : payload.oldRecord;
            final postId = record[CommentColumns.postId] as String?;

            if (postId != null && !controller.isClosed) {
              controller.add(PostUpdatedEvent(postId));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.postShares,
          callback: (payload) {
            final record =
                payload.newRecord.isNotEmpty
                    ? payload.newRecord
                    : payload.oldRecord;
            final postId = record[PostShareColumns.postId] as String?;
            if (postId != null && !controller.isClosed) {
              controller.add(ShareChangedEvent(postId, payload.eventType));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.userPresence,
          callback: (payload) {
            final record = payload.newRecord;
            final userId = record[GroupMemberColumns.userId] as String?;
            if (userId != null && !controller.isClosed) {
              final isOnline =
                  record[PresenceColumns.isOnline] as bool? ?? false;
              final updatedAtRaw = record[PresenceColumns.updatedAt] as String?;
              final updatedAt =
                  updatedAtRaw != null ? DateTime.tryParse(updatedAtRaw) : null;
              controller.add(PresenceChangedEvent(userId, isOnline, updatedAt));
            }
          },
        )
        .subscribe((status, [error]) {
          debugPrint('[FeedStream] status: $status');
        });

    controller.onCancel = () {
      _supabase.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  Future<void> addPost(PostRequestBody post) async {
    try {
      await supabaseServices.insertRow(
        table: SupabaseConstants.posts,
        values: post.toMap(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> insertPostMentions({
    required String postId,
    required List<MentionRef> mentions,
  }) async {
    if (mentions.isEmpty) return;
    try {
      await _supabase
          .from(SupabaseConstants.postMentions)
          .insert(
            mentions
                .map(
                  (m) => {
                    PostMentionColumns.postId: postId,
                    PostMentionColumns.mentionedUserId: m.mentionedUserId,
                    PostMentionColumns.startIndex: m.startIndex,
                    PostMentionColumns.endIndex: m.endIndex,
                  },
                )
                .toList(),
          );
    } catch (e) {
      debugPrint('Error inserting post mentions: $e');
      rethrow;
    }
  }

  Future<void> shareReel({
    required String postId,
    required String reelId,
    required String authorId,
  }) async {
    try {
      await supabaseServices.insertRow(
        table: SupabaseConstants.posts,
        values: {
          PostColumns.id: postId,
          PostColumns.text: '',
          PostColumns.authorId: authorId,
          PostColumns.sharedReelId: reelId,
          PostColumns.privacyType: contentPrivacyToString(
            ContentPrivacy.public,
          ),
        },
      );
    } catch (e) {
      debugPrint('Error sharing reel: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await MediaCleanupService.instance.deleteWithMedia(
        table: SupabaseConstants.posts,
        id: postId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleReaction({
    required String postId,
    required String userId,
    required String emoji,
    String? currentEmoji,
  }) async {
    try {
      await _supabase.from(SupabaseConstants.likes).delete().match({
        LikeColumns.postId: postId,
        LikeColumns.userId: userId,
      });

      if (currentEmoji == emoji) return;

      await _supabase.from(SupabaseConstants.likes).insert({
        LikeColumns.postId: postId,
        LikeColumns.userId: userId,
        LikeColumns.reaction: emoji,
      });
    } catch (e) {
      debugPrint("Error toggling reaction in DB: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> toggleSharePost({required String postId}) async {
    try {
      final response = await _supabase.rpc(
        SupabaseConstants.togglePostShareRpc,
        params: {'p_post_id': postId},
      );
      final rows = response as List;
      if (rows.isEmpty) {
        throw Exception('toggle_post_share returned no rows');
      }
      return rows.first as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error toggling share in DB: $e');
      rethrow;
    }
  }

  Future<int> incrementPostLinkShareCount(String postId) async {
    try {
      final response = await _supabase.rpc(
        'increment_post_link_share_count',
        params: {'p_post_id': postId},
      );
      return (response as int?) ?? 0;
    } catch (e) {
      debugPrint('Error incrementing link share count: $e');
      rethrow;
    }
  }

  Future<void> toggleSavePost({
    required String postId,
    required String userId,
    required bool isCurrentlySaved,
  }) async {
    try {
      if (isCurrentlySaved) {
        await _supabase.from(SupabaseConstants.savedPosts).delete().match({
          SavedPostColumns.postId: postId,
          SavedPostColumns.userId: userId,
        });
      } else {
        await _supabase.from(SupabaseConstants.savedPosts).insert({
          SavedPostColumns.postId: postId,
          SavedPostColumns.userId: userId,
        });
      }
    } catch (e) {
      debugPrint('Error toggling saved post in DB: $e');
      rethrow;
    }
  }

  Future<List<PostModel>> fetchSavedPosts(String userId) async {
    if (!(await _networkStatus.isConnected())) {
      throw Exception('no-internet');
    }
    try {
      final rows = await _supabase
          .from(SupabaseConstants.savedPosts)
          .select(
            '${SavedPostColumns.createdAt}, ${SupabaseConstants.posts} ($_postsQuery)',
          )
          .eq(SavedPostColumns.userId, userId)
          .order(SavedPostColumns.createdAt, ascending: false);

      final List<Map<String, dynamic>> rawPostsData = [];
      for (final row in rows as List) {
        final postData = row[SupabaseConstants.posts] as Map<String, dynamic>?;
        if (postData != null) {
          rawPostsData.add(postData);
        }
      }

      final savedPosts = await _resolveSharedPostsAndHydrate(rawPostsData);
      return savedPosts;
    } catch (e) {
      debugPrint('fetchSavedPosts error: $e');
      rethrow;
    }
  }
}
