import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/data/models/user_data.dart';
import '../../../../features/group_chats/models/group_model.dart';
import '../../../../features/group_chats/services/group_chat_services.dart';
import '../../../../features/social_graph/services/connections_service.dart';
import '../../models/new_chat_list_item.dart';
import '../../models/new_chat_row.dart';
part 'new_chat_state.dart';

class NewChatCubit extends Cubit<NewChatState> {
  final ConnectionsService _connectionsService;
  final GroupChatServices _groupChatServices;

  List<NewChatListItem> _allItems = [];
  Set<String> _blockedPersonIds = {};

  NewChatCubit(this._connectionsService, this._groupChatServices)
    : super(NewChatInitial());

  Future<void> loadNewChatCandidates() async {
    emit(NewChatLoading());
    try {
      final results = await Future.wait([
        _connectionsService.getMyConnections(),
        _groupChatServices.getMyGroups(),
        _connectionsService.getMyBlockedPersonIds(), // 🆕
      ]);

      final people =
          (results[0] as List<Map<String, dynamic>>)
              .map((row) => NewChatListItem.person(UserData.fromMap(row)))
              .toList();

      final groups =
          (results[1] as List<GroupModel>).map(NewChatListItem.group).toList();

      _blockedPersonIds = results[2] as Set<String>;
      _allItems = [...people, ...groups];

      emit(NewChatLoaded(rows: _buildRows(_allItems, '')));
    } catch (e) {
      emit(const NewChatError('Failed to load contacts. Please try again.'));
    }
  }

  void search(String query) {
    if (state is! NewChatLoaded) return;
    emit(NewChatLoaded(rows: _buildRows(_allItems, query), query: query));
  }

  bool _isItemBlocked(NewChatListItem item) =>
      item.isGroup
          ? item.group!.isBlocked
          : _blockedPersonIds.contains(item.id);

  List<NewChatRow> _buildRows(List<NewChatListItem> items, String query) {
    final trimmed = query.trim().toLowerCase();

    final matched =
        trimmed.isEmpty
            ? items
            : items.where((item) {
              if (item.isGroup) {
                return item.group!.name.toLowerCase().contains(trimmed);
              }
              final p = item.person!;
              return p.name.toLowerCase().contains(trimmed) ||
                  (p.userName?.toLowerCase().contains(trimmed) ?? false);
            }).toList();

    // ── تقسيم النتائج: نشِط / محظور أشخاص / محظور جروبات ──
    final active = <NewChatListItem>[];
    final blockedPeople = <NewChatListItem>[];
    final blockedGroups = <NewChatListItem>[];

    for (final item in matched) {
      if (!_isItemBlocked(item)) {
        active.add(item);
      } else if (item.isGroup) {
        blockedGroups.add(item);
      } else {
        blockedPeople.add(item);
      }
    }

    int byName(NewChatListItem a, NewChatListItem b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());

    active.sort(byName);
    blockedPeople.sort(byName);
    blockedGroups.sort(byName);

    return [
      ...active.map((e) => NewChatItemRow(e)),
      if (blockedPeople.isNotEmpty) ...[
        const NewChatSectionHeaderRow('Blocked Contacts'),
        ...blockedPeople.map((e) => NewChatItemRow(e, isBlocked: true)),
      ],
      if (blockedGroups.isNotEmpty) ...[
        const NewChatSectionHeaderRow('Blocked Groups'),
        ...blockedGroups.map((e) => NewChatItemRow(e, isBlocked: true)),
      ],
    ];
  }
}
