import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/core/errors/network_error_utils.dart';
import 'package:social_media_app/core/helpers/safe_emit_mixin.dart';
import 'package:social_media_app/core/observability/observability.dart';
import 'package:social_media_app/core/toast/app_toast.dart';
import '../../models/report_reason.dart';
import '../../models/report_submit_status.dart';
import '../../models/report_target.dart';
import '../../services/reports_service.dart';
part 'report_state.dart';

class ReportCubit extends Cubit<ReportState> with SafeEmitMixin<ReportState> {
  ReportCubit({required this.target, ReportsService? service})
    : _service = service ?? ReportsService(),
      super(const ReportFormState());

  static const int maxNoteLength = 300;

  final ReportTarget target;
  final ReportsService _service;

  void selectReason(ReportReason reason) {
    final s = state;
    if (s is! ReportFormState) return;
    emit(s.copyWith(reason: reason));
  }

  void updateNote(String value) {
    final s = state;
    if (s is! ReportFormState) return;
    emit(s.copyWith(note: value));
  }

  void submit() {
    final s = state;
    if (s is! ReportFormState || !s.canSubmit) return;

    final reason = s.reason!;
    final note = s.note.trim();

    emit(const ReportSubmitted());
    unawaited(_send(reason, note.isEmpty ? null : note));
  }

  Future<void> _send(ReportReason reason, String? note) async {
    try {
      final status = await _service.submitReport(
        target: target,
        reason: reason,
        note: note,
      );
      _handleStatus(status, reason, note);
    } catch (e, st) {
      unawaited(
        obs.recordError(e, st, feature: 'reports', operation: 'submit_report'),
      );
      final offline =
          NetworkErrorUtils.isNetworkError(e) ||
          e.toString().contains('no-internet');
      _showRetry(
        offline
            ? 'No internet connection. Your report was not sent.'
            : 'Report could not be sent. Please try again.',
        reason,
        note,
      );
    }
  }

  void _handleStatus(
    ReportSubmitStatus status,
    ReportReason reason,
    String? note,
  ) {
    switch (status) {
      case ReportSubmitStatus.created:
      case ReportSubmitStatus.alreadyReported:
        return;
      case ReportSubmitStatus.rateLimited:
        AppToast.warning(
          'Too many reports in a short time. Please try again later.',
        );
      case ReportSubmitStatus.targetNotFound:
        AppToast.info('This content is no longer available.');
      case ReportSubmitStatus.notAllowed:
      case ReportSubmitStatus.notReportable:
      case ReportSubmitStatus.cannotReportSelf:
        AppToast.error('You can\'t report this content.');
      case ReportSubmitStatus.unknown:
        _showRetry('Report could not be sent. Please try again.', reason, note);
    }
  }

  void _showRetry(String message, ReportReason reason, String? note) {
    AppToast.error(
      message,
      actionLabel: 'Retry',
      onAction: () => unawaited(_send(reason, note)),
    );
  }
}
