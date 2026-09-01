import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../../single_chats/services/chat_block_service.dart';
import '../../models/blocked_user_item_model.dart';
part 'blocked_users_state.dart';

class BlockedUsersCubit extends Cubit<BlockedUsersState> {
  final ChatBlockService _chatBlockService;

  BlockedUsersCubit({ChatBlockService? chatBlockService})
    : _chatBlockService = chatBlockService ?? ChatBlockService(),
      super(BlockedUsersInitial());

  Future<void> fetchBlockedUsers() async {
    emit(BlockedUsersLoading());
    try {
      final rows = await _chatBlockService.getBlockedUsersList();
      final items = rows.map(BlockedUserItemModel.fromMap).toList();
      emit(BlockedUsersLoaded(items));
    } catch (e) {
      emit(
        const BlockedUsersError(
          'Failed to load blocked users. Please try again.',
        ),
      );
    }
  }

  Future<void> unblockUser(String blockedUserId) async {
    final currentState = state;
    if (currentState is! BlockedUsersLoaded) return;

    final previousItems = currentState.items;
    final updatedItems =
        previousItems.where((item) => item.user.id != blockedUserId).toList();
    emit(BlockedUsersLoaded(updatedItems));

    try {
      await _chatBlockService.unblockUser(
        blockerId: SupabaseProvider.id,
        blockedId: blockedUserId,
      );
    } catch (e) {
      emit(BlockedUsersLoaded(previousItems));
    }
  }
}
