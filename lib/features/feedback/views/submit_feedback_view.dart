import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/core/media_editor/media_editor_service.dart';
import 'package:social_media_app/core/router/app_routes.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import 'package:social_media_app/core/widgets/custom_elevated_button.dart';
import 'package:social_media_app/core/widgets/custom_text_form_field.dart';
import 'package:social_media_app/features/settings/widgets/settings_detail_sliver_app_bar.dart';
import 'package:social_media_app/features/settings/widgets/settings_surface_card.dart';

import '../cubits/feedback_cubit.dart';
import '../cubits/feedback_state.dart';
import '../models/feedback_models.dart';
import '../widgets/feedback_category_selector.dart';
import '../widgets/feedback_quota_badge.dart';
import '../widgets/feedback_star_rating_bar.dart';
import '../widgets/feedback_status_chip.dart';
import '../widgets/feedback_voice_recorder.dart';
import 'package:social_media_app/core/localization/l10n_extension.dart';

class SubmitFeedbackView extends StatefulWidget {
  const SubmitFeedbackView({super.key});

  @override
  State<SubmitFeedbackView> createState() => _SubmitFeedbackViewState();
}

class _SubmitFeedbackViewState extends State<SubmitFeedbackView> {
  static const int _maxImageBytes = 10 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  late final TextEditingController _contactController;

  @override
  void initState() {
    super.initState();
    _contactController = TextEditingController(
      text: SupabaseProvider.user?.email ?? '',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(FeedbackCubit cubit) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;
      final file = File(picked.path);
      if (await file.length() > _maxImageBytes) {
        AppToast.warning(context.l10n.imageIsTooLarge);
        return;
      }
      cubit.setImage(file);
    } catch (_) {
      AppToast.error(context.l10n.couldNotOpenYour);
    }
  }

  /// Optional: draw arrows, highlight the bug, or blur personal info on the
  /// attached screenshot. Cancelling keeps the original image.
  Future<void> _editImage(FeedbackCubit cubit, File file) async {
    final edited = await MediaEditorService.editImage(
      context,
      file,
      preset: MediaEditorPreset.feedback,
    );
    if (edited == null) return;
    if (await edited.length() > _maxImageBytes) {
      AppToast.warning(context.l10n.editedImageIsToo);
      return;
    }
    cubit.setImage(edited);
  }

  String? _validateMessage(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return context.l10n.pleaseTellUsWhat;
    if (t.length < FeedbackCubit.minMessageLength) {
      return context.l10n.pleaseWriteAtLeast(FeedbackCubit.minMessageLength);
    }
    return null;
  }

  String? _validateContact(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
    final isPhone = RegExp(r'^\+?[0-9\s\-()]{7,20}$').hasMatch(t);
    return (isEmail || isPhone) ? null : context.l10n.enterAValidEmail;
  }

  void _submit(FeedbackCubit cubit) {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    cubit.submit(
      message: _messageController.text,
      contact: _contactController.text,
    );
  }

  Future<void> _showSuccessDialog(FeedbackCubit cubit) async {
    final theme = Theme.of(context);
    final goToHistory = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Gap(6),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_alt_circle_fill,
                    color: Color(0xFF27AE60),
                    size: 38,
                  ),
                ),
                const Gap(16),
                Text(
                  context.l10n.feedbackSubmittedSuccessfully,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(10),
                FeedbackStatusChip(
                  status: FeedbackStatus.pending,
                  label: context.l10n.underReview,
                ),
                const Gap(12),
                Text(
                  context.l10n.ourTeamTypicallyResponds,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.l10n.done),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(context.l10n.myFeedbacks),
              ),
            ],
          ),
    );
    if (!mounted) return;
    if (goToHistory == true) _openHistory(cubit);
  }

  void _openHistory(FeedbackCubit cubit) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.feedbackHistoryRoute, arguments: cubit);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cubit = context.read<FeedbackCubit>();
    final topInset = MediaQuery.of(context).padding.top;

    return BlocConsumer<FeedbackCubit, FeedbackState>(
      listenWhen:
          (p, c) =>
              (c.errorMessage != null) ||
              (p.justSubmitted == null && c.justSubmitted != null),
      listener: (context, state) {
        if (state.errorMessage != null) AppToast.error(state.errorMessage!);
        final submitted = state.justSubmitted;
        if (submitted != null) {
          _messageController.clear();
          cubit.consumeSubmitted();
          _showSuccessDialog(cubit);
        }
      },
      builder: (context, state) {
        final busy = state.isSubmitting;
        final locked = state.quota.isExhausted;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SettingsDetailSliverAppBar(
                    icon: CupertinoIcons.bubble_left_bubble_right_fill,
                    title: context.l10n.feedbackSupport,
                    subtitle: context.l10n.helpUsImproveSocial,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FeedbackQuotaBadge(
                              quota: state.quota,
                              onExpired: cubit.refreshQuota,
                            ),
                            const Gap(20),
                            const _SectionLabel('What is this about?'),
                            const Gap(10),
                            FeedbackCategorySelector(
                              selected: state.category,
                              onSelected: busy ? (_) {} : cubit.selectCategory,
                            ),
                            const Gap(22),
                            _SectionLabel(
                              state.ratingRequired
                                  ? context.l10n.yourRating
                                  : context.l10n.yourRatingOptional,
                            ),
                            const Gap(8),
                            FeedbackStarRatingBar(
                              value: state.rating,
                              onChanged: busy ? (_) {} : cubit.setRating,
                            ),
                            const Gap(22),
                            const _SectionLabel('Tell us more'),
                            const Gap(10),
                            CustomTextFormField(
                              controller: _messageController,
                              hintText: _hintFor(state.category),
                              minLines: 4,
                              maxLines: 8,
                              maxLength: FeedbackCubit.maxMessageLength,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              validator: _validateMessage,
                            ),
                            const Gap(18),
                            const _SectionLabel('Attachments'),
                            const Gap(10),
                            _ImageAttachment(
                              file: state.imageFile,
                              enabled: !busy,
                              onPick: () => _pickImage(cubit),
                              onRemove: () => cubit.setImage(null),
                              onEdit:
                                  state.imageFile == null
                                      ? null
                                      : () =>
                                          _editImage(cubit, state.imageFile!),
                            ),
                            const Gap(12),
                            FeedbackVoiceRecorder(
                              file: state.audioFile,
                              seconds: state.audioSeconds,
                              enabled: !busy,
                              onChanged: cubit.setAudio,
                            ),
                            const Gap(22),
                            const _SectionLabel(
                              'How can we reach you? (optional)',
                            ),
                            const Gap(10),
                            CustomTextFormField(
                              controller: _contactController,
                              hintText: context.l10n.emailOrPhoneNumber,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              validator: _validateContact,
                            ),
                            const Gap(24),
                            SettingsInfoBanner(
                              icon: CupertinoIcons.clock,
                              title: context.l10n.responseTime,
                              message: context.l10n.responseWithin24Hours,
                              tone: SettingsBannerTone.info,
                            ),
                            const Gap(18),
                            SizedBox(
                              width: double.infinity,
                              child: CustomElevatedButton(
                                txtBtn:
                                    locked
                                        ? context.l10n.dailyLimitReached
                                        : context.l10n.submitFeedback,
                                isLoading: busy,
                                onPressed:
                                    (busy || locked)
                                        ? null
                                        : () => _submit(cubit),
                              ),
                            ),
                            if (busy && state.submitStage != null) ...[
                              const Gap(10),
                              Center(
                                child: Text(
                                  state.submitStage!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color:
                                        isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // "My Feedbacks" entry point (top-right), above the pinned app bar.
              Positioned(
                top: topInset + 6,
                right: 8,
                child: IconButton(
                  tooltip: context.l10n.myFeedbacks2,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _openHistory(cubit);
                  },
                  icon: Icon(
                    CupertinoIcons.clock,
                    color: isDark ? Colors.white : theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _hintFor(FeedbackCategory c) => switch (c) {
    FeedbackCategory.bug => context.l10n.whatWentWrongWhat,
    FeedbackCategory.feature => context.l10n.describeTheFeatureYou,
    FeedbackCategory.inquiry => context.l10n.whatWouldYouLike,
    FeedbackCategory.rating => context.l10n.shareYourExperienceWith,
    FeedbackCategory.appreciation => context.l10n.tellUsWhatYou,
    FeedbackCategory.other => context.l10n.writeYourMessageHere,
  };
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      letterSpacing: context.ls(-0.2),
      color:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
    ),
  );
}

class _ImageAttachment extends StatelessWidget {
  final File? file;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final VoidCallback? onEdit;

  const _ImageAttachment({
    required this.file,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (file == null) {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onPick : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.photo_on_rectangle,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.attachAScreenshot,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(file!, height: 150, width: 150, fit: BoxFit.cover),
        ),
        if (onEdit != null)
          Positioned(
            top: 6,
            left: 6,
            child: InkWell(
              onTap: enabled ? onEdit : null,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        Positioned(
          top: 6,
          right: 6,
          child: InkWell(
            onTap: enabled ? onRemove : null,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
