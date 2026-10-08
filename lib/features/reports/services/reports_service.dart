import 'package:social_media_app/core/services/network_status_service.dart';
import 'package:social_media_app/core/supabase/supabase_provider.dart';
import 'package:social_media_app/core/utilities/supabase_constants.dart';
import '../models/report_reason.dart';
import '../models/report_submit_status.dart';
import '../models/report_target.dart';

class ReportsService {
  final NetworkStatusService _networkStatus;

  ReportsService({NetworkStatusService? networkStatus})
    : _networkStatus = networkStatus ?? NetworkStatusService.instance;

  Future<ReportSubmitStatus> submitReport({
    required ReportTarget target,
    required ReportReason reason,
    String? note,
  }) async {
    if (!(await _networkStatus.isConnected())) {
      throw Exception('no-internet');
    }

    final result = await SupabaseProvider.client.rpc(
      SupabaseConstants.submitReportRpc,
      params: {
        'p_target_type': target.type.dbValue,
        'p_target_id': target.id,
        'p_reason_code': reason.dbValue,
        if (note != null && note.isNotEmpty) 'p_note': note,
      },
    );

    return ReportSubmitStatus.fromRpc(result);
  }
}
