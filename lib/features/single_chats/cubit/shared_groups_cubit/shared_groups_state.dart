import '../../models/shared_group_item.dart';

sealed class SharedGroupsState {
  const SharedGroupsState();
}

final class SharedGroupsInitial extends SharedGroupsState {
  const SharedGroupsInitial();
}

final class SharedGroupsLoading extends SharedGroupsState {
  const SharedGroupsLoading();
}

final class SharedGroupsLoaded extends SharedGroupsState {
  final List<SharedGroupItem> groups;
  const SharedGroupsLoaded(this.groups);
}

final class SharedGroupsError extends SharedGroupsState {
  final String message;
  const SharedGroupsError(this.message);
}
