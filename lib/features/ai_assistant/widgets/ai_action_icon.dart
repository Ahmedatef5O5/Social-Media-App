import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import '../cubits/ai_text_field_cubit.dart';
import '../data/repositories/ai_repository_impl.dart';
import '../entities/ai_action_type.dart';
import '../entities/ai_request_context.dart';
import '../helpers/ai_image_encoder.dart';
import '../repository/ai_repository.dart';
import 'dart:typed_data';
import 'animated_ai_stars_icon.dart';

class AiActionIcon extends StatefulWidget {
  final TextEditingController controller;
  final AiSurfaceType surface;

  final AiActionType generationAction;

  final bool hasMediaAttached;
  final bool hasReplyContext;
  final String? replyToText;
  final String? replyToAuthorName;
  final String? parentContentText;

  final Future<Uint8List?> Function()? imageBytesProvider;

  final AiRepository? repository;

  const AiActionIcon({
    super.key,
    required this.controller,
    required this.surface,
    this.generationAction = AiActionType.autocompleteCaption,
    this.hasMediaAttached = false,
    this.hasReplyContext = false,
    this.replyToText,
    this.replyToAuthorName,
    this.parentContentText,
    this.imageBytesProvider,
    this.repository,
  });

  @override
  State<AiActionIcon> createState() => _AiActionIconState();
}

class _AiActionIconState extends State<AiActionIcon> {
  late final AiTextFieldCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AiTextFieldCubit(
      repository: widget.repository ?? AiRepositoryImpl(),
      generationAction: widget.generationAction,
      surface: widget.surface,
      hasMediaAttached: widget.hasMediaAttached,
      hasReplyContext: widget.hasReplyContext,
    );
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => _cubit.onTextChanged(widget.controller.text);

  @override
  void didUpdateWidget(covariant AiActionIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hasMediaAttached != widget.hasMediaAttached ||
        oldWidget.hasReplyContext != widget.hasReplyContext) {
      _cubit.updateExternalContext(
        hasMediaAttached: widget.hasMediaAttached,
        hasReplyContext: widget.hasReplyContext,
      );
    }
  }

  Future<AiRequestContext> _buildContext() async {
    String? imageBase64;

    if (widget.hasMediaAttached && widget.imageBytesProvider != null) {
      try {
        final bytes = await widget.imageBytesProvider!();
        if (bytes != null) {
          imageBase64 = AiImageEncoder.encodeForCaption(bytes);
        }
      } catch (_) {
        // Fall back to a text-only caption rather than failing the tap
        // entirely if reading/encoding the image goes wrong.
      }
    }

    return AiRequestContext(
      surface: widget.surface,
      currentText: widget.controller.text,
      replyToText: widget.replyToText,
      replyToAuthorName: widget.replyToAuthorName,
      parentContentText: widget.parentContentText,
      hasMediaAttached: widget.hasMediaAttached,
      imageBase64: imageBase64,
    );
  }

  void _showQuotaToast(bool isGlobal) {
    AppToast.warning(
      isGlobal
          ? 'وصلنا للحد الأقصى من استخدام الذكاء الاصطناعي المجاني اليوم، حاول تاني بكرة.'
          : 'خلصت حصتك اليومية من اقتراحات الذكاء الاصطناعي، هترجع تاني بكرة.',
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
      child: BlocConsumer<AiTextFieldCubit, AiTextFieldState>(
        listener: (context, state) {
          if (state is AiFieldResultReady) {
            widget.controller.removeListener(_onTextChanged);
            widget.controller.text = state.text;
            widget.controller.selection = TextSelection.collapsed(
              offset: state.text.length,
            );
            widget.controller.addListener(_onTextChanged);
            _cubit.acknowledgeResult();
          } else if (state is AiFieldError) {
            AppToast.error('حصل خطأ في اقتراح الذكاء الاصطناعي، جرب تاني.');
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
          final theme = Theme.of(context);

          return IconButton(
            tooltip:
                isSpellingError ? 'تصحيح إملائي' : 'اقتراح بالذكاء الاصطناعي',
            icon: Icon(
              isSpellingError
                  ? Icons.spellcheck_rounded
                  : Icons.auto_awesome_rounded,
              color:
                  isQuotaExceeded
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
              _cubit.onIconTapped(await _buildContext());
            },
          );
        },
      ),
    );
  }
}
