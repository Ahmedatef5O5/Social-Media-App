import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/themes/cubit/theme_cubit.dart';
import 'package:social_media_app/features/auth/cubit/auth_cubit/auth_cubit.dart';
import 'package:social_media_app/features/profile/cubits/profile_cubit/profile_cubit.dart';
import 'package:social_media_app/features/settings/widgets/theme_picker_sheet_widget.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  bool _notificationsEnabled = true;
  bool _messagePreviews = true;
  bool _callNotifications = true;
  bool _readReceipts = true;
  bool _onlineStatus = true;
  bool _twoFactor = false;

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, isDark, primary, size),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    context,
                    isDark,
                    primary,
                    title: 'Account',
                    icon: Icons.manage_accounts_outlined,
                    delay: 0,
                    items: [
                      _SettingsItemData(
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
                      _SettingsItemData(
                        icon: CupertinoIcons.lock_fill,
                        label: 'Change Password',
                        subtitle: 'Update your account password',
                        onTap: () {},
                      ),
                      _SettingsItemData(
                        icon: CupertinoIcons.mail_solid,
                        label: 'Email Address',
                        subtitle: 'Manage linked email',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const Gap(10),
                  _buildSection(
                    context,
                    isDark,
                    primary,
                    title: 'Notifications',
                    icon: Icons.notifications_outlined,
                    delay: 1,
                    items: [
                      _SettingsItemData(
                        icon: Icons.notifications_active_outlined,
                        label: 'Push Notifications',
                        subtitle: 'Enable all notifications',
                        toggle: _notificationsEnabled,
                        onToggle:
                            (v) => setState(() => _notificationsEnabled = v),
                      ),
                      _SettingsItemData(
                        icon: Icons.message_outlined,
                        label: 'Message Previews',
                        subtitle: 'Show content in notifications',
                        toggle: _messagePreviews,
                        onToggle: (v) => setState(() => _messagePreviews = v),
                      ),
                      _SettingsItemData(
                        icon: Icons.call_outlined,
                        label: 'Call Notifications',
                        subtitle: 'Incoming call alerts',
                        toggle: _callNotifications,
                        onToggle: (v) => setState(() => _callNotifications = v),
                      ),
                    ],
                  ),
                  const Gap(10),
                  _buildSection(
                    context,
                    isDark,
                    primary,
                    title: 'Privacy',
                    icon: CupertinoIcons.shield_fill,
                    delay: 2,
                    items: [
                      _SettingsItemData(
                        icon: Icons.done_all_rounded,
                        label: 'Read Receipts',
                        subtitle: 'Show when you\'ve read messages',
                        toggle: _readReceipts,
                        onToggle: (v) => setState(() => _readReceipts = v),
                      ),
                      _SettingsItemData(
                        icon: Icons.circle_outlined,
                        label: 'Online Status',
                        subtitle: 'Let others see when you\'re active',
                        toggle: _onlineStatus,
                        onToggle: (v) => setState(() => _onlineStatus = v),
                      ),
                      _SettingsItemData(
                        icon: CupertinoIcons.lock_shield_fill,
                        label: 'Two-Factor Auth',
                        subtitle: 'Extra layer of security',
                        toggle: _twoFactor,
                        onToggle: (v) => setState(() => _twoFactor = v),
                      ),
                      _SettingsItemData(
                        icon: Icons.block_outlined,
                        label: 'Blocked Users',
                        subtitle: 'Manage blocked accounts',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const Gap(10),
                  _buildSection(
                    context,
                    isDark,
                    primary,
                    title: 'Appearance',
                    icon: Icons.palette_outlined,
                    delay: 3,
                    items: [
                      _SettingsItemData(
                        icon: Icons.color_lens_outlined,
                        label: 'Theme',
                        subtitle: 'Personalize your app colors',
                        onTap: () => _showThemeSheet(context),
                      ),
                      _SettingsItemData(
                        icon: Icons.language_rounded,
                        label: 'Language',
                        subtitle: 'English (US)',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const Gap(10),
                  _buildSection(
                    context,
                    isDark,
                    primary,
                    title: 'Support',
                    icon: CupertinoIcons.question_circle_fill,
                    delay: 4,
                    items: [
                      _SettingsItemData(
                        icon: Icons.info_outline_rounded,
                        label: 'About Us',
                        subtitle: 'Our story and mission',
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.aboutUsViewRoute,
                            ),
                      ),
                      _SettingsItemData(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & FAQ',
                        subtitle: 'Get answers to common questions',
                        onTap: () {},
                      ),
                      _SettingsItemData(
                        icon: Icons.feedback_outlined,
                        label: 'Send Feedback',
                        subtitle: 'Tell us what you think',
                        onTap: () {},
                      ),
                      _SettingsItemData(
                        icon: Icons.policy_outlined,
                        label: 'Privacy Policy',
                        subtitle: 'How we handle your data',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const Gap(10),
                  _buildDangerZone(context, isDark, primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    bool isDark,
    Color primary,
    Size size,
  ) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double minHeight = statusBarHeight + 60.0;

    return SliverAppBar(
      expandedHeight: 120,
      collapsedHeight: 60,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,

      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: primary),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final top = constraints.maxHeight;
          double titleOpacity = (minHeight + 20 - top) / 20.0;
          titleOpacity = titleOpacity.clamp(0.0, 1.0);

          double bgOpacity = (top - (minHeight + 10)) / 30.0;
          bgOpacity = bgOpacity.clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            titlePadding: const EdgeInsets.only(left: 52, bottom: 20),

            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),

              opacity: titleOpacity,
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            background: Padding(
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      color: primary,
                      size: 22,
                    ),
                  ),
                  const Gap(14),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Manage your preferences',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    bool isDark,
    Color primary, {
    required String title,
    required IconData icon,
    required List<_SettingsItemData> items,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay * 80),
      curve: Curves.easeOut,
      builder:
          (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - value)),
              child: child,
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 6),
            child: Row(
              children: [
                Icon(icon, size: 14, color: primary),
                const Gap(6),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.06),
                width: 0.8,
              ),
            ),
            child: Column(
              children:
                  items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isLast = idx == items.length - 1;
                    return _buildSettingsItem(
                      context,
                      item,
                      isDark,
                      primary,
                      isLast,
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    _SettingsItemData item,
    bool isDark,
    Color primary,
    bool isLast,
  ) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap:
              item.toggle == null
                  ? () {
                    HapticFeedback.selectionClick();
                    item.onTap?.call();
                  }
                  : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(item.icon, color: primary, size: 18),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (item.subtitle != null) ...[
                        const Gap(2),
                        Text(
                          item.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark ? Colors.white38 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.toggle != null)
                  Transform.scale(
                    scale: 0.85,
                    child: CupertinoSwitch(
                      value: item.toggle!,
                      activeTrackColor: primary,
                      onChanged: (v) {
                        HapticFeedback.lightImpact();
                        item.onToggle?.call(v);
                      },
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 68,
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
          ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context, bool isDark, Color primary) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder:
          (ctx, val, child) => Opacity(
            opacity: val,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - val)),
              child: child,
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 6),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Colors.red.shade400,
                ),
                const Gap(6),
                Text(
                  'DANGER ZONE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.red.withValues(alpha: 0.05)
                      : Colors.red.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    isDark
                        ? Colors.red.withValues(alpha: 0.12)
                        : Colors.red.shade100,
                width: 0.8,
              ),
            ),
            child: Column(
              children: [
                BlocConsumer<AuthCubit, AuthState>(
                  listener: (context, state) {
                    if (state is AuthSignedOut) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Logged out successfully',
                            style: Theme.of(context).textTheme.titleSmall!
                                .copyWith(color: Colors.white),
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamedAndRemoveUntil(
                        AppRoutes.authRoute,
                        (route) => false,
                      );
                    } else if (state is AuthFailure) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(state.errMsg)));
                    }
                  },
                  buildWhen:
                      (p, c) =>
                          c is AuthSignedOut ||
                          c is AuthFailure ||
                          c is AuthLoading,
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return _buildDangerItem(
                      context,
                      isDark,
                      icon: Icons.logout_rounded,
                      label: 'Log Out',
                      subtitle: 'Sign out of your account',
                      color: Colors.orange.shade600,
                      isLoading: isLoading,
                      isLast: false,
                      onTap:
                          isLoading
                              ? null
                              : () => context.read<AuthCubit>().signOut(),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  indent: 68,
                  color:
                      isDark
                          ? Colors.red.withValues(alpha: 0.10)
                          : Colors.red.shade100,
                ),
                _buildDangerItem(
                  context,
                  isDark,
                  icon: Icons.delete_forever_rounded,
                  label: 'Delete Account',
                  subtitle: 'Permanently remove your account',
                  color: Colors.red.shade500,
                  isLast: true,
                  onTap: () => _showDeleteConfirmation(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerItem(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    bool isLast = false,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap:
          onTap == null
              ? null
              : () {
                HapticFeedback.mediumImpact();
                onTap();
              },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child:
                  isLoading
                      ? Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        ),
                      )
                      : Icon(icon, color: color, size: 18),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: color,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: color.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Delete Account',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: const Text(
              'This will permanently delete your account and all your data. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  // TODO: implement delete account
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showThemeSheet(BuildContext context) {
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is! ProfileLoaded) return;
    final userId = profileState.user.id;
    final themeCubit = context.read<ThemeCubit>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => BlocProvider.value(
            value: themeCubit,
            child: DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.3,
              maxChildSize: 0.95,
              expand: false,
              snap: true,
              builder: (context, scrollController) {
                return ThemePickerSheetWidget(
                  userId: userId,
                  scrollController: scrollController,
                );
              },
            ),
          ),
    );
  }
}

class _SettingsItemData {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool? toggle;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;

  const _SettingsItemData({
    required this.icon,
    required this.label,
    this.subtitle,
    this.toggle,
    this.onTap,
    this.onToggle,
  });
}
