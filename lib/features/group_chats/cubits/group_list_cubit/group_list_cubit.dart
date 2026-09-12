import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/cache/constants/snapshot_keys.dart';
import '../../../../core/cache/services/local_snapshot_store.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../../core/utilities/supabase_constants.dart';
import '../../../auth/handlers/auth_exception_handler.dart';
import '../../helpers/group_chat_clear_store.dart';
import '../../models/group_member_model.dart';
import '../../models/group_model.dart';
import '../../models/group_presence_entry.dart';
import '../../services/group_chat_services.dart';
part 'group_list_state.dart';
part 'group_list_base.dart';
part 'group_realtime_sync_mixin.dart';
part 'group_local_mutations_mixin.dart';
part 'group_fetch_persistence_mixin.dart';

class GroupListCubit extends GroupListBase
    with
        WidgetsBindingObserver,
        GroupRealtimeSyncMixin,
        GroupLocalMutationsMixin,
        GroupFetchPersistenceMixin {
  List<GroupModel> get cachedGroupsChats => cached;

  GroupListCubit(super.services) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    channel?.unsubscribe();
    messagesStreamSub?.cancel();
    presenceSub?.cancel();
    activeGroupTimer?.cancel();
    reconcileDebounce?.cancel();
    return super.close();
  }
}
