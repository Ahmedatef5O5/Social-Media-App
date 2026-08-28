import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import '../../supabase/supabase_provider.dart';
import '../models/app_theme_model.dart';
part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static String _getPrefKey(String? userId) {
    if (userId == null || userId.isEmpty) return 'app_guest_theme';
    return 'user_theme_$userId';
  }

  ThemeCubit({String? initialTheme})
    : super(
        ThemeState(
          initialTheme != null
              ? AppThemeModel.fromString(initialTheme)
              : AppThemeModel.themes.first,
        ),
      ) {
    _initTheme();
  }

  Future<void> _initTheme() async {
    final currentUserId = SupabaseProvider.user?.id;
    await loaderUserTheme(currentUserId);
  }

  Future<void> loaderUserTheme(String? userId) async {
    final key = _getPrefKey(userId);
    final prefs = await SharedPreferences.getInstance();

    final cachedTheme = prefs.getString(key);
    if (cachedTheme != null) {
      emit(ThemeState(AppThemeModel.fromString(cachedTheme)));
    }

    if (userId != null && userId.isNotEmpty) {
      try {
        final row =
            await SupabaseProvider.client
                .from(SupabaseConstants.users)
                .select(UserColumns.theme)
                .eq(UserColumns.id, userId)
                .maybeSingle();

        final serverTheme = row?[UserColumns.theme] as String?;
        if (serverTheme != null) {
          emit(ThemeState(AppThemeModel.fromString(serverTheme)));
          await prefs.setString(key, serverTheme);
        } else if (cachedTheme == null) {
          emit(ThemeState(AppThemeModel.themes.first));
        }
      } catch (e) {
        debugPrint("Error loading user theme from DB: $e");
      }
    }
  }

  Future<void> changeTheme(AppThemeModel theme, String userId) async {
    emit(ThemeState(theme));
    try {
      final key = _getPrefKey(userId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, theme.toStorageString());

      if (userId.isNotEmpty) {
        await SupabaseProvider.client
            .from(SupabaseConstants.users)
            .update({UserColumns.theme: theme.toStorageString()})
            .eq(UserColumns.id, userId);
      }
    } catch (e) {
      debugPrint("Error saving theme: $e");
    }
  }
}
