import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../group_chats/models/group_model.dart';
import '../../../group_chats/services/group_chat_services.dart';
part 'search_groups_state.dart';

class SearchGroupsCubit extends Cubit<SearchGroupsState> {
  final GroupChatServices _groupChatServices;

  SearchGroupsCubit({GroupChatServices? groupChatServices})
    : _groupChatServices = groupChatServices ?? GroupChatServices(),
      super(SearchGroupsInitial());

  static const int _pageSize = 20;
  String _query = '';

  Future<void> search(String query) async {
    final trimmed = query.trim();
    _query = trimmed;

    if (trimmed.isEmpty) {
      emit(SearchGroupsInitial());
      return;
    }

    emit(SearchGroupsLoading());
    try {
      final groups = await _groupChatServices.searchMyGroups(
        query: trimmed,
        limit: _pageSize,
      );
      if (_query != trimmed) return;
      emit(SearchGroupsLoaded(groups));
    } catch (e) {
      if (_query != trimmed) return;
      debugPrint('SearchGroupsCubit.search error: $e');
      emit(
        const SearchGroupsError(
          'Something went wrong. Please try again later.',
        ),
      );
    }
  }
}
