import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/supabase_error_mapper.dart';
import '../../../../core/helpers/safe_emit_mixin.dart';
import '../../models/group_join_request_model.dart';
import '../../services/group_social_service.dart';
part 'group_join_requests_state.dart';

/// Owner/admin side: list pending join requests and accept / reject them.
class GroupJoinRequestsCubit extends Cubit<GroupJoinRequestsState>
    with SafeEmitMixin<GroupJoinRequestsState> {
  final String groupId;
  final GroupSocialService _service;

  /// Called after a request was reviewed so the host can refresh counters.
  final VoidCallback? onReviewed;

  GroupJoinRequestsCubit({
    required this.groupId,
    GroupSocialService? service,
    this.onReviewed,
  }) : _service = service ?? GroupSocialService(),
       super(const GroupJoinRequestsInitial());

  Future<void> load() async {
    emit(const GroupJoinRequestsLoading());
    try {
      emit(GroupJoinRequestsLoaded(await _service.getPendingRequests(groupId)));
    } catch (e) {
      debugPrint('[GroupJoinRequestsCubit] load failed: $e');
      emit(GroupJoinRequestsError(SupabaseErrorMapper.toUserMessage(e)));
    }
  }

  /// Returns true when the review succeeded. The row is removed optimistically
  /// and restored on failure.
  Future<bool> review(
    GroupJoinRequestModel request, {
    required bool accept,
  }) async {
    final current = state;
    if (current is! GroupJoinRequestsLoaded ||
        current.busyIds.contains(request.id)) {
      return false;
    }
    emit(
      GroupJoinRequestsLoaded(
        current.requests,
        busyIds: {...current.busyIds, request.id},
      ),
    );
    try {
      await _service.reviewRequest(request.id, accept: accept);
      final latest = state;
      if (latest is GroupJoinRequestsLoaded) {
        emit(
          GroupJoinRequestsLoaded(
            latest.requests.where((r) => r.id != request.id).toList(),
            busyIds: {...latest.busyIds}..remove(request.id),
          ),
        );
      }
      onReviewed?.call();
      return true;
    } catch (e) {
      debugPrint('[GroupJoinRequestsCubit] review failed: $e');
      final latest = state;
      if (latest is GroupJoinRequestsLoaded) {
        emit(
          GroupJoinRequestsLoaded(
            latest.requests,
            busyIds: {...latest.busyIds}..remove(request.id),
          ),
        );
      }
      // Already handled by someone else -> just refresh the list.
      if (e.toString().contains('already_reviewed')) {
        await load();
        return false;
      }
      rethrow;
    }
  }
}
