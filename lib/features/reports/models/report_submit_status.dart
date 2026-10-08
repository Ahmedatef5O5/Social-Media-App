enum ReportSubmitStatus {
  created,
  alreadyReported,
  rateLimited,
  targetNotFound,
  notAllowed,
  notReportable,
  cannotReportSelf,
  unknown;

  static ReportSubmitStatus fromRpc(Object? raw) {
    final status = raw is Map ? raw['status'] : null;
    return switch (status) {
      'created' => ReportSubmitStatus.created,
      'already_reported' => ReportSubmitStatus.alreadyReported,
      'rate_limited' => ReportSubmitStatus.rateLimited,
      'target_not_found' => ReportSubmitStatus.targetNotFound,
      'not_allowed' => ReportSubmitStatus.notAllowed,
      'not_reportable' => ReportSubmitStatus.notReportable,
      'cannot_report_self' => ReportSubmitStatus.cannotReportSelf,
      _ => ReportSubmitStatus.unknown,
    };
  }
}
