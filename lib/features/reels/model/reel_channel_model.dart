import '../../../core/utilities/supabase_constants.dart';

class ReelChannelModel {
  final String id;
  final String channelName;
  final String? channelAvatarUrl;

  const ReelChannelModel({
    required this.id,
    required this.channelName,
    this.channelAvatarUrl,
  });

  factory ReelChannelModel.fromMap(Map<String, dynamic> data) {
    return ReelChannelModel(
      id: data[ReelChannelColumns.id] as String,
      channelName: data[ReelChannelColumns.channelName] as String,
      channelAvatarUrl: data[ReelChannelColumns.channelAvatarUrl] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'channel_name': channelName,
    'channel_avatar_url': channelAvatarUrl,
  };

  factory ReelChannelModel.fromJson(Map<String, dynamic> json) {
    return ReelChannelModel(
      id: json['id'] as String,
      channelName: json['channel_name'] as String,
      channelAvatarUrl: json['channel_avatar_url'] as String?,
    );
  }
}
