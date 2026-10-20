import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/auth/cubits/auth_cubit/auth_cubit.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/widgets/custom_confirmation_dialog.dart';
import 'delete_account_verification_sheet.dart';
import '../../../core/localization/l10n_extension.dart';

enum _DangerAction { logout, delete }

class SettingsDangerZone extends StatefulWidget {
  const SettingsDangerZone({super.key});

  @override
  State<SettingsDangerZone> createState() => _SettingsDangerZoneState();
}

class _SettingsDangerZoneState extends State<SettingsDangerZone> {
  _DangerAction? _pendingAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            padding: const EdgeInsetsDirectional.only(
              start: 4,
              bottom: 8,
              top: 6,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Colors.red.shade400,
                ),
                const Gap(6),
                Text(
                  context.l10n.dangerZone.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: context.ls(1.2),
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
            child: BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is AuthSignedOut &&
                    _pendingAction != _DangerAction.delete) {
                  AppToast.error(context.l10n.loggedOutSuccessfully);
                } else if (state is AuthFailure) {
                  AppToast.error(state.errMsg);
                }

                if (state is! AuthLoading && _pendingAction != null) {
                  setState(() => _pendingAction = null);
                }
              },
              buildWhen:
                  (p, c) =>
                      c is AuthSignedOut ||
                      c is AuthFailure ||
                      c is AuthLoading,
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return Column(
                  children: [
                    _buildDangerItem(
                      context,
                      isDark,
                      icon: Icons.logout_rounded,
                      label: context.l10n.logOut,
                      subtitle: context.l10n.logOutSubtitle,
                      color: Colors.orange.shade600,
                      isLoading:
                          isLoading && _pendingAction == _DangerAction.logout,
                      isLast: false,
                      onTap: isLoading ? null : _onLogoutPressed,
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
                      label: context.l10n.deleteAccount,
                      subtitle: context.l10n.deleteAccountSubtitle,
                      color: Colors.red.shade500,
                      isLoading:
                          isLoading && _pendingAction == _DangerAction.delete,
                      isLast: true,
                      onTap: isLoading ? null : _onDeletePressed,
                    ),
                  ],
                );
              },
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
                      letterSpacing: context.ls(-0.2),
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

  void _onLogoutPressed() {
    setState(() => _pendingAction = _DangerAction.logout);
    context.read<AuthCubit>().signOut();
  }

  Future<void> _onDeletePressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => CustomConfirmationDialog(
            title: context.l10n.deleteAccountConfirmation,
            textAlign: TextAlign.center,
            img: AppImages.alertAnimationLot,
            confirmBtnText: context.l10n.deleteAccount,
            cancelBtnText: context.l10n.cancel,
            confirmTxtColor: Colors.red.shade600,
            onConfirm: () {
              Navigator.of(dialogContext, rootNavigator: true).pop(true);
            },
          ),
    );

    if (confirmed != true || !mounted) return;

    final verification = await DeleteAccountVerificationSheet.show(context);
    if (verification == null || !mounted) return;

    setState(() => _pendingAction = _DangerAction.delete);
    context.read<AuthCubit>().deleteAccount(password: verification.password);
  }
}
