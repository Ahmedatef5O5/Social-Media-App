import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../entities/ai_action_type.dart';
import '../entities/ai_request_context.dart';
import '../entities/ai_result.dart';
import '../repository/ai_repository.dart';
part 'ai_text_field_state.dart';

class AiTextFieldCubit extends Cubit<AiTextFieldState> {
  final AiRepository _repository;
  final AiActionType generationAction;
  final AiSurfaceType surface;

  static const _debounceDuration = Duration(milliseconds: 900);
  static const _cooldownDuration = Duration(seconds: 5);
  static const _minLengthForSpellCheck = 8;

  bool _hasMediaAttached;
  bool _hasReplyContext;
  Timer? _debounce;
  bool _inCooldown = false;

  AiTextFieldCubit({
    required AiRepository repository,
    required this.generationAction,
    required this.surface,
    bool hasMediaAttached = false,
    bool hasReplyContext = false,
  }) : _repository = repository,
       _hasMediaAttached = hasMediaAttached,
       _hasReplyContext = hasReplyContext,
       super(
         (hasMediaAttached || hasReplyContext)
             ? const AiFieldIdle()
             : const AiFieldHidden(),
       );

  bool get _hasAutoCompleteContext => _hasMediaAttached || _hasReplyContext;

  AiTextFieldState get _restingState =>
      _hasAutoCompleteContext ? const AiFieldIdle() : const AiFieldHidden();

  void updateExternalContext({bool? hasMediaAttached, bool? hasReplyContext}) {
    _hasMediaAttached = hasMediaAttached ?? _hasMediaAttached;
    _hasReplyContext = hasReplyContext ?? _hasReplyContext;

    if (state is AiFieldHidden || state is AiFieldIdle) {
      emit(_restingState);
    }
  }

  void onTextChanged(String text) {
    _debounce?.cancel();

    if (state is AiFieldQuotaExceeded) return;

    if (text.trim().isEmpty) {
      emit(_restingState);
      return;
    }

    if (_inCooldown) return;

    if (text.trim().length < _minLengthForSpellCheck) {
      if (state is! AiFieldIdle) emit(const AiFieldIdle());
      return;
    }

    _debounce = Timer(_debounceDuration, () => _runSpellCheck(text));
  }

  Future<void> _runSpellCheck(String text) async {
    emit(const AiFieldChecking());

    final result = await _repository.checkSpelling(
      AiRequestContext(surface: surface, currentText: text),
    );

    if (!result.success) {
      if (result.isQuotaExceeded) {
        emit(
          AiFieldQuotaExceeded(
            isGlobal:
                result.failureReason == AiFailureReason.globalQuotaExceeded,
          ),
        );
        return;
      }
      emit(AiFieldError(result.failureReason ?? 'error'));
      return;
    }

    final corrected = result.text?.trim();
    if (corrected == null || corrected.isEmpty || corrected == 'NONE') {
      _settleWithCooldown(const AiFieldIdle());
    } else {
      _settleWithCooldown(AiFieldSpellingError(corrected));
    }
  }

  void _settleWithCooldown(AiTextFieldState nextState) {
    emit(nextState);
    _inCooldown = true;
    Timer(_cooldownDuration, () => _inCooldown = false);
  }

  Future<void> onIconTapped(AiRequestContext context) async {
    final current = state;

    if (current is AiFieldQuotaExceeded) return;

    if (current is AiFieldSpellingError) {
      emit(AiFieldResultReady(current.correctedText));
      return;
    }

    emit(const AiFieldLoading());

    final result =
        generationAction == AiActionType.replySuggestion
            ? await _repository.suggestReply(context)
            : await _repository.generateCaption(context);

    if (!result.success) {
      if (result.isQuotaExceeded) {
        emit(
          AiFieldQuotaExceeded(
            isGlobal:
                result.failureReason == AiFailureReason.globalQuotaExceeded,
          ),
        );
      } else {
        emit(AiFieldError(result.failureReason ?? 'error'));
      }
      return;
    }

    emit(AiFieldResultReady(result.text?.trim() ?? ''));
  }

  void acknowledgeResult() => emit(_restingState);

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
