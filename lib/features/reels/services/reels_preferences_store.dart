import 'package:hive_flutter/adapters.dart';
import '../../../core/cache/constants/hive_box_names.dart';

class ReelsPreferencesStore {
  ReelsPreferencesStore._();
  static final ReelsPreferencesStore instance = ReelsPreferencesStore._();
  static const String _hasSeenOnboardingKey = 'has_seen_reels_onboarding';
  static const String _selectedCategoriesKey = 'selected_reels_categories';
  static const String _recentlyViewedIdsKey = 'recently_viewed_reel_ids';
  static const int maxStoredSeenIds = 500;

  Box<dynamic>? _box;

  Future<Box<dynamic>> _openBox() async {
    return _box ??= await Hive.openBox<dynamic>(HiveBoxNames.reelsPreferences);
  }

  Future<bool> hasSeenOnboarding() async {
    final box = await _openBox();
    return box.get(_hasSeenOnboardingKey, defaultValue: false) as bool;
  }

  Future<List<String>> getSelectedCategories() async {
    final box = await _openBox();
    final raw = box.get(_selectedCategoriesKey, defaultValue: <String>[]);
    return List<String>.from(raw as List);
  }

  Future<void> savePreferences({required List<String> categories}) async {
    final box = await _openBox();
    await box.put(_hasSeenOnboardingKey, true);
    await box.put(_selectedCategoriesKey, categories);
  }

  Future<void> resetPreferences() async {
    final box = await _openBox();
    await box.put(_hasSeenOnboardingKey, false);
    await box.put(_selectedCategoriesKey, <String>[]);
  }

  Future<List<String>> getRecentlyViewedIds() async {
    final box = await _openBox();
    final raw = box.get(_recentlyViewedIdsKey, defaultValue: <String>[]);
    return List<String>.from(raw as List);
  }

  Future<void> addRecentlyViewedIds(Iterable<String> newlyViewedIds) async {
    final box = await _openBox();
    final existing = List<String>.from(
      box.get(_recentlyViewedIdsKey, defaultValue: <String>[]) as List,
    );

    final merged = <String>{...existing, ...newlyViewedIds}.toList();
    final trimmed =
        merged.length > maxStoredSeenIds
            ? merged.sublist(merged.length - maxStoredSeenIds)
            : merged;

    await box.put(_recentlyViewedIdsKey, trimmed);
  }

  Future<void> clearRecentlyViewedIds() async {
    final box = await _openBox();
    await box.put(_recentlyViewedIdsKey, <String>[]);
  }
}
