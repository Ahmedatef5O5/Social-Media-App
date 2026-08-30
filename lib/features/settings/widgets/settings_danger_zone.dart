import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:social_media_app/features/auth/cubits/auth_cubit/auth_cubit.dart';
import '../../../core/toast/app_toast.dart';

class SettingsDangerZone extends StatelessWidget {
  const SettingsDangerZone({super.key});

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
                      AppToast.error('Logged out successfully');
                    } else if (state is AuthFailure) {
                      AppToast.error(state.errMsg);
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
              'Feature Under Construction',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: const Text(
              "Account deletion isn't available yet. Please contact support if you need your account removed.",
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }
}
