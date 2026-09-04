import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/features/profile/cubits/profile_cubit/profile_cubit.dart';
import '../../../core/presence/models/presence_privacy.dart';
import '../../../core/presence/widgets/presence_privacy_sheet.dart';
import '../../../core/toast/app_toast.dart';
import '../../home/cubits/home_cubit/home_cubit.dart';
import '../../profile/services/user_services.dart';
import '../../social_graph/views/audience_picker_view.dart';
import '../../support/utils/support_actions.dart';
import '../cubits/settings_state.dart';
import '../cubits/setttings_cubit.dart';
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
            currentUser: context.read<HomeCubit>().currentUserData,
          ),
      child: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (previous, current) => current.errorMessage != null,
        listener: (context, state) {
          AppToast.error(state.errorMessage!);
        },
        builder: (context, settingsState) {
          return _buildScaffold(context, settingsState);
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    HapticFeedback.selectionClick();

    AppToast.info('$feature is coming soon');
  }

  Future<void> _sendFeedback(BuildContext context) async {
    HapticFeedback.selectionClick();
    await SupportActions.sendFeedback(context);
  }

  Widget _buildScaffold(BuildContext context, SettingsState settingsState) {
    final theme = Theme.of(context);

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
                    title: 'Account',
                    icon: Icons.manage_accounts_outlined,
                    delay: 0,
                    items: [
                      SettingsItemData(
                        icon: CupertinoIcons.person_fill,
                        label: 'Edit Profile',
                        subtitle: 'Update your info and photo',
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
                        label: 'Change Password',
                        subtitle: 'Update your account password',
                        onTap:
                            () => _showComingSoon(context, 'Change Password'),
                      ),
                      SettingsItemData(
                        icon: CupertinoIcons.mail_solid,
                        label: 'Email Address',
                        subtitle: 'Manage linked email',
                        onTap: () => _showComingSoon(context, 'Email Address'),
                      ),
                    ],
                  ),
                  const Gap(10),
                  SettingsSection(
                    title: 'Notifications',
                    icon: Icons.notifications_outlined,
                    delay: 1,
                    items: [
                      SettingsItemData(
                        icon: Icons.notifications_active_outlined,
                        label: 'Push Notifications',
                        subtitle: 'Enable all notifications',
                        toggle: settingsState.pushNotifications,
                        onToggle:
                            (v) => context
                                .read<SettingsCubit>()
                                .setPushNotifications(v),
                      ),
                      SettingsItemData(
                        icon: Icons.message_outlined,
                        label: 'Message Previews',
                        subtitle: 'Show content in notifications',
                        toggle: settingsState.messagePreviews,
                        onToggle:
                            (v) => context
                                .read<SettingsCubit>()
                                .setMessagePreviews(v),
                      ),
                      SettingsItemData(
                        icon: Icons.call_outlined,
                        label: 'Call Notifications',
                        subtitle: 'Incoming call alerts',
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
                    title: 'Privacy',
                    icon: CupertinoIcons.shield_fill,
                    delay: 2,
                    items: [
                      SettingsItemData(
                        icon: Icons.done_all_rounded,
                        label: 'Read Receipts',
                        subtitle: 'Show when you\'ve read messages',
                        toggle: settingsState.readReceipts,
                        onToggle:
                            (v) => context
                                .read<SettingsCubit>()
                                .setReadReceipts(v),
                      ),
                      SettingsItemData(
                        icon: Icons.circle_outlined,
                        label: 'Online Status',
                        subtitle: 'Let others see when you\'re active',
                        toggle: settingsState.onlineStatus,
                        onToggle:
                            (v) => context
                                .read<SettingsCubit>()
                                .setOnlineStatus(v),
                      ),

                      SettingsItemData(
                        icon: Icons.visibility_outlined,
                        label: 'Online Status Visibility',
                        subtitle: _presencePrivacyLabel(
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
                        label: 'App Lock',
                        subtitle: 'Require fingerprint / Face ID to open app',
                        toggle: settingsState.biometricLock,
                        onToggle:
                            (v) => context
                                .read<SettingsCubit>()
                                .toggleBiometricLock(v),
                      ),
                      SettingsItemData(
                        icon: CupertinoIcons.lock_shield_fill,
                        label: 'Two-Factor Auth',
                        subtitle: 'Extra layer of security',
                        toggle: settingsState.twoFactor,
                        onToggle: (v) {
                          context.read<SettingsCubit>().setTwoFactor(v);
                          _showComingSoon(context, 'Two-Factor Auth');
                        },
                      ),
                      SettingsItemData(
                        icon: Icons.block_outlined,
                        label: 'Blocked Users',
                        subtitle: 'Manage blocked accounts',
                        onTap:
                            () => Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.blockedUsersViewRoute),
                      ),
                    ],
                  ),
                  const Gap(10),
                  SettingsSection(
                    title: 'Artificial Intelligence',
                    icon: Icons.auto_awesome_rounded,
                    delay: 3,
                    items: [
                      SettingsItemData(
                        icon: Icons.psychology_rounded,

                        label: 'AI Settings',
                        subtitle: 'Personalize your AI-powered experience',
                        onTap:
                            () => Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.aiSettingsViewRoute),
                      ),
                    ],
                  ),
                  const Gap(10),
                  SettingsSection(
                    title: 'Appearance',
                    icon: Icons.palette_outlined,
                    delay: 4,
                    items: [
                      SettingsItemData(
                        icon: Icons.color_lens_outlined,
                        label: 'Theme',
                        subtitle: 'Personalize your app colors',
                        onTap: () => _openThemesSelectView(context),
                      ),
                      SettingsItemData(
                        icon: Icons.language_rounded,
                        label: 'Language',
                        subtitle: 'English (US)',
                        onTap:
                            () =>
                                _showComingSoon(context, 'Language selection'),
                      ),
                    ],
                  ),
                  const Gap(10),
                  SettingsSection(
                    title: 'Support',
                    icon: CupertinoIcons.question_circle_fill,
                    delay: 5,
                    items: [
                      SettingsItemData(
                        icon: Icons.info_outline_rounded,
                        label: 'About Us',
                        subtitle: 'Our story and mission',
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.aboutUsViewRoute,
                            ),
                      ),
                      SettingsItemData(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & FAQ',
                        subtitle: 'Get answers to common questions',
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.helpFaqViewRoute,
                            ),
                      ),
                      SettingsItemData(
                        icon: Icons.feedback_outlined,
                        label: 'Send Feedback',
                        subtitle: 'Tell us what you think',
                        onTap: () => _sendFeedback(context),
                      ),
                      SettingsItemData(
                        icon: Icons.policy_outlined,
                        label: 'Privacy Policy',
                        subtitle: 'How we handle your data',
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.privacyPolicyViewRoute,
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

  String _presencePrivacyLabel(PresencePrivacy p) => switch (p) {
    PresencePrivacy.everyone => 'Everyone',
    PresencePrivacy.friends => 'My Friends',
    PresencePrivacy.specific => 'Specific People',
    PresencePrivacy.nobody => 'Nobody',
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
