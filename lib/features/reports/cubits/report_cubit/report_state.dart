part of 'report_cubit.dart';

sealed class ReportState {
  const ReportState();
}

final class ReportFormState extends ReportState {
  final ReportReason? reason;
  final String note;

  const ReportFormState({this.reason, this.note = ''});

  bool get canSubmit {
    final r = reason;
    if (r == null) return false;
    final trimmed = note.trim();
    if (trimmed.length > ReportCubit.maxNoteLength) return false;
    if (r == ReportReason.other && trimmed.isEmpty) return false;
    return true;
  }

  ReportFormState copyWith({ReportReason? reason, String? note}) =>
      ReportFormState(reason: reason ?? this.reason, note: note ?? this.note);
}

final class ReportSubmitted extends ReportState {
  const ReportSubmitted();
}
