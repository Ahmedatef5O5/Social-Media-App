import 'package:hive_flutter/adapters.dart';
import '../../../core/cache/constants/hive_box_names.dart';
import '../entities/ai_autocomplete_language.dart';
import '../entities/ai_reply_length.dart';
import '../entities/ai_reply_tone.dart';
import '../entities/ai_usage_snapshot.dart';

class AiPreferencesStore {
  AiPreferencesStore._();
  static final AiPreferencesStore instance = AiPreferencesStore._();

  static const String _kAutoComplete = 'ai_auto_complete_enabled';
  static const String _kAutoDetect = 'ai_auto_detect_enabled';
  static const String _kCommentSuggestions = 'ai_comment_suggestions_enabled';
  static const String _kLanguage = 'ai_autocomplete_language';
  static const String _kReplyTone = 'ai_reply_tone';
  static const String _kReplyLength = 'ai_reply_length';
  static const String _kUsageCache = 'ai_usage_cache';

  Box<dynamic>? _box;

  Future<Box<dynamic>> _openBox() async {
    return _box ??= await Hive.openBox<dynamic>(HiveBoxNames.aiPreferences);
  }

  Future<bool> getAutoCompleteEnabled() async {
    final box = await _openBox();
    return box.get(_kAutoComplete, defaultValue: true) as bool;
  }

  Future<bool> getAutoDetectEnabled() async {
    final box = await _openBox();
    return box.get(_kAutoDetect, defaultValue: false) as bool;
  }

  Future<bool> getCommentSuggestionsEnabled() async {
    final box = await _openBox();
    return box.get(_kCommentSuggestions, defaultValue: true) as bool;
  }

  Future<AiAutoCompleteLanguage> getLanguage() async {
    final box = await _openBox();
    return AiAutoCompleteLanguageX.fromStorage(box.get(_kLanguage) as String?);
  }

  Future<AiReplyTone> getReplyTone() async {
    final box = await _openBox();
    return AiReplyToneX.fromStorage(box.get(_kReplyTone) as String?);
  }

  Future<AiReplyLength> getReplyLength() async {
    final box = await _openBox();
    return AiReplyLengthX.fromStorage(box.get(_kReplyLength) as String?);
  }

  Future<AiUsageSnapshot> getCachedUsage() async {
    final box = await _openBox();
    final raw = box.get(_kUsageCache);
    if (raw is! Map) return AiUsageSnapshot.unknown();
    return AiUsageSnapshot.fromJson(raw);
  }

  Future<void> setAutoCompleteEnabled(bool value) async {
    final box = await _openBox();
    await box.put(_kAutoComplete, value);
  }

  Future<void> setAutoDetectEnabled(bool value) async {
    final box = await _openBox();
    await box.put(_kAutoDetect, value);
  }

  Future<void> setCommentSuggestionsEnabled(bool value) async {
    final box = await _openBox();
    await box.put(_kCommentSuggestions, value);
  }

  Future<void> setLanguage(AiAutoCompleteLanguage value) async {
    final box = await _openBox();
    await box.put(_kLanguage, value.storageValue);
  }

  Future<void> setReplyTone(AiReplyTone value) async {
    final box = await _openBox();
    await box.put(_kReplyTone, value.storageValue);
  }

  Future<void> setReplyLength(AiReplyLength value) async {
    final box = await _openBox();
    await box.put(_kReplyLength, value.storageValue);
  }

  Future<void> setCachedUsage(AiUsageSnapshot snapshot) async {
    final box = await _openBox();
    await box.put(_kUsageCache, snapshot.toJson());
  }
}
