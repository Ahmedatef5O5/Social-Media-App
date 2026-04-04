import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_theme_model.dart';
part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final _supabase = Supabase.instance.client;
  static const String _themeKey = 'user_theme';

  ThemeCubit() : super(ThemeState(AppThemeModel.themes.first)) {
    _loadThemeFromPrefs();
  }

  void _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme != null) {
      emit(ThemeState(AppThemeModel.fromString(savedTheme)));
    }
  }

  Future<void> loaderUserTheme(String userId) async {
    try {
      final row =
          await _supabase
              .from(SupabaseConstants.users)
              .select(UserColumns.theme)
              .eq(UserColumns.id, userId)
              .maybeSingle();
      final savedThemeName = row?[UserColumns.theme] as String?;
      if (savedThemeName != null) {
        emit(ThemeState(AppThemeModel.fromString(savedThemeName)));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_themeKey, savedThemeName);
      }
    } catch (e) {
      debugPrint("Error loading theme: $e");
    }
  }

  Future<void> changeTheme(AppThemeModel theme, String userId) async {
    emit(ThemeState(theme));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.toStorageString());
      await _supabase
          .from(SupabaseConstants.users)
          .update({UserColumns.theme: theme.toStorageString()})
          .eq(UserColumns.id, userId);
    } catch (e) {
      debugPrint("Error saving theme: $e");
    }
  }
}
