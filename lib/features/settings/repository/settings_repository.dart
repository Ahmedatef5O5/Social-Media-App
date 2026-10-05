import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }

  Future<void> setPushNotifications(bool value) async {
    pushNotifications = value;
    await _prefs?.setBool(_kPushNotifications, value);
  }

  Future<void> setMessagePreviews(bool value) async {
    messagePreviews = value;
    await _prefs?.setBool(_kMessagePreviews, value);
  }

  Future<void> setCallNotifications(bool value) async {
    callNotifications = value;
    await _prefs?.setBool(_kCallNotifications, value);
  }

  Future<void> setReadReceipts(bool value) async {
    readReceipts = value;
    await _prefs?.setBool(_kReadReceipts, value);
  }

  Future<void> setOnlineStatus(bool value) async {
    onlineStatus = value;
    await _prefs?.setBool(_kOnlineStatus, value);
  }

  Future<void> setBiometricLock(bool value) async {
    biometricLock = value;
    await _prefs?.setBool(_kBiometricLock, value);
  }

  Future<void> setTwoFactor(bool value) async {
    twoFactor = value;
    await _prefs?.setBool(_kTwoFactor, value);
  }

  Future<void> setDefaultStoryPrivacy(ContentPrivacy value) async {
    defaultStoryPrivacy = value;
    await _prefs?.setString(
      _kDefaultStoryPrivacy,
      contentPrivacyToString(value),
    );
  }
}
