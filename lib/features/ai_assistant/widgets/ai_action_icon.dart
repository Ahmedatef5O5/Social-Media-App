import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import '../cubits/ai_preferences_cubit/ai_preferences_cubit.dart';
import '../cubits/ai_text_field_cubit.dart';
import '../data/repositories/ai_repository_impl.dart';
import '../entities/ai_action_type.dart';
import '../entities/ai_active_provider.dart';
import '../entities/ai_request_context.dart';
import '../helpers/ai_image_encoder.dart';
import '../repository/ai_repository.dart';
import 'dart:typed_data';
import 'animated_ai_stars_icon.dart';

class AiActionIcon extends StatefulWidget {
  final TextEditingController controller;
  final AiSurfaceType surface;
  final AiActionType generationAction;
  final AiActionContext actionContext;

  final bool hasMediaAttached;
  final bool hasReplyContext;
  final String? targetText;
  final String? targetUserName;
  final AiTargetMediaType targetMediaType;
  final String? mediaCaption;
  final Future<Uint8List?> Function()? targetImageBytesProvider;
  final Future<Uint8List?> Function()? imageBytesProvider;
  final AiRepository? repository;
  final ValueChanged<bool>? onGeneratingChanged;

  const AiActionIcon({
    super.key,
    required this.controller,
    required this.surface,
    required this.actionContext,
    this.generationAction = AiActionType.autocompleteCaption,
    this.hasMediaAttached = false,
    this.hasReplyContext = false,
    this.targetText,
    this.targetUserName,
    this.targetMediaType = AiTargetMediaType.none,
    this.mediaCaption,
    this.targetImageBytesProvider,
    this.imageBytesProvider,
    this.repository,
    this.onGeneratingChanged,
  });

  @override
  State<AiActionIcon> createState() => _AiActionIconState();
}

class _AiActionIconState extends State<AiActionIcon> {
  late final AiTextFieldCubit _cubit;
  bool get _isMuted =>
      widget.targetMediaType == AiTargetMediaType.video &&
      (widget.mediaCaption == null || widget.mediaCaption!.trim().isEmpty);

  @override
  void initState() {
    super.initState();
    final aiPrefs = context.read<AiPreferencesCubit>().state;
    _cubit = AiTextFieldCubit(
      repository: widget.repository ?? AiRepositoryImpl(),
      generationAction: widget.generationAction,
      surface: widget.surface,
      hasMediaAttached: widget.hasMediaAttached,
      hasReplyContext: widget.hasReplyContext,
      autoCompleteEnabled: aiPrefs.autoCompleteEnabled,
      autoDetectEnabled: aiPrefs.autoDetectEnabled,
      isTargetUsable: !_isMuted,
      onQuotaUpdated: (quota, provider, modelId) {
        if (!mounted) return;
        context.read<AiPreferencesCubit>().recordUsageFromQuota(
          quota,
          provider: provider,
          modelId: modelId,
        );
      },
    );
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => _cubit.onTextChanged(widget.controller.text);

  @override
  void didUpdateWidget(covariant AiActionIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetChanged =
        oldWidget.targetMediaType != widget.targetMediaType ||
        oldWidget.mediaCaption != widget.mediaCaption;

    if (oldWidget.hasMediaAttached != widget.hasMediaAttached ||
        oldWidget.hasReplyContext != widget.hasReplyContext ||
        targetChanged) {
      _cubit.updateExternalContext(
        hasMediaAttached: widget.hasMediaAttached,
        hasReplyContext: widget.hasReplyContext,
        isTargetUsable: targetChanged ? !_isMuted : null,
      );
    }
  }

  Future<AiRequestContext> _buildContext() async {
    String? imageBase64;
    // local user image
    if (widget.hasMediaAttached && widget.imageBytesProvider != null) {
      try {
        final bytes = await widget.imageBytesProvider!();
        if (bytes != null) imageBase64 = AiImageEncoder.encodeForCaption(bytes);
      } catch (e) {
        debugPrint('[AiActionIcon] failed to read local image bytes: $e');
      }
    }

    // remote image
    if (imageBase64 == null &&
        widget.targetMediaType == AiTargetMediaType.image &&
        widget.targetImageBytesProvider != null) {
      try {
        final bytes = await widget.targetImageBytesProvider!();
        if (bytes != null) imageBase64 = AiImageEncoder.encodeForCaption(bytes);
      } catch (e) {
        debugPrint('[AiActionIcon] failed to read target image bytes: $e');
      }
    }

    final aiPrefs = context.read<AiPreferencesCubit>().state;

    return AiRequestContext(
      surface: widget.surface,
      actionContext: widget.actionContext,
      userDraft: widget.controller.text,
      targetUserName: widget.targetUserName,
      targetMediaType: widget.targetMediaType,
      targetText: widget.targetText,
      mediaCaption: widget.mediaCaption,
      hasMediaAttached: widget.hasMediaAttached,
      imageBase64: imageBase64,
      userLanguage: aiPrefs.language,
      userTone: aiPrefs.replyTone,
      userLength: aiPrefs.replyLength,
    );
  }

  void _showQuotaToast(bool isGlobal) {
    AppToast.warning(
      isGlobal
          ? 'You have reached the daily limit for free AI usage. Please try again tomorrow.'
          : 'You have used up your daily quota of AI suggestions. It will reset tomorrow.',
    );
  }

  void _showVisionUnavailableToast() {
    AppToast.warning(
      'The smart reply to images service is currently busy. Please try again later or write your reply manually.',
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<AiPreferencesCubit, AiPreferencesState>(
        listenWhen:
            (previous, current) =>
                previous.autoCompleteEnabled != current.autoCompleteEnabled ||
                previous.autoDetectEnabled != current.autoDetectEnabled,
        listener: (context, prefs) {
          _cubit.updatePreferences(
            autoCompleteEnabled: prefs.autoCompleteEnabled,
            autoDetectEnabled: prefs.autoDetectEnabled,
          );
        },
        child: BlocConsumer<AiTextFieldCubit, AiTextFieldState>(
          listener: (context, state) {
            widget.onGeneratingChanged?.call(
              state is AiFieldChecking || state is AiFieldLoading,
            );
            if (state is AiFieldResultReady) {
              widget.controller.removeListener(_onTextChanged);
              widget.controller.text = state.text;
              widget.controller.selection = TextSelection.collapsed(
                offset: state.text.length,
              );
              widget.controller.addListener(_onTextChanged);
              _cubit.acknowledgeResult();
            } else if (state is AiFieldError) {
              AppToast.error(
                'An error occurred with the AI suggestion. Please try again.',
              );
              _cubit.acknowledgeResult();
            }
          },
          builder: (context, state) {
            if (state is AiFieldHidden) return const SizedBox.shrink();

            if (state is AiFieldChecking || state is AiFieldLoading) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: AnimatedAiStarsIcon(size: 18),
              );
            }

            final isSpellingError = state is AiFieldSpellingError;
            final isQuotaExceeded = state is AiFieldQuotaExceeded;
            final needsVisionNow =
                state is AiFieldIdle &&
                widget.targetMediaType == AiTargetMediaType.image;
            final activeProvider =
                context.watch<AiPreferencesCubit>().state.usage.activeProvider;
            final isVisionUnavailable =
                needsVisionNow && !activeProvider.supportsVision;

            final theme = Theme.of(context);
            final isDisabledLook = isQuotaExceeded || isVisionUnavailable;

            return IconButton(
              tooltip:
                  isSpellingError
                      ? 'Spelling Correction'
                      : (isVisionUnavailable
                          ? 'Smart reply to images is currently unavailable'
                          : 'AI Suggestion'),
              icon: Icon(
                isSpellingError
                    ? Icons.spellcheck_rounded
                    : Icons.auto_awesome_rounded,
                color:
                    isDisabledLook
                        ? theme.disabledColor
                        : (isSpellingError
                            ? Colors.orangeAccent
                            : theme.primaryColor),
              ),
              onPressed: () async {
                if (isQuotaExceeded) {
                  _showQuotaToast((state).isGlobal);
                  return;
                }
                if (isVisionUnavailable) {
                  _showVisionUnavailableToast();
                  return;
                }
                _cubit.onIconTapped(await _buildContext());
              },
            );
          },
        ),
      ),
    );
  }
}
