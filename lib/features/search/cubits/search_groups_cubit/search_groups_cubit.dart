import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/helpers/safe_emit_mixin.dart';
import '../../../group_chats/models/group_model.dart';
import '../../../group_chats/services/group_chat_services.dart';
import '../../../group_chats/services/group_social_service.dart';
part 'search_groups_state.dart';

class SearchGroupsCubit extends Cubit<SearchGroupsState>
    with SafeEmitMixin<SearchGroupsState> {
  final GroupSocialService _social;

  SearchGroupsCubit({
    GroupChatServices? groupChatServices,
    GroupSocialService? social,
  }) : _social = social ?? GroupSocialService(),
       super(const SearchGroupsInitial());

  List<GroupModel> _discovered = const [];

  Future<void> loadDiscover() async {
    if (_query.isNotEmpty) return;
    emit(SearchGroupsInitial(discovered: _discovered, discoverLoading: true));
    try {
      _discovered = await _social.discoverPublicGroups(limit: _pageSize);
    } catch (e) {
      debugPrint('SearchGroupsCubit.loadDiscover error: $e');
    }
    if (_query.isNotEmpty || isClosed) return;
    emit(SearchGroupsInitial(discovered: _discovered));
  }

  static const int _pageSize = 20;
  String _query = '';

  Future<void> search(String query) async {
    final trimmed = query.trim();
    _query = trimmed;

    if (trimmed.isEmpty) {
      emit(SearchGroupsInitial(discovered: _discovered));
      unawaited(loadDiscover());
      return;
    }

    emit(SearchGroupsLoading());
    try {
      final groups = await _social.searchGroupsGlobal(
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
