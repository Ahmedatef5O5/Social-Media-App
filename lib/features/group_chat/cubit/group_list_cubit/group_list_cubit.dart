import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/group_model.dart';
import '../../services/group_chat_services.dart';

part 'group_list_state.dart';

class GroupListCubit extends Cubit<GroupListState> {
  final GroupChatServices _services;
  StreamSubscription? _streamSubscription;
  Timer? _refreshDebounce;
  List<GroupModel> _cached = [];

  List<GroupModel> cachedGroupsChats = [];

  GroupListCubit(this._services) : super(GroupListInitial());

  void monitorGroups() {
    loadGroups();
    _streamSubscription?.cancel();
    _streamSubscription = _services.getGroupsListStream().listen((_) {
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(const Duration(milliseconds: 200), () {
        loadGroups(isRefresh: true);
      });
    });
  }

  Future<void> loadGroups({bool isRefresh = false}) async {
    if (!isRefresh) emit(GroupListLoading());
    try {
      _cached = await _services.getMyGroups();
      emit(GroupListLoaded(_cached));
    } catch (e) {
      emit(GroupListError(e.toString()));
    }
  }

  Future<GroupModel> createGroup({
    required String name,
    String? avatarUrl,
    required List<String> memberIds,
  }) async {
    final group = await _services.createGroup(
      name: name,
      avatarUrl: avatarUrl,
      memberIds: memberIds,
    );
    await loadGroups(isRefresh: true);
    return group;
  }

  void updateGroupLastMessage({
    required String groupId,
    required String message,
    required String messageType,
    required DateTime createdAt,
  }) {
    if (state is GroupListLoaded) {
      final currentState = state as GroupListLoaded;

      final updatedGroups =
          currentState.groups.map((group) {
            if (group.id == groupId) {
              return group.copyWith(
                lastMessage: message,
                lastMessageType: messageType,
                lastMessageAt: createdAt,
              );
            }
            return group;
          }).toList();

      updatedGroups.sort((a, b) {
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });

      emit(GroupListLoaded(updatedGroups));
    }
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    _refreshDebounce?.cancel();
    return super.close();
  }
}
