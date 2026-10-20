import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/app_locale.dart';
import '../../social_graph/models/content_privacy.dart';

class SettingsRepository {
  SettingsRepository._();
  static final SettingsRepository instance = SettingsRepository._();

  static const String _kPushNotifications = 'settings_push_notifications';
  static const String _kMessagePreviews = 'settings_message_previews';
  static const String _kCallNotifications = 'settings_call_notifications';
  static const String _kReadReceipts = 'settings_read_receipts';
  static const String _kOnlineStatus = 'settings_online_status';
  static const String _kBiometricLock = 'settings_biometric_lock';
  static const String _kTwoFactor = 'settings_two_factor';
  static const String _kDefaultStoryPrivacy = 'settings_default_story_privacy';

  /// Device-level (not account-level) UI language. Deliberately NOT namespaced
  /// by user id and never cleared by `SessionDataCleaner`, so it survives
  /// logout/login and process death.
  static const String _kLanguageCode = 'settings_language_code';

  SharedPreferences? _prefs;
  bool _initialised = false;

  bool pushNotifications = true;
  bool messagePreviews = true;
  bool callNotifications = true;
  bool readReceipts = true;
  bool onlineStatus = true;
  bool biometricLock = false;
  bool twoFactor = false;
  ContentPrivacy defaultStoryPrivacy = ContentPrivacy.public;
  String languageCode = AppLocale.defaultCode;

  Future<void> init() async {
    if (_initialised) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _readFromPrefs(_prefs!);
      _initialised = true;
    } catch (e) {
      debugPrint('[SettingsRepository] init error: $e');
    }
  }

  /// Setters must persist even if [init] has not completed yet (or failed once).
  /// Previously they used a null-aware call on `_prefs`, which silently dropped the write when
  /// `_prefs` was still null.
  Future<SharedPreferences> _ensurePrefs() async {
    final existing = _prefs;
    if (existing != null) return existing;
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    return prefs;
  }

  Future<void> reload() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.reload();
      _prefs = prefs;
      _readFromPrefs(prefs);
      _initialised = true;
    } catch (e) {
      debugPrint('[SettingsRepository] reload error: $e');
    }
  }

  void _readFromPrefs(SharedPreferences prefs) {
    pushNotifications = prefs.getBool(_kPushNotifications) ?? true;
    messagePreviews = prefs.getBool(_kMessagePreviews) ?? true;
    callNotifications = prefs.getBool(_kCallNotifications) ?? true;
    readReceipts = prefs.getBool(_kReadReceipts) ?? true;
    onlineStatus = prefs.getBool(_kOnlineStatus) ?? true;
    biometricLock = prefs.getBool(_kBiometricLock) ?? false;
    twoFactor = prefs.getBool(_kTwoFactor) ?? false;
    defaultStoryPrivacy = contentPrivacyFromString(
      prefs.getString(_kDefaultStoryPrivacy),
    );
    languageCode = AppLocale.normalize(prefs.getString(_kLanguageCode));
  }

  Future<void> setPushNotifications(bool value) async {
    pushNotifications = value;
    await (await _ensurePrefs()).setBool(_kPushNotifications, value);
  }

  Future<void> setMessagePreviews(bool value) async {
    messagePreviews = value;
    await (await _ensurePrefs()).setBool(_kMessagePreviews, value);
  }

  Future<void> setCallNotifications(bool value) async {
    callNotifications = value;
    await (await _ensurePrefs()).setBool(_kCallNotifications, value);
  }

  Future<void> setReadReceipts(bool value) async {
    readReceipts = value;
    await (await _ensurePrefs()).setBool(_kReadReceipts, value);
  }

  Future<void> setOnlineStatus(bool value) async {
    onlineStatus = value;
    await (await _ensurePrefs()).setBool(_kOnlineStatus, value);
  }

  Future<void> setBiometricLock(bool value) async {
    biometricLock = value;
    await (await _ensurePrefs()).setBool(_kBiometricLock, value);
  }

  Future<void> setTwoFactor(bool value) async {
    twoFactor = value;
    await (await _ensurePrefs()).setBool(_kTwoFactor, value);
  }

  Future<void> setDefaultStoryPrivacy(ContentPrivacy value) async {
    defaultStoryPrivacy = value;
    await (await _ensurePrefs()).setString(
      _kDefaultStoryPrivacy,
      contentPrivacyToString(value),
    );
  }

  Future<void> setLanguageCode(String code) async {
    final normalized = AppLocale.normalize(code);
    languageCode = normalized;
    await (await _ensurePrefs()).setString(_kLanguageCode, normalized);
  }
}
