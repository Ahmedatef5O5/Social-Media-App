import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/shared_groups_service.dart';
import 'shared_groups_state.dart';

class SharedGroupsCubit extends Cubit<SharedGroupsState> {
  final SharedGroupsService _service;
  final String currentUserId;
  final String otherUserId;

  SharedGroupsCubit({
    required SharedGroupsService service,
    required this.currentUserId,
    required this.otherUserId,
  }) : _service = service,
       super(const SharedGroupsInitial());

  Future<void> load() async {
    if (state is! SharedGroupsInitial) return;
    emit(const SharedGroupsLoading());
    try {
      final groups = await _service.getMutualGroups(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );
      if (!isClosed) emit(SharedGroupsLoaded(groups));
    } catch (e) {
      if (!isClosed) emit(SharedGroupsError(e.toString()));
    }
  }
}
