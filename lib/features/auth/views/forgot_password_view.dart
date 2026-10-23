import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/background_theme_widget.dart';
import '../../../core/toast/app_toast.dart';
import '../../../core/utilities/app_formatters.dart';
import '../../../core/utilities/app_validators.dart';
import '../../../core/widgets/custom_elevated_button.dart';
import '../../../core/widgets/custom_text_form_field.dart';
import '../cubits/auth_cubit/auth_cubit.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewCustomState();
}

class _ForgotPasswordViewCustomState extends State<ForgotPasswordView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _mailInputController = TextEditingController();

  static const String _kLastResetTimestampKey =
      'social_mate_pwd_reset_cooldown_ts';
  static const int _kCooldownPeriodSeconds = 60;

  static const String _kLastResetEmailFpKey =
      'social_mate_pwd_reset_cooldown_email_fp';

  final FocusNode _emailFocusNode = FocusNode();

  Timer? _countdownTicker;
  int _secondsRemaining = 0;

  // The email field is read-only while a link was just sent in this session,
  // with an edit button to cancel the cooldown and change the address.
  bool _isEmailLocked = false;

  // In-memory guard: after "Edit", re-sending to the SAME address inside the
  // cooldown window resumes the remaining time instead of sending again (the
  // server enforces a per-address limit too). A DIFFERENT address is free.
  String? _lastSentEmailFp;
  int? _lastSentAtMs;

  @override
  void initState() {
    super.initState();
    _checkPersistedCooldown();
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    _emailFocusNode.dispose();
    _mailInputController.dispose();
    super.dispose();
  }

  Future<void> _checkPersistedCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSentTimestamp = prefs.getInt(_kLastResetTimestampKey);
    if (lastSentTimestamp == null) return;

    final elapsedSeconds =
        (DateTime.now().millisecondsSinceEpoch - lastSentTimestamp) ~/ 1000;
    if (elapsedSeconds < _kCooldownPeriodSeconds) {
      if (mounted) {
        _beginTimerCountdown(_kCooldownPeriodSeconds - elapsedSeconds);
      }
    }
  }

  void _beginTimerCountdown(int duration) {
    _countdownTicker?.cancel();
    setState(() => _secondsRemaining = duration);

    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (ticker) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        ticker.cancel();
        setState(() {
          _secondsRemaining = 0;
          _isEmailLocked = false;
        });
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String _fingerprint(String email) =>
      sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();

  Future<void> _recordDispatchTimestamp() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastSentEmailFp = _fingerprint(_mailInputController.text);
    _lastSentAtMs = now;
    if (mounted) setState(() => _isEmailLocked = true);
    _beginTimerCountdown(_kCooldownPeriodSeconds);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastResetTimestampKey, now);
    await prefs.setString(_kLastResetEmailFpKey, _lastSentEmailFp!);
  }

  /// Edit button: cancel the countdown, forget the stored cooldown, unlock the
  /// field and re-enable "Send Reset Link".
  Future<void> _editEmail() async {
    _countdownTicker?.cancel();
    if (mounted) {
      setState(() {
        _secondsRemaining = 0;
        _isEmailLocked = false;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastResetTimestampKey);
    await prefs.remove(_kLastResetEmailFpKey);

    if (!mounted) return;
    _emailFocusNode.requestFocus();
    _mailInputController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _mailInputController.text.length,
    );
  }

  void _dispatchResetRequest() {
    if (!_formKey.currentState!.validate()) return;
    if (_secondsRemaining > 0) return;

    final email = _mailInputController.text.trim();

    // Same address as the last send and still inside the window: resume.
    final sentAt = _lastSentAtMs;
    if (sentAt != null && _lastSentEmailFp == _fingerprint(email)) {
      final elapsed = (DateTime.now().millisecondsSinceEpoch - sentAt) ~/ 1000;
      if (elapsed < _kCooldownPeriodSeconds) {
        setState(() => _isEmailLocked = true);
        _beginTimerCountdown(_kCooldownPeriodSeconds - elapsed);
        AppToast.info(context.l10n.aLinkWasJust);
        return;
      }
    }

    FocusManager.instance.primaryFocus?.unfocus();
    context.read<AuthCubit>().resetPassword(email);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: BackgroundThemeWidget(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    const Gap(10),
                    Lottie.asset(
                      AppImages.forgotPasswordAnimation,
                      width: 255,
                      height: 255,
                      fit: BoxFit.contain,
                    ),
                    const Gap(24),
                    Text(
                      context.l10n.forgotPassword,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      context.l10n.enterYourRegisteredEmail,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.grey,
                        height: 1.4,
                      ),
                    ),
                    const Gap(32),
                    CustomTextFormField(
                      controller: _mailInputController,
                      focusNode: _emailFocusNode,
                      readOnly: _isEmailLocked,
                      suffixIcon:
                          _isEmailLocked
                              ? IconButton(
                                tooltip: context.l10n.changeEmail,
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: _editEmail,
                              )
                              : null,
                      prefixIcon: const Icon(Icons.email_outlined),
                      labelText: context.l10n.settingsEmailAddress,
                      hintText: context.l10n.enterYourEmail,
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: AppFormatters.noSpaces,
                      validator: AppValidators.validateEmail,
                    ),
                    const Gap(28),
                    BlocConsumer<AuthCubit, AuthState>(
                      listenWhen:
                          (prev, curr) =>
                              curr is PasswordResetEmailSent ||
                              curr is AuthFailure,
                      listener: (context, state) {
                        if (state is PasswordResetEmailSent) {
                          AppToast.success(context.l10n.ifAnAccountExists);
                          _recordDispatchTimestamp();
                        } else if (state is AuthFailure) {
                          AppToast.error(state.errMsg);
                        }
                      },
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        final isCooldownActive = _secondsRemaining > 0;
                        final buttonLabel =
                            isCooldownActive
                                ? context.l10n.resendInS(_secondsRemaining)
                                : context.l10n.sendResetLink2;

                        return CustomElevatedButton(
                          txtBtn: buttonLabel,
                          isLoading: isLoading,
                          onPressed:
                              (isCooldownActive || isLoading)
                                  ? null
                                  : _dispatchResetRequest,
                        );
                      },
                    ),
                    const Gap(20),
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(
                        context.l10n.returnToLogin,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
