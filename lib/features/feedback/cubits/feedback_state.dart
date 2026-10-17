import 'dart:io';
import '../models/feedback_models.dart';

class FeedbackState {
  // Draft (submit screen)
  final FeedbackCategory category;
  final int? rating;
  final File? imageFile;
  final File? audioFile;
  final int audioSeconds;

  // Quota
  final FeedbackQuota quota;

  // Submit lifecycle
  final bool isSubmitting;
  final String? submitStage;

  /// One-shot: set when a submission succeeds; the view shows the dialog and
  /// calls `consumeSubmitted()`.
  final UserFeedback? justSubmitted;

  /// One-shot error for toasts; cleared by the next emit.
  final String? errorMessage;

  // History
  final List<UserFeedback> history;
  final bool historyLoading;
  final bool historyFailed;

  const FeedbackState({
    this.category = FeedbackCategory.bug,
    this.rating,
    this.imageFile,
    this.audioFile,
    this.audioSeconds = 0,
    this.quota = const FeedbackQuota.unknown(),
    this.isSubmitting = false,
    this.submitStage,
    this.justSubmitted,
    this.errorMessage,
    this.history = const [],
    this.historyLoading = true,
    this.historyFailed = false,
  });

  bool get ratingRequired => category == FeedbackCategory.rating;

  FeedbackState copyWith({
    FeedbackCategory? category,
    int? rating,
    bool clearRating = false,
    File? imageFile,
    bool clearImage = false,
    File? audioFile,
    bool clearAudio = false,
    int? audioSeconds,
    FeedbackQuota? quota,
    bool? isSubmitting,
    String? submitStage,
    bool clearSubmitStage = false,
    UserFeedback? justSubmitted,
    bool clearJustSubmitted = false,
    String? errorMessage,
    List<UserFeedback>? history,
    bool? historyLoading,
    bool? historyFailed,
  }) {
    return FeedbackState(
      category: category ?? this.category,
      rating: clearRating ? null : (rating ?? this.rating),
      imageFile: clearImage ? null : (imageFile ?? this.imageFile),
      audioFile: clearAudio ? null : (audioFile ?? this.audioFile),
      audioSeconds: clearAudio ? 0 : (audioSeconds ?? this.audioSeconds),
      quota: quota ?? this.quota,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitStage: clearSubmitStage ? null : (submitStage ?? this.submitStage),
      justSubmitted:
          clearJustSubmitted ? null : (justSubmitted ?? this.justSubmitted),
      // errorMessage is one-shot: never carried over.
      errorMessage: errorMessage,
      history: history ?? this.history,
      historyLoading: historyLoading ?? this.historyLoading,
      historyFailed: historyFailed ?? this.historyFailed,
    );
  }
}
