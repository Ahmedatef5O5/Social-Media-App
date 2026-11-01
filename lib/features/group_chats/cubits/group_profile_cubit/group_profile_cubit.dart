import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/supabase_error_mapper.dart';
import '../../../../core/helpers/safe_emit_mixin.dart';
import '../../models/group_model.dart';
import '../../models/group_profile_model.dart';
import '../../services/group_social_service.dart';
part 'group_profile_state.dart';

/// Header data for GroupView and GroupPreviewJoinView, plus the actions that
/// change it (request to join, posting policy, cover). Works for members and
/// non-members: `get_group_profile` returns only preview data to the latter.
class GroupProfileCubit extends Cubit<GroupProfileState>
    with SafeEmitMixin<GroupProfileState> {
  final String groupId;
  final GroupSocialService _service;

  StreamSubscription<GroupJoinRequestStatus>? _requestSub;
  StreamSubscription<int>? _pendingSub;

  GroupProfileCubit({required this.groupId, GroupSocialService? service})
    : _service = service ?? GroupSocialService(),
      super(const GroupProfileInitial());

  GroupProfileModel? get profile {
    final s = state;
    return s is GroupProfileLoaded ? s.profile : null;
  }

  Future<void> load({bool silent = false}) async {
    if (!silent || profile == null) emit(const GroupProfileLoading());
    try {
      final p = await _service.getGroupProfile(groupId);
      if (p == null) {
        emit(const GroupProfileNotFound());
        return;
      }
      emit(GroupProfileLoaded(p));
      _bindRealtime(p);
    } catch (e) {
      debugPrint('[GroupProfileCubit] load failed: $e');
      if (silent && profile != null) return;
      emit(GroupProfileError(SupabaseErrorMapper.toUserMessage(e)));
    }
  }

  void _bindRealtime(GroupProfileModel p) {
    if (!p.isMember && _requestSub == null) {
      // Non-member: react to my request being accepted / rejected.
      _requestSub = _service.watchMyRequestStatus(groupId).listen((status) {
        final current = profile;
        if (current == null || current.isMember) return;
        if (status == GroupJoinRequestStatus.accepted) {
          unawaited(load(silent: true)); // becomes member -> view switches
        } else if (status != current.requestStatus) {
          emit(GroupProfileLoaded(current.copyWith(requestStatus: status)));
        }
      }, onError: (e) => debugPrint('[GroupProfileCubit] request stream: $e'));
    }
    if (p.hasAdminPrivileges && _pendingSub == null) {
      _pendingSub = _service.watchPendingCount(groupId).listen((count) {
        final current = profile;
        if (current == null || current.pendingRequestsCount == count) return;
        emit(GroupProfileLoaded(current.copyWith(pendingRequestsCount: count)));
      }, onError: (e) => debugPrint('[GroupProfileCubit] pending stream: $e'));
    }
  }

  /// Optimistic: flips to "pending" immediately, rolls back on failure.
  /// Returns true on success.
  Future<bool> requestToJoin() async {
    final current = profile;
    if (current == null ||
        current.isMember ||
        current.requestStatus == GroupJoinRequestStatus.pending) {
      return false;
    }
    emit(
      GroupProfileLoaded(
        current.copyWith(requestStatus: GroupJoinRequestStatus.pending),
        isBusy: true,
      ),
    );
    try {
      final status = await _service.requestToJoin(groupId);
      if (status == GroupJoinRequestStatus.accepted) {
        await load(silent: true);
      } else {
        emit(GroupProfileLoaded(profile ?? current));
      }
      return true;
    } catch (e) {
      debugPrint('[GroupProfileCubit] requestToJoin failed: $e');
      emit(GroupProfileLoaded(current));
      rethrow;
    }
  }

  Future<void> setWhoCanPost(GroupWhoCanPost value) async {
    final current = profile;
    if (current == null || !current.hasAdminPrivileges) return;
    emit(GroupProfileLoaded(current.copyWith(whoCanPost: value)));
    try {
      await _service.updateWhoCanPost(groupId, value);
    } catch (e) {
      emit(GroupProfileLoaded(current));
      rethrow;
    }
  }

  Future<void> changeCover(File file) async {
    final current = profile;
    if (current == null || !current.hasAdminPrivileges) return;
    emit(GroupProfileLoaded(current, isBusy: true));
    try {
      final up = await _service.uploadCover(file);
      await _service.updateCover(groupId, up.url, up.publicId);
      emit(GroupProfileLoaded(current.copyWith(coverUrl: up.url)));
    } catch (e) {
      emit(GroupProfileLoaded(current));
      rethrow;
    }
  }

  /// Local patches coming from edit screens (name / avatar / title).
  void applyLocal({String? name, Object? avatarUrl, Object? title}) {
    final current = profile;
    if (current == null) return;
    emit(
      GroupProfileLoaded(
        current.copyWith(
          name: name,
          avatarUrl: avatarUrl ?? current.avatarUrl,
          title: title ?? current.title,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _requestSub?.cancel();
    _pendingSub?.cancel();
    return super.close();
  }
}
