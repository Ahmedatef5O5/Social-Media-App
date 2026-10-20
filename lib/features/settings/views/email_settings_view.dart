import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, User;
import '../../../core/router/app_routes.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/utilities/app_formatters.dart';
import '../../../core/utilities/app_validators.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../../core/widgets/custom_text_form_field.dart';
import '../../auth/data/models/account_auth_info.dart';
import '../../auth/services/supabase_auth_services.dart';
import '../cubits/account_security_cubit.dart';
import '../utils/resend_cooldown.dart';
import '../widgets/settings_detail_sliver_app_bar.dart';
import '../widgets/settings_surface_card.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class EmailSettingsView extends StatefulWidget {
  const EmailSettingsView({super.key});

  @override
  State<EmailSettingsView> createState() => _EmailSettingsViewState();
}

class _EmailSettingsViewState extends State<EmailSettingsView>
    with WidgetsBindingObserver {
  late final SupabaseAuthServices _services;
  StreamSubscription<AuthState>? _authSub;
  User? _user;
  bool _refreshing = false;
  bool _profileSynced = false;

  final ResendCooldown _verifyCooldown = ResendCooldown(
    storageKey: 'social_mate_email_verify_resend_expiry',
  );
  final ResendCooldown _changeCooldown = ResendCooldown(
    storageKey: 'social_mate_email_change_resend_expiry',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _services = context.read<SupabaseAuthServices>();
    _user = SupabaseProvider.user;
    _verifyCooldown.restore();
    _changeCooldown.restore();
    _authSub = SupabaseProvider.authChanges.listen(_onAuthEvent);
    _refreshUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _verifyCooldown.dispose();
    _changeCooldown.dispose();
    super.dispose();
  }

  /// The user usually taps the confirmation link in their mail app and comes
  /// back here: refresh so the pending banner resolves on its own.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshUser();
  }

  void _onAuthEvent(AuthState data) {
    final user = data.session?.user;
    if (user == null) return;
    if (data.event == AuthChangeEvent.userUpdated ||
        data.event == AuthChangeEvent.tokenRefreshed) {
      _applyUser(user);
    }
  }

  Future<void> _refreshUser() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final fresh = await _services.fetchFreshUser();
      if (fresh != null) {
        _applyUser(fresh);
        if (!_profileSynced) {
          _profileSynced = true;
          unawaited(_services.syncProfileEmail(fresh.email));
        }
      }
    } catch (e) {
      debugPrint('⚠️ EmailSettingsView refresh failed: $e');
    } finally {
      _refreshing = false;
    }
  }

  void _applyUser(User fresh) {
    if (!mounted) return;
    final before = _user;
    final hadPending = _hasPending(before);
    final emailChanged = before?.email != fresh.email;

    setState(() => _user = fresh);

    if (hadPending && !_hasPending(fresh)) {
      _changeCooldown.clear();
      if (emailChanged) {
        AppToast.success(context.l10n.yourEmailAddressWas);
        unawaited(_services.syncProfileEmail(fresh.email));
      }
    }
    if (before?.emailConfirmedAt == null && fresh.emailConfirmedAt != null) {
      _verifyCooldown.clear();
      AppToast.success(context.l10n.emailVerified);
    }
  }

  bool _hasPending(User? user) => (user?.newEmail ?? '').isNotEmpty;

  // ───────────────────────── cubit results ─────────────────────────

  void _onCubitState(BuildContext context, AccountSecurityState state) {
    if (state is AccountSecuritySuccess) {
      switch (state.action) {
        case AccountAction.changeEmail:
          final user = state.user;
          if (user != null) _applyUser(user);
          _changeCooldown.start();
          AppToast.success(context.l10n.confirmationLinkSent);
        case AccountAction.resendEmailChange:
          _changeCooldown.start();
          AppToast.success(context.l10n.confirmationLinkSentAgain);
        case AccountAction.cancelEmailChange:
          _changeCooldown.clear();
          AppToast.info(context.l10n.emailChangeCancelled);
          _refreshUser();
        case AccountAction.resendVerification:
          _verifyCooldown.start();
          AppToast.success(context.l10n.verificationEmailSent);
        default:
          break;
      }
    } else if (state is AccountSecurityFailure) {
      // The change-email sheet reports its own errors inline.
      if (state.action == AccountAction.changeEmail) return;
      if (state.kind == AccountFailureKind.rateLimited) {
        final secs = state.retryAfterSeconds ?? 60;
        if (state.action == AccountAction.resendVerification) {
          _verifyCooldown.start(secs);
        } else if (state.action == AccountAction.resendEmailChange) {
          _changeCooldown.start(secs);
        }
      }
      AppToast.error(state.message);
    }
  }

  // ───────────────────────── UI actions ─────────────────────────

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(context.l10n.keep),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  confirmLabel,
                  style:
                      destructive ? const TextStyle(color: Colors.red) : null,
                ),
              ),
            ],
          ),
    );
    return result == true;
  }

  Future<void> _cancelPending(String currentEmail, String pendingEmail) async {
    final ok = await _confirm(
      title: context.l10n.cancelEmailChange,
      message: context.l10n.yourEmailStaysThe(currentEmail, pendingEmail),
      confirmLabel: 'Cancel request',
      destructive: true,
    );
    if (ok && mounted) context.read<AccountSecurityCubit>().cancelEmailChange();
  }

  Future<void> _openChangeEmailSheet(String currentEmail) {
    final cubit = context.read<AccountSecurityCubit>();
    final theme = Theme.of(context);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => BlocProvider.value(
            value: cubit,
            child: _ChangeEmailSheet(currentEmail: currentEmail),
          ),
    );
  }

  Future<void> _goSetPassword() async {
    await Navigator.of(context).pushNamed(AppRoutes.changePasswordRoute);
    if (mounted) {
      final current = SupabaseProvider.user;
      if (current != null) setState(() => _user = current);
      _refreshUser();
    }
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocListener<AccountSecurityCubit, AccountSecurityState>(
        listener: _onCubitState,
        listenWhen:
            (prev, curr) =>
                curr is AccountSecuritySuccess ||
                curr is AccountSecurityFailure,
        child: RefreshIndicator(
          onRefresh: _refreshUser,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            slivers: [
              SettingsDetailSliverAppBar(
                icon: CupertinoIcons.mail_solid,
                title: context.l10n.settingsEmailAddress,
                subtitle: context.l10n.manageAndUpdateYour,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  child:
                      user == null
                          ? Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(
                              child: Text(context.l10n.pleaseSignInAgain),
                            ),
                          )
                          : _buildBody(context, user),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, User user) {
    final info = AccountAuthInfo.fromUser(user);
    final currentEmail = user.email ?? '';
    final pending = _hasPending(user) ? user.newEmail! : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusCard(context, user, info),
        if (pending != null) ...[
          const Gap(16),
          _buildPendingCard(context, currentEmail, pending),
        ],
        const Gap(20),
        if (info.hasPassword) ...[
          CustomElevatedButton(
            txtBtn: 'Change Email Address',
            prefixIcon: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => _openChangeEmailSheet(currentEmail),
          ),
          const Gap(12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              context.l10n.forYourSecurityWe,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white38
                        : Colors.grey.shade500,
              ),
            ),
          ),
        ] else ...[
          SettingsInfoBanner(
            icon: Icons.lock_outline_rounded,
            title: context.l10n.setAPasswordFirst,
            message: context.l10n.toChangeYourEmail,
          ),
          const Gap(14),
          CustomElevatedButton(
            txtBtn: 'Set a Password',
            onPressed: _goSetPassword,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    User user,
    AccountAuthInfo info,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    final verified = user.emailConfirmedAt != null;
    final muted = isDark ? Colors.white38 : Colors.grey.shade500;

    return SettingsSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.alternate_email_rounded, color: primary),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.currentEmail,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: context.ls(1.1),
                        color: muted,
                      ),
                    ),
                    const Gap(3),
                    Text(
                      user.email ?? context.l10n.noEmailOnFile,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: context.ls(-0.2),
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(14),
          verified
              ? _StatusChip(
                icon: Icons.verified_rounded,
                label: context.l10n.verified,
                color: isDark ? Colors.green.shade300 : Colors.green.shade700,
              )
              : _StatusChip(
                icon: Icons.warning_amber_rounded,
                label: context.l10n.unverified,
                color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
              ),
          if (!verified) ...[
            const Gap(12),
            Text(
              context.l10n.verifyThisAddressSo,
              style: TextStyle(fontSize: 12.5, height: 1.45, color: muted),
            ),
            const Gap(10),
            _buildResendVerification(),
          ],
          const Gap(14),
          Divider(
            height: 1,
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
          ),
          const Gap(14),
          Row(
            children: [
              Icon(Icons.login_rounded, size: 18, color: muted),
              const Gap(10),
              Text(
                context.l10n.signInMethod,
                style: TextStyle(fontSize: 13, color: muted),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  info.signInMethodLabel,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          if (info.isOAuthLinked) ...[
            const Gap(14),
            SettingsInfoBanner(
              icon: Icons.link_rounded,
              message:
                  info.hasPassword
                      ? context.l10n.isAlsoLinkedTo(
                        info.oauthLabel,
                        info.oauthLabel,
                      )
                      : context.l10n.yourPrimarySignIn(info.oauthLabel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResendVerification() {
    return ValueListenableBuilder<int>(
      valueListenable: _verifyCooldown.remaining,
      builder: (context, secs, _) {
        return BlocBuilder<AccountSecurityCubit, AccountSecurityState>(
          builder: (context, state) {
            final busy = state is AccountSecurityBusy;
            final loading =
                state is AccountSecurityBusy &&
                state.action == AccountAction.resendVerification;
            return OutlinedButton.icon(
              onPressed:
                  (secs > 0 || busy)
                      ? null
                      : () {
                        HapticFeedback.selectionClick();
                        context
                            .read<AccountSecurityCubit>()
                            .resendVerification();
                      },
              icon:
                  loading
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.mark_email_read_outlined, size: 18),
              label: Text(
                secs > 0
                    ? context.l10n.resendInS2(secs)
                    : context.l10n.resendVerification,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingCard(
    BuildContext context,
    String currentEmail,
    String pendingEmail,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? Colors.amber.shade300 : Colors.amber.shade800;

    return SettingsSurfaceCard(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mark_email_unread_rounded, color: accent),
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  context.l10n.confirmYourNewEmail,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            context.l10n.confirmationLinkSentTo(pendingEmail),
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const Gap(8),
          Text(
            context.l10n.cannotFindItCheck,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
          const Gap(14),
          ValueListenableBuilder<int>(
            valueListenable: _changeCooldown.remaining,
            builder: (context, secs, _) {
              return BlocBuilder<AccountSecurityCubit, AccountSecurityState>(
                builder: (context, state) {
                  final busy = state is AccountSecurityBusy;
                  final resending =
                      state is AccountSecurityBusy &&
                      state.action == AccountAction.resendEmailChange;
                  final cancelling =
                      state is AccountSecurityBusy &&
                      state.action == AccountAction.cancelEmailChange;

                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              (secs > 0 || busy)
                                  ? null
                                  : () {
                                    HapticFeedback.selectionClick();
                                    context
                                        .read<AccountSecurityCubit>()
                                        .resendEmailChange(pendingEmail);
                                  },
                          icon:
                              resending
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            secs > 0
                                ? context.l10n.resendInS2(secs)
                                : context.l10n.resendLink,
                          ),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: TextButton.icon(
                          onPressed:
                              busy
                                  ? null
                                  : () => _cancelPending(
                                    currentEmail,
                                    pendingEmail,
                                  ),
                          icon:
                              cancelling
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.close_rounded, size: 18),
                          label: Text(context.l10n.cancelRequest),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Small widgets
// ═════════════════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const Gap(6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Change email bottom sheet
// ═════════════════════════════════════════════════════════════════════════

class _ChangeEmailSheet extends StatefulWidget {
  final String currentEmail;
  const _ChangeEmailSheet({required this.currentEmail});

  @override
  State<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<_ChangeEmailSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  String? _passwordServerError;
  String? _emailServerError;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    _passwordServerError = null;
    _emailServerError = null;
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<AccountSecurityCubit>().changeEmail(
      currentPassword: _passwordCtrl.text,
      newEmail: _emailCtrl.text.trim(),
    );
  }

  void _onState(BuildContext context, AccountSecurityState state) {
    if (state is AccountSecuritySuccess &&
        state.action == AccountAction.changeEmail) {
      Navigator.of(context).pop();
    } else if (state is AccountSecurityFailure &&
        state.action == AccountAction.changeEmail) {
      switch (state.kind) {
        case AccountFailureKind.wrongCurrentPassword:
          HapticFeedback.mediumImpact();
          setState(() => _passwordServerError = state.message);
          _formKey.currentState?.validate();
        case AccountFailureKind.emailTaken:
          setState(() => _emailServerError = state.message);
          _formKey.currentState?.validate();
        default:
          AppToast.error(state.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<AccountSecurityCubit, AccountSecurityState>(
      listenWhen:
          (prev, curr) =>
              curr is AccountSecuritySuccess || curr is AccountSecurityFailure,
      listener: _onState,
      builder: (context, state) {
        final busy = state is AccountSecurityBusy;
        final saving =
            state is AccountSecurityBusy &&
            state.action == AccountAction.changeEmail;

        return PopScope(
          canPop: !busy,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.changeEmailAddress,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: context.ls(-0.4),
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Gap(6),
                    Text(
                      context.l10n.enterYourPasswordAnd,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    const Gap(20),
                    CustomTextFormField(
                      controller: _passwordCtrl,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      labelText: context.l10n.currentPassword,
                      hintText: context.l10n.enterYourPassword,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.passwordIsRequired;
                        }
                        return _passwordServerError;
                      },
                    ),
                    const Gap(16),
                    CustomTextFormField(
                      controller: _emailCtrl,
                      prefixIcon: const Icon(Icons.email_outlined),
                      labelText: context.l10n.newEmailAddress,
                      hintText: context.l10n.enterYourNewEmail,
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: AppFormatters.noSpaces,
                      validator: (value) {
                        final base = AppValidators.validateEmail(value);
                        if (base != null) return base;
                        if (value!.trim().toLowerCase() ==
                            widget.currentEmail.trim().toLowerCase()) {
                          return context.l10n.newEmailMustBe;
                        }
                        return _emailServerError;
                      },
                    ),
                    const Gap(24),
                    CustomElevatedButton(
                      txtBtn: 'Send Confirmation Link',
                      isLoading: saving,
                      onPressed: busy ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
