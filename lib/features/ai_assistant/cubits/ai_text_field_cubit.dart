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
  final void Function(AiQuotaInfo quota, String? provider, String? modelId)?
  onQuotaUpdated;

  static const _debounceDuration = Duration(milliseconds: 900);
  static const _cooldownDuration = Duration(seconds: 5);
  static const _minLengthForSpellCheck = 8;

  bool _hasMediaAttached;
  bool _hasReplyContext;
  bool _autoCompleteEnabled;
  bool _autoDetectEnabled;
  Timer? _debounce;
  Timer? _cooldownTimer;
  bool _inCooldown = false;
  bool _isTargetUsable;
  int _requestGeneration = 0;

  AiTextFieldCubit({
    required AiRepository repository,
    required this.generationAction,
    required this.surface,
    bool hasMediaAttached = false,
    bool hasReplyContext = false,
    bool autoCompleteEnabled = true,
    bool autoDetectEnabled = true,
    bool isTargetUsable = true,
    this.onQuotaUpdated,
  }) : _repository = repository,
       _hasMediaAttached = hasMediaAttached,
       _hasReplyContext = hasReplyContext,
       _autoCompleteEnabled = autoCompleteEnabled,
       _autoDetectEnabled = autoDetectEnabled,
       _isTargetUsable = isTargetUsable,
       super(
         (autoCompleteEnabled && (hasMediaAttached || hasReplyContext))
             ? const AiFieldIdle()
             : const AiFieldHidden(),
       );

  bool get _hasAutoCompleteContext =>
      _autoCompleteEnabled && (_hasMediaAttached || _hasReplyContext);

  AiTextFieldState get _restingState =>
      _hasAutoCompleteContext ? const AiFieldIdle() : const AiFieldHidden();

  void updateExternalContext({
    bool? hasMediaAttached,
    bool? hasReplyContext,
    bool? isTargetUsable,
  }) {
    _hasMediaAttached = hasMediaAttached ?? _hasMediaAttached;
    _hasReplyContext = hasReplyContext ?? _hasReplyContext;
    _isTargetUsable = isTargetUsable ?? _isTargetUsable;

    if (state is AiFieldHidden || state is AiFieldIdle) {
      emit(_restingState);
    }
  }

  void updatePreferences({bool? autoCompleteEnabled, bool? autoDetectEnabled}) {
    final nextAutoComplete = autoCompleteEnabled ?? _autoCompleteEnabled;
    final nextAutoDetect = autoDetectEnabled ?? _autoDetectEnabled;

    if (nextAutoComplete == _autoCompleteEnabled &&
        nextAutoDetect == _autoDetectEnabled) {
      return;
    }

    _autoCompleteEnabled = nextAutoComplete;
    _autoDetectEnabled = nextAutoDetect;

    _debounce?.cancel();
    emit(_restingState);
  }

  void onTextChanged(String text) {
    _debounce?.cancel();
    if (!_isTargetUsable) return;
    if (!_autoDetectEnabled) return;
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
    final myGeneration = ++_requestGeneration;
    emit(const AiFieldChecking());

    final result = await _repository.checkSpelling(
      AiRequestContext(
        surface: surface,
        actionContext: AiActionContext.spellCheck,
        userDraft: text,
      ),
    );

    if (isClosed) return;
    if (myGeneration != _requestGeneration) return;

    if (result.quota != null) {
      onQuotaUpdated?.call(result.quota!, result.provider, result.model);
    }

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
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(_cooldownDuration, () => _inCooldown = false);
  }

  Future<void> onIconTapped(AiRequestContext context) async {
    if (!_isTargetUsable) return;
    final current = state;

    if (current is AiFieldQuotaExceeded) return;
    if (current is AiFieldLoading) return;

    if (current is AiFieldSpellingError) {
      emit(AiFieldResultReady(current.correctedText));
      return;
    }

    if (!_autoCompleteEnabled) return;

    emit(const AiFieldLoading());

    final effectiveAction =
        context.hasMediaAttached
            ? AiActionType.autocompleteCaption
            : generationAction;

    final result =
        effectiveAction == AiActionType.replySuggestion
            ? await _repository.suggestReply(context)
            : await _repository.generateCaption(context);

    if (isClosed) return;

    if (result.quota != null) {
      onQuotaUpdated?.call(result.quota!, result.provider, result.model);
    }

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
    _cooldownTimer?.cancel();
    return super.close();
  }
}
