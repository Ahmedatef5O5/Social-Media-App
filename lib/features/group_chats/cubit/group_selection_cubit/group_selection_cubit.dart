import 'package:flutter_bloc/flutter_bloc.dart';

class GroupSelectionState {
  final Set<String> selectedIds;
  const GroupSelectionState(this.selectedIds);

  bool get isSelecting => selectedIds.isNotEmpty;
  bool isSelected(String id) => selectedIds.contains(id);
}

class GroupSelectionCubit extends Cubit<GroupSelectionState> {
  GroupSelectionCubit() : super(const GroupSelectionState({}));

  void toggle(String groupId) {
    final updated = Set<String>.from(state.selectedIds);
    if (!updated.remove(groupId)) updated.add(groupId);
    emit(GroupSelectionState(updated));
  }

  void clear() => emit(const GroupSelectionState({}));
}
