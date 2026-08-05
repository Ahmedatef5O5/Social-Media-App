import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../social_graph/models/content_privacy.dart';
import '../cubit/create_sticker_pack_cubit/create_sticker_pack_cubit.dart';
import '../cubit/create_sticker_pack_cubit/create_sticker_pack_state.dart';
import '../model/sticker_pack_privacy.dart';
import '../widgets/friend_picker_sheet.dart';

Future<void> showCreatePackFriendPicker(BuildContext context) async {
  final cubit = context.read<CreateStickerPackCubit>();
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder:
        (_) => BlocBuilder<CreateStickerPackCubit, CreateStickerPackState>(
          bloc: cubit,
          builder: (context, latest) {
            final form = latest as CreateStickerPackForm;
            return FriendPickerSheet(
              friends: form.allFriends,
              selectedIds: form.selectedFriendIds,
              onToggle: cubit.toggleFriend,
            );
          },
        ),
  );
}

extension StickerPackPrivacyMapper on StickerPackPrivacy {
  ContentPrivacy toContentPrivacy() {
    switch (this) {
      case StickerPackPrivacy.public:
        return ContentPrivacy.public;
      case StickerPackPrivacy.private:
        return ContentPrivacy.private;
      case StickerPackPrivacy.friends:
        return ContentPrivacy.friends;
    }
  }
}

extension ContentPrivacyMapper on ContentPrivacy {
  StickerPackPrivacy toStickerPackPrivacy() {
    switch (this) {
      case ContentPrivacy.public:
        return StickerPackPrivacy.public;
      case ContentPrivacy.private:
        return StickerPackPrivacy.private;
      case ContentPrivacy.friends:
        return StickerPackPrivacy.friends;
    }
  }
}
