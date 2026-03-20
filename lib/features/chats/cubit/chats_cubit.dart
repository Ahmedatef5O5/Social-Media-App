import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/services/supabase_database_services.dart';
import 'package:social_media_app/core/utilities/app_tables_names.dart';
import 'package:social_media_app/features/chats/models/chat_user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'chats_state.dart';

class ChatsCubit extends Cubit<ChatsState> {
  ChatsCubit() : super(ChatsInitial());
  final _dbServices = SupabaseDatabaseServices.instance;
  final _currentUserId = Supabase.instance.client.auth.currentUser!.id;

  Future<void> getChats() async {
    emit(ChatsLoading());
    try {
      final List<ChatUserModel> users = await _dbServices.fetchRows(
        table: AppTablesNames.users,

        builder: (data, id) => ChatUserModel.fromUserData(data),
        filter: (query) => query.neq(UserColumns.id, _currentUserId),
      );
      emit(ChatsSuccessloaded(chats: users));
    } catch (e) {
      debugPrint('Error getting chats: $e');
      emit(ChatsError(e.toString()));
    }
  }
}
