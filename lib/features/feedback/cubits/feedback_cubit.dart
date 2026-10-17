import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/helpers/safe_emit_mixin.dart';
import 'package:social_media_app/core/services/cloudinary_upload_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feedback_models.dart';
import '../services/feedback_service.dart';
import 'feedback_state.dart';

class FeedbackCubit extends Cubit<FeedbackState>
    with SafeEmitMixin<FeedbackState> {
  FeedbackCubit(this._service) : super(const FeedbackState());

  final FeedbackService _service;
  RealtimeChannel? _channel;
  Timer? _debounce;

  static const int minMessageLength = 5;
  static const int maxMessageLength = 2000;

  Future<void> init() async {
    await Future.wait([refreshQuota(), refreshHistory()]);
    _channel ??= _service.subscribe(onChange: _onRemoteChange);
  }

  void _onRemoteChange() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      refreshHistory(silent: true);
      refreshQuota();
    });
  }

  Future<void> refreshQuota() async {
    try {
      emit(state.copyWith(quota: await _service.fetchQuota()));
    } catch (e) {
      // Keep the previous quota: the database trigger is the real guard.
      debugPrint('[FeedbackCubit] quota fetch failed: $e');
    }
  }

  Future<void> refreshHistory({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(historyLoading: true, historyFailed: false));
    }
    try {
      final items = await _service.fetchMyFeedbacks();
      emit(
        state.copyWith(
          history: items,
          historyLoading: false,
          historyFailed: false,
        ),
      );
    } catch (e) {
      debugPrint('[FeedbackCubit] history fetch failed: $e');
      emit(state.copyWith(historyLoading: false, historyFailed: true));
    }
  }

  void selectCategory(FeedbackCategory c) => emit(state.copyWith(category: c));

  void setRating(int? value) => emit(
    value == null || value == state.rating
        ? state.copyWith(clearRating: true)
        : state.copyWith(rating: value),
  );

  void setImage(File? file) => emit(
    file == null
        ? state.copyWith(clearImage: true)
        : state.copyWith(imageFile: file),
  );

  void setAudio(File? file, int seconds) => emit(
    file == null
        ? state.copyWith(clearAudio: true)
        : state.copyWith(audioFile: file, audioSeconds: seconds),
  );

  void consumeSubmitted() => emit(state.copyWith(clearJustSubmitted: true));

  Future<void> submit({required String message, String? contact}) async {
    if (state.isSubmitting) return;

    final text = message.trim();
    if (text.length < minMessageLength) {
      emit(
        state.copyWith(
          errorMessage:
              'Please describe your feedback (at least $minMessageLength characters).',
        ),
      );
      return;
    }
    if (state.ratingRequired && state.rating == null) {
      emit(state.copyWith(errorMessage: 'Please choose a star rating.'));
      return;
    }
    if (state.quota.isExhausted) {
      emit(
        state.copyWith(
          errorMessage: 'You have reached the limit of 3 feedbacks per day.',
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true, submitStage: 'Submitting…'));

    try {
      CloudinaryUploadResult? image;
      CloudinaryUploadResult? audio;

      final imageFile = state.imageFile;
      if (imageFile != null) {
        emit(
          state.copyWith(
            isSubmitting: true,
            submitStage: 'Uploading screenshot…',
          ),
        );
        image = await _service.uploadAttachment(imageFile, kind: 'image');
      }

      final audioFile = state.audioFile;
      if (audioFile != null) {
        emit(
          state.copyWith(
            isSubmitting: true,
            submitStage: 'Uploading voice note…',
          ),
        );
        audio = await _service.uploadAttachment(audioFile, kind: 'audio');
      }

      emit(state.copyWith(isSubmitting: true, submitStage: 'Sending…'));
      final created = await _service.submit(
        category: state.category,
        message: text,
        rating: state.rating,
        image: image,
        audio: audio,
        audioDurationSeconds: audioFile != null ? state.audioSeconds : null,
        contactMethod: contact,
      );

      emit(
        state.copyWith(
          isSubmitting: false,
          clearSubmitStage: true,
          justSubmitted: created,
          history: [created, ...state.history],
          clearImage: true,
          clearAudio: true,
          clearRating: true,
        ),
      );
      unawaited(refreshQuota());
    } on FeedbackRateLimitException {
      emit(
        state.copyWith(
          isSubmitting: false,
          clearSubmitStage: true,
          errorMessage: 'You have reached the limit of 3 feedbacks per day.',
        ),
      );
      unawaited(refreshQuota());
    } catch (e) {
      debugPrint('[FeedbackCubit] submit failed: $e');
      emit(
        state.copyWith(
          isSubmitting: false,
          clearSubmitStage: true,
          errorMessage: 'Could not send your feedback. Please try again.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await _service.unsubscribe(_channel);
    _channel = null;
    return super.close();
  }
}
