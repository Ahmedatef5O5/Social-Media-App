import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/groupe_message_model.dart';
import '../../services/group_chat_services.dart';
part 'group_media_state.dart';

enum GroupMediaTab { all, images, videos, voice, links }

class GroupMediaCubit extends Cubit<GroupMediaState> {
  final GroupChatServices _services;
  final String groupId;

  GroupMediaCubit(this._services, {required this.groupId})
    : super(const GroupMediaState());

  Future<void> loadPreview() async {
    if (state.previewLoaded || state.previewLoading) return;
    emit(state.copyWith(previewLoading: true));

    try {
      final items = await _services.getGroupMediaPreview(groupId: groupId);
      emit(
        state.copyWith(
          preview: items,
          previewLoading: false,
          previewLoaded: true,
        ),
      );
    } catch (e) {
      debugPrint('[GroupMediaCubit] loadPreview error: $e');
      emit(state.copyWith(previewLoading: false));
    }
  }

  Future<void> loadTab(GroupMediaTab tab) async {
    if (state.loadedTabs.contains(tab) || state.loadingTabs.contains(tab)) {
      return;
    }
    emit(state.copyWith(loadingTabs: {...state.loadingTabs, tab}));

    try {
      List<GroupMessageModel> items;
      if (tab == GroupMediaTab.all) {
        items = await _services.getGroupMediaPreview(
          groupId: groupId,
          limit: 100,
        );
      } else if (tab == GroupMediaTab.links) {
        items = await _services.getGroupLinkMessages(groupId: groupId);
      } else {
        items = await _services.getGroupMediaMessages(
          groupId: groupId,
          messageType: _messageTypeFor(tab),
        );
      }

      emit(
        state.copyWith(
          items: {...state.items, tab: items},
          loadingTabs: {...state.loadingTabs}..remove(tab),
          loadedTabs: {...state.loadedTabs, tab},
        ),
      );
    } catch (e) {
      debugPrint('[GroupMediaCubit] loadTab($tab) error: $e');
      emit(
        state.copyWith(
          loadingTabs: {...state.loadingTabs}..remove(tab),
          tabErrors: {...state.tabErrors, tab: e.toString()},
        ),
      );
    }
  }

  String _messageTypeFor(GroupMediaTab tab) {
    switch (tab) {
      case GroupMediaTab.all:
        return '';
      case GroupMediaTab.images:
        return 'image';
      case GroupMediaTab.videos:
        return 'video';
      case GroupMediaTab.voice:
        return 'voice';
      case GroupMediaTab.links:
        return 'text';
    }
  }
}
