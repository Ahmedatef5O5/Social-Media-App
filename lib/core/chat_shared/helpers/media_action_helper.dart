import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/features/home/cubits/home_cubit/home_cubit.dart';
import '../../toast/app_toast.dart';
import '../cubits/shared_media_cubit/shared_media_cubit.dart';
import '../models/shared_media_item.dart';
import '../views/full_screen_media_pager.dart';

typedef ShowInChatCallback =
    void Function(BuildContext context, String messageId);

class MediaActionHelper {
  MediaActionHelper._();

  static void openFullScreenMedia(
    BuildContext context,
    List<SharedMediaItem> tabItems,
    SharedMediaItem tappedItem,
  ) {
    final playable =
        tabItems
            .where(
              (i) =>
                  i.messageType == 'image' ||
                  i.messageType == 'video' ||
                  (i.voiceUrl ?? '').isNotEmpty,
            )
            .toList();

    final initialIndex = playable.indexWhere((i) => i.id == tappedItem.id);
    final currentUserAvatar =
        context.read<HomeCubit>().currentUserData?.imageUrl;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder:
            (_, __, ___) => FullScreenMediaPager(
              items: playable,
              initialIndex: initialIndex < 0 ? 0 : initialIndex,
              currentUserAvatar: currentUserAvatar,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  static void handleShowInChat(
    BuildContext context,
    SharedMediaItem item,
    ShowInChatCallback? onShowInChat,
  ) {
    if (onShowInChat == null) {
      AppToast.info('Open this from a chat to jump to the message');
      return;
    }

    onShowInChat(context, item.id);
  }

  static Future<void> handleDelete(
    BuildContext context,
    SharedMediaItem item, {
    required bool forEveryone,
  }) async {
    try {
      await context.read<SharedMediaCubit>().deleteItem(
        item,
        forEveryone: forEveryone,
      );

      if (context.mounted) {
        AppToast.success(
          forEveryone ? 'Deleted for everyone' : 'Deleted for you',
        );
      }
    } catch (e) {
      debugPrint('[MediaActionHelper] delete error: $e');

      if (context.mounted) {
        AppToast.error('Failed to delete message');
      }
    }
  }
}
