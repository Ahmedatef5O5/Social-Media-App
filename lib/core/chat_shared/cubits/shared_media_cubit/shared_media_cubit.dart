import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/shared_media_item.dart';
import '../../services/shared_media_data_source.dart';
part 'shared_media_state.dart';

enum SharedMediaTab { all, images, videos, voice, links }

class SharedMediaCubit extends Cubit<SharedMediaState> {
  final SharedMediaDataSource _dataSource;

  SharedMediaCubit(this._dataSource) : super(const SharedMediaState());

  Future<void> loadPreview() async {
    if (state.previewLoaded || state.previewLoading) return;
    emit(state.copyWith(previewLoading: true));

    try {
      final items = await _dataSource.loadPreview();

      if (isClosed) return;

      emit(
        state.copyWith(
          preview: items,
          previewLoading: false,
          previewLoaded: true,
        ),
      );
    } catch (e) {
      debugPrint('[SharedMediaCubit] loadPreview error: $e');
      if (isClosed) return;
      emit(state.copyWith(previewLoading: false));
    }
  }

  Future<void> loadTab(SharedMediaTab tab) async {
    if (state.loadedTabs.contains(tab) || state.loadingTabs.contains(tab)) {
      return;
    }
    emit(state.copyWith(loadingTabs: {...state.loadingTabs, tab}));

    try {
      List<SharedMediaItem> items;
      if (tab == SharedMediaTab.all) {
        items = await _dataSource.loadPreview(limit: 100);
      } else if (tab == SharedMediaTab.links) {
        items = await _dataSource.loadLinks(limit: 100);
      } else {
        items = await _dataSource.loadMediaByType(
          _messageTypeFor(tab),
          limit: 100,
        );
      }

      if (isClosed) return;

      emit(
        state.copyWith(
          items: {...state.items, tab: items},
          loadingTabs: {...state.loadingTabs}..remove(tab),
          loadedTabs: {...state.loadedTabs, tab},
        ),
      );
    } catch (e) {
      debugPrint('[SharedMediaCubit] loadTab($tab) error: $e');
      if (isClosed) return;
      emit(
        state.copyWith(
          loadingTabs: {...state.loadingTabs}..remove(tab),
          tabErrors: {...state.tabErrors, tab: e.toString()},
        ),
      );
    }
  }

  Future<void> deleteItem(
    SharedMediaItem item, {
    required bool forEveryone,
  }) async {
    if (forEveryone) {
      await _dataSource.deleteItemForEveryone(item.id);
    } else {
      await _dataSource.deleteItemForMe(item.id);
    }
    _removeItemLocally(item.id);
  }

  void _removeItemLocally(String messageId) {
    final updatedItems = <SharedMediaTab, List<SharedMediaItem>>{
      for (final entry in state.items.entries)
        entry.key: entry.value.where((m) => m.id != messageId).toList(),
    };
    emit(
      state.copyWith(
        items: updatedItems,
        preview: state.preview.where((m) => m.id != messageId).toList(),
      ),
    );
  }

  String _messageTypeFor(SharedMediaTab tab) {
    switch (tab) {
      case SharedMediaTab.all:
        return '';
      case SharedMediaTab.images:
        return 'image';
      case SharedMediaTab.videos:
        return 'video';
      case SharedMediaTab.voice:
        return 'voice';
      case SharedMediaTab.links:
        return 'text';
    }
  }
}
