import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_locale.dart';
import '../repository/settings_repository.dart';

/// App-wide active [Locale].
///
/// Lives ABOVE `MaterialApp` and OUTSIDE `SessionScope` on purpose: the
/// language is a device preference, so it must survive logout/login and must
/// not be reset with session-bound cubits. `SettingsCubit` is route-scoped and
/// therefore cannot drive `MaterialApp.locale` itself; it delegates here.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit()
    : super(AppLocale.toLocale(SettingsRepository.instance.languageCode)) {
    _hydrate();
  }

  /// `SettingsRepository.init()` is awaited before `runApp`, so this normally
  /// matches immediately; it only corrects the state if prefs loaded late.
  Future<void> _hydrate() async {
    await SettingsRepository.instance.init();
    if (isClosed) return;
    final stored = AppLocale.toLocale(SettingsRepository.instance.languageCode);
    if (stored != state) emit(stored);
  }

  void apply(String code) {
    if (isClosed) return;
    final next = AppLocale.toLocale(code);
    if (next != state) {
      Intl.defaultLocale = next.languageCode;
      emit(next);
    }
  }
}
