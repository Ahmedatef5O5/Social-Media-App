import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/profile/cubits/profile_cubit/profile_cubit.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/presence/models/presence_privacy.dart';
import '../../../core/presence/widgets/presence_privacy_sheet.dart';
import '../../../core/toast/app_toast.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../../profile/services/user_services.dart';
import '../../social_graph/views/audience_picker_view.dart';
import '../../two_factor/widgets/two_factor_disable_sheet.dart';
import '../cubits/locale_cubit.dart';
import '../cubits/settings_state.dart';
import '../cubits/setttings_cubit.dart';
import '../utils/settings_error_l10n.dart';
import '../widgets/language_selection_sheet.dart';
import '../widgets/settings_danger_zone.dart';
import '../widgets/settings_item_data.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_sliver_app_bar.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => SettingsCubit(
            userService: context.read<UserService>(),
            homeCubit: context.read<HomeCubit>(),
            localeCubit: context.read<LocaleCubit>(),
            currentUser: context.read<HomeCubit>().currentUserData,
          ),
      child: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (previous, current) => current.error != null,
        listener: (context, state) {
          AppToast.error(context.l10n.settingsErrorMessage(state.error!));
        },
        builder: (context, settingsState) {
          return _buildScaffold(context, settingsState);
        },
      ),
    );
  }

  void _sendFeedback(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pushNamed(AppRoutes.feedbackRoute);
  }

  Widget _buildScaffold(BuildContext context, SettingsState settingsState) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          const SettingsSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsSection(
                    title: l10n.settingsSectionAccount,
                    icon: Icons.manage_accounts_outlined,
                    delay: 0,
                    items: [
                      SettingsItemData(
                        icon: CupertinoIcons.person_fill,
                        label: l10n.settingsEditProfile,
                        subtitle: l10n.settingsEditProfileSubtitle,
                        onTap: () async {
                          final profileCubit = context.read<ProfileCubit>();
                          final profileState = profileCubit.state;
                          if (profileState is ProfileLoaded) {
                            await Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushNamed(
                              AppRoutes.editProfileViewRoute,
                              arguments: profileState.user,
                            );
                            if (context.mounted) {
                              profileCubit.getProfileData(profileState.user.id);
                            }
                          }
                        },
                      ),
                      SettingsItemData(
                        icon: CupertinoIcons.lock_fill,
                        label: l10n.settingsChangePassword,
                        subtitle: l10n.settingsChangePasswordSubtitle,
                        onTap:
                            () => Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.changePasswordRoute),
                      ),
                      SettingsItemData(
                        icon: CupertinoIcons.mail_solid,
                        label: l10n.settingsEmailAddress,
                        subtitle: l10n.settingsEmailAddressSubtitle,
                        onTap:
                            () => Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.emailSettingsRoute),
                      ),
                    ],
                  ),
                  const Gap(10),
                  SettingsSection(
                    title: l10n.settingsSectionNotifications,
                    icon: Icons.notifications_outlined,
                    delay: 1,
                    items: [
                      SettingsItemData(
                        icon: Icons.notifications_active_outlined,
                        label: l10n.settingsPushNotifications,
                        subtitle: l10n.settingsPushNotificationsSubtitle,
                        toggle: settingsState.pushNotifications,
                        onToggle:
                            (v) => context
                                .read<SettingsCubit>()
                                .setPushNotifications(v),
                      ),
                      SettingsItemData(
                        icon: Icons.message_outlined,
                        label: l10n.settingsMessagePreviews,
                        subtitle: l10n.settingsMessagePreviewsSubtitle,
                        toggle: settingsState.messagePreviews,
                        onToggle:
                            (v) => context
                                .read<SettingsCubit>()
                                .setMessagePreviews(v),
                      ),
                      SettingsItemData(
                        icon: Icons.call_outlined,
                        label: l10n.settingsCallNotifications,
                        subtitle: l10n.settingsCallNotificationsSubtitle,
                        toggle: settingsState.callNotifications,
                        onToggle:
                            (v) => context
                                .read<SettingsCubit>()
                                .setCallNotifications(v),
                      ),
                    ],
                  ),
                  const Gap(10),
                  SettingsSection(
                    title: l10n.settingsSectionPrivacy,
                    icon: CupertinoIcons.shield_fill,
                    delay: 2,
                    items: [
                      SettingsItemData(
                        icon: Icons.done_all_rounded,
                        label: l10n.settingsReadReceipts,
                        subtitle: l10n.settingsReadReceiptsSubtitle,
                        toggle: settingsState.readReceipts,
                        onToggle:
                            (v) => context
                                .read<SettingsCubit>()
                                .setReadReceipts(v),
                      ),
                      SettingsItemData(
                        icon: Icons.circle_outlined,
                        label: l10n.settingsOnlineStatus,
                        subtitle: l10n.settingsOnlineStatusSubtitle,
                        toggle: settingsState.onlineStatus,
                        onToggle:
                            (v) => context
                                .read<SettingsCubit>()
                                .setOnlineStatus(v),
                      ),

                      SettingsItemData(
                        icon: Icons.visibility_outlined,
                        label: l10n.settingsOnlineStatusVisibility,
                        subtitle: _presencePrivacyLabel(
                          l10n,
                          settingsState.presencePrivacy,
                        ),
                        enabled: settingsState.onlineStatus,
                        onTap:
                            () => _pickPresencePrivacy(
                              context,
                              settingsState.presencePrivacy,
                            ),
                      ),

                      SettingsItemData(
                        icon: Icons.fingerprint_rounded,
                        label: l10n.settingsAppLock,
                        subtitle: l10n.settingsAppLockSubtitle,
                        toggle: settingsState.biometricLock,
                        onToggle:
                            (v) => context
                                .read<SettingsCubit>()
                                .toggleBiometricLock(v),
                      ),
                      SettingsItemData(
                        icon: CupertinoIcons.lock_shield_fill,
                        label: l10n.settingsTwoFactor,
                        subtitle:
                            settingsState.twoFactor
                                ? (settingsState.recoveryCodesCount != null
                                    ? l10n.settingsTwoFactorOnRecoveryCodes(
                                      settingsState.recoveryCodesCount!,
                                    )
                                    : l10n.settingsTwoFactorOnAuthenticator)
                                : l10n.settingsTwoFactorOffSubtitle,
                        toggle: settingsState.twoFactor,
                        onToggle: (v) async {
                          if (v) {
                            final success = await Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.twoFactorSetupRoute);
                            if (success == true && context.mounted) {
                              context
                                  .read<SettingsCubit>()
                                  .refreshTwoFactorStatus();
                            }
                          } else {
                            final disabled = await showTwoFactorDisableSheet(
                              context,
                            );
                            if (disabled == true && context.mounted) {
                              context
                                  .read<SettingsCubit>()
                                  .refreshTwoFactorStatus();
                            }
                          }
                        },
                      ),
                      SettingsItemData(
                        icon: Icons.block_outlined,
                        label: l10n.settingsBlockedUsers,
                        subtitle: l10n.settingsBlockedUsersSubtitle,
                        onTap:
                            () => Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.blockedUsersViewRoute),
                      ),
                    ],
                  ),
                  const Gap(10),
                  SettingsSection(
                    title: l10n.settingsSectionAi,
                    icon: Icons.auto_awesome_rounded,
                    delay: 3,
                    items: [
                      SettingsItemData(
                        icon: Icons.psychology_rounded,

                        label: l10n.settingsAiSettings,
                        subtitle: l10n.settingsAiSettingsSubtitle,
                        onTap:
                            () => Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.aiSettingsViewRoute),
                      ),
                    ],
                  ),
                  const Gap(10),
                  SettingsSection(
                    title: l10n.settingsSectionAppearance,
                    icon: Icons.palette_outlined,
                    delay: 4,
                    items: [
                      SettingsItemData(
                        icon: Icons.color_lens_outlined,
                        label: l10n.settingsTheme,
                        subtitle: l10n.settingsThemeSubtitle,
                        onTap: () => _openThemesSelectView(context),
                      ),
                      SettingsItemData(
                        icon: Icons.language_rounded,
                        label: l10n.language,
                        subtitle:
                            AppLocale.isArabic(settingsState.languageCode)
                                ? 'العربية'
                                : 'English (US)',
                        onTap: () => showLanguageSelectionSheet(context),
                      ),
                    ],
                  ),
                  const Gap(10),
                  SettingsSection(
                    title: l10n.settingsSectionSupport,
                    icon: CupertinoIcons.question_circle_fill,
                    delay: 5,
                    items: [
                      SettingsItemData(
                        icon: Icons.info_outline_rounded,
                        label: l10n.settingsAboutUs,
                        subtitle: l10n.settingsAboutUsSubtitle,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.aboutUsViewRoute,
                            ),
                      ),
                      SettingsItemData(
                        icon: Icons.help_outline_rounded,
                        label: l10n.settingsHelpFaq,
                        subtitle: l10n.settingsHelpFaqSubtitle,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.helpFaqViewRoute,
                            ),
                      ),
                      SettingsItemData(
                        icon: Icons.feedback_outlined,
                        label: l10n.settingsSendFeedback,
                        subtitle: l10n.settingsSendFeedbackSubtitle,
                        onTap: () => _sendFeedback(context),
                      ),
                      SettingsItemData(
                        icon: Icons.policy_outlined,
                        label: l10n.settingsPrivacyPolicy,
                        subtitle: l10n.settingsPrivacyPolicySubtitle,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.privacyPolicyViewRoute,
                            ),
                      ),
                      SettingsItemData(
                        icon: Icons.gavel_rounded,
                        label: l10n.settingsTermsOfService,
                        subtitle: l10n.settingsTermsOfServiceSubtitle,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.termsOfServiceRoute,
                            ),
                      ),
                    ],
                  ),
                  const Gap(10),
                  const SettingsDangerZone(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openThemesSelectView(BuildContext context) {
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is! ProfileLoaded) return;

    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.themesSelectViewRoute,
      arguments: profileState.user.id,
    );
  }

  String _presencePrivacyLabel(AppLocalizations l10n, PresencePrivacy p) =>
      switch (p) {
        PresencePrivacy.everyone => l10n.presenceEveryone,
        PresencePrivacy.friends => l10n.presenceFriends,
        PresencePrivacy.specific => l10n.presenceSpecific,
        PresencePrivacy.nobody => l10n.presenceNobody,
      };

  Future<void> _pickPresencePrivacy(
    BuildContext context,
    PresencePrivacy current,
  ) async {
    final result = await PresencePrivacySheet.show(context, current);
    if (result == null || !context.mounted) return;

    final cubit = context.read<SettingsCubit>();
    await cubit.setPresencePrivacy(result);

    if (result == PresencePrivacy.specific && context.mounted) {
      final selected = await Navigator.of(context).push<Set<String>>(
        MaterialPageRoute(
          builder:
              (_) => AudiencePickerView(
                initialSelectedIds: cubit.state.presenceVisibleTo.toSet(),
              ),
        ),
      );
      if (selected != null) {
        await cubit.setPresenceVisibleTo(selected.toList());
      }
    }
  }
}
