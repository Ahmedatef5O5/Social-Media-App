import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/features/social_graph/models/friend_list_item_model.dart';
import '../../model/sticker_pack_model.dart';
import '../../model/sticker_pack_privacy.dart';

abstract class CreateStickerPackState {}

class CreateStickerPackLoading extends CreateStickerPackState {}

class CreateStickerPackUploading extends CreateStickerPackState {
  final int done;
  final int total;
  CreateStickerPackUploading({required this.done, required this.total});
}

class CreateStickerPackSuccess extends CreateStickerPackState {
  final StickerPackModel pack;
  CreateStickerPackSuccess(this.pack);
}

class CreateStickerPackQuotaBlocked extends CreateStickerPackState {
  final List<StickerPackModel> myPacks;
  final bool isDeleting;

  CreateStickerPackQuotaBlocked({
    required this.myPacks,
    this.isDeleting = false,
  });

  CreateStickerPackQuotaBlocked copyWith({
    List<StickerPackModel>? myPacks,
    bool? isDeleting,
  }) => CreateStickerPackQuotaBlocked(
    myPacks: myPacks ?? this.myPacks,
    isDeleting: isDeleting ?? this.isDeleting,
  );
}

class CreateStickerPackForm extends CreateStickerPackState {
  static const int maxStickers = 20;
  static const int maxTotalSizeBytes = 25 * 1024 * 1024; // 25 MB

  final String title;
  final List<XFile> images;
  final int totalSizeBytes;
  final StickerPackPrivacy privacy;
  final List<FriendListItemModel> allFriends;
  final Set<String> selectedFriendIds;
  final bool isSubmitting;

  CreateStickerPackForm({
    this.title = '',
    this.images = const [],
    this.totalSizeBytes = 0,
    this.privacy = StickerPackPrivacy.public,
    this.allFriends = const [],
    this.selectedFriendIds = const {},
    this.isSubmitting = false,
  });

  bool get canSubmit =>
      title.trim().isNotEmpty &&
      images.isNotEmpty &&
      images.length <= maxStickers &&
      totalSizeBytes <= maxTotalSizeBytes &&
      (privacy != StickerPackPrivacy.friends || selectedFriendIds.isNotEmpty) &&
      !isSubmitting;

  CreateStickerPackForm copyWith({
    String? title,
    List<XFile>? images,
    int? totalSizeBytes,
    StickerPackPrivacy? privacy,
    List<FriendListItemModel>? allFriends,
    Set<String>? selectedFriendIds,
    bool? isSubmitting,
  }) {
    return CreateStickerPackForm(
      title: title ?? this.title,
      images: images ?? this.images,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      privacy: privacy ?? this.privacy,
      allFriends: allFriends ?? this.allFriends,
      selectedFriendIds: selectedFriendIds ?? this.selectedFriendIds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class CreateStickerPackError extends CreateStickerPackState {
  final String message;
  CreateStickerPackError(this.message);
}
