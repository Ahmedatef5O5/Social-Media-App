import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/localization/l10n_extension.dart';
import '../cubits/settings_state.dart';
import '../cubits/setttings_cubit.dart';
import 'settings_surface_card.dart';

/// Opens the language picker. Reads the route-scoped [SettingsCubit] from the
/// caller's context and re-provides it to the sheet (a modal route is not a
/// descendant of `SettingsView`'s `BlocProvider`).
Future<void> showLanguageSelectionSheet(BuildContext context) {
  final cubit = context.read<SettingsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder:
        (_) => BlocProvider<SettingsCubit>.value(
          value: cubit,
          child: const LanguageSelectionSheet(),
        ),
  );
}

class _LanguageOption {
  const _LanguageOption({
    required this.code,
    required this.title,
    required this.subtitle,
  });

  final String code;

  /// Each language is shown in its own script, independent of the active
  /// locale, so a user who landed in the wrong language can still find theirs.
  final String title;
  final String subtitle;
}

const List<_LanguageOption> _options = <_LanguageOption>[
  _LanguageOption(
    code: AppLocale.english,
    title: 'English (US)',
    subtitle: 'English',
  ),
  _LanguageOption(
    code: AppLocale.arabic,
    title: 'العربية (Arabic)',
    subtitle: 'اللغة العربية',
  ),
];

class LanguageSelectionSheet extends StatelessWidget {
  const LanguageSelectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Gap(20),
              Text(
                context.l10n.language,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Gap(6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  context.l10n.languageSheetSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Gap(18),
              Flexible(
                child: BlocBuilder<SettingsCubit, SettingsState>(
                  buildWhen: (p, c) => p.languageCode != c.languageCode,
                  builder: (context, state) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final option in _options) ...[
                            _LanguageOptionTile(
                              option: option,
                              selected:
                                  AppLocale.normalize(state.languageCode) ==
                                  option.code,
                            ),
                            const Gap(10),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({required this.option, required this.selected});

  final _LanguageOption option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    return Semantics(
      button: true,
      selected: selected,
      label: '${option.title}, ${option.subtitle}',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          HapticFeedback.selectionClick();
          final navigator = Navigator.of(context);
          await context.read<SettingsCubit>().setLanguage(option.code);
          if (navigator.mounted) navigator.pop();
        },
        child: SettingsSurfaceCard(
          accent: selected ? primary : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.language_rounded,
                color: selected ? primary : theme.hintColor,
                size: 22,
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      option.subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color:
                    selected
                        ? primary
                        : (isDark ? Colors.white24 : Colors.grey.shade400),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
