import '../../../core/utilities/supabase_constants.dart';
import 'reel_channel_model.dart';

class ReelModel {
  final String id;
  final String youtubeVideoId;
  final String title;
  final String? description;
  final String thumbnailUrl;
  final int originalLikeCount;
  final int originalViewCount;
  final DateTime publishedAt;
  final ReelChannelModel channel;

  String get youtubeWatchUrl =>
      'https://www.youtube.com/watch?v=$youtubeVideoId';
  String get youtubeCommentsUrl => '$youtubeWatchUrl#comments';

  const ReelModel({
    required this.id,
    required this.youtubeVideoId,
    required this.title,
    this.description,
    required this.thumbnailUrl,
    required this.originalLikeCount,
    required this.originalViewCount,
    required this.publishedAt,
    required this.channel,
  });

  factory ReelModel.fromMap(Map<String, dynamic> data) {
    final channelData =
        data[SupabaseConstants.reelChannels] as Map<String, dynamic>;
    return ReelModel(
      id: data[ReelColumns.id] as String,
      youtubeVideoId: data[ReelColumns.youtubeVideoId] as String,
      title: data[ReelColumns.title] as String,
      description: data[ReelColumns.description] as String?,
      thumbnailUrl: data[ReelColumns.thumbnailUrl] as String,
      originalLikeCount: (data[ReelColumns.originalLikeCount] as num).toInt(),
      originalViewCount: (data[ReelColumns.originalViewCount] as num).toInt(),
      publishedAt: DateTime.parse(data[ReelColumns.publishedAt] as String),
      channel: ReelChannelModel.fromMap(channelData),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'youtube_video_id': youtubeVideoId,
    'title': title,
    'description': description,
    'thumbnail_url': thumbnailUrl,
    'original_like_count': originalLikeCount,
    'original_view_count': originalViewCount,
    'published_at': publishedAt.toIso8601String(),
    'channel': channel.toJson(),
  };

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json['id'] as String,
      youtubeVideoId: json['youtube_video_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String,
      originalLikeCount: json['original_like_count'] as int? ?? 0,
      originalViewCount: json['original_view_count'] as int? ?? 0,
      publishedAt: DateTime.parse(json['published_at'] as String),
      channel: ReelChannelModel.fromJson(
        json['channel'] as Map<String, dynamic>,
      ),
    );
  }
}
