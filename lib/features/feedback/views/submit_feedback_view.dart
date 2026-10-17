import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
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
        AppToast.warning('Image is too large (max 10 MB).');
        return;
      }
      cubit.setImage(file);
    } catch (_) {
      AppToast.error('Could not open your gallery.');
    }
  }

  String? _validateMessage(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Please tell us what is on your mind.';
    if (t.length < FeedbackCubit.minMessageLength) {
      return 'Please write at least ${FeedbackCubit.minMessageLength} characters.';
    }
    return null;
  }

  String? _validateContact(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
    final isPhone = RegExp(r'^\+?[0-9\s\-()]{7,20}$').hasMatch(t);
    return (isEmail || isPhone) ? null : 'Enter a valid email or phone number.';
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
                  'Feedback Submitted Successfully',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(10),
                const FeedbackStatusChip(
                  status: FeedbackStatus.pending,
                  label: 'Under Review',
                ),
                const Gap(12),
                Text(
                  'Our team typically responds within 24 hours (up to 3 business days).',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Done'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('My Feedbacks'),
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
                  const SettingsDetailSliverAppBar(
                    icon: CupertinoIcons.bubble_left_bubble_right_fill,
                    title: 'Feedback & Support',
                    subtitle: 'Help us improve Social Mate',
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
                                  ? 'Your rating *'
                                  : 'Your rating (optional)',
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
                              hintText: 'Email or phone number',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              validator: _validateContact,
                            ),
                            const Gap(24),
                            SettingsInfoBanner(
                              icon: CupertinoIcons.clock,
                              title: 'Response time',
                              message: 'Response within 24 hours (max 3 days).',
                              tone: SettingsBannerTone.info,
                            ),
                            const Gap(18),
                            SizedBox(
                              width: double.infinity,
                              child: CustomElevatedButton(
                                txtBtn:
                                    locked
                                        ? 'Daily limit reached'
                                        : 'Submit Feedback',
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
                  tooltip: 'My feedbacks',
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
    FeedbackCategory.bug => 'What went wrong? What did you expect to happen?',
    FeedbackCategory.feature => 'Describe the feature you would love to see…',
    FeedbackCategory.inquiry => 'What would you like to know?',
    FeedbackCategory.rating => 'Share your experience with Social Mate…',
    FeedbackCategory.appreciation => 'Tell us what you enjoy!',
    FeedbackCategory.other => 'Write your message here…',
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
      letterSpacing: -0.2,
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

  const _ImageAttachment({
    required this.file,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
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
              const Expanded(
                child: Text(
                  'Attach a screenshot',
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
