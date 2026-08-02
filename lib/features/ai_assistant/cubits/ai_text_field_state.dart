part of 'ai_text_field_cubit.dart';

abstract class AiTextFieldState {
  const AiTextFieldState();
}

class AiFieldHidden extends AiTextFieldState {
  const AiFieldHidden();
}

class AiFieldIdle extends AiTextFieldState {
  const AiFieldIdle();
}

class AiFieldChecking extends AiTextFieldState {
  const AiFieldChecking();
}

class AiFieldSpellingError extends AiTextFieldState {
  final String correctedText;
  const AiFieldSpellingError(this.correctedText);
}

class AiFieldLoading extends AiTextFieldState {
  const AiFieldLoading();
}

class AiFieldResultReady extends AiTextFieldState {
  final String text;
  const AiFieldResultReady(this.text);
}

class AiFieldQuotaExceeded extends AiTextFieldState {
  final bool isGlobal;
  const AiFieldQuotaExceeded({this.isGlobal = false});
}

class AiFieldError extends AiTextFieldState {
  final String reason;
  const AiFieldError(this.reason);
}
