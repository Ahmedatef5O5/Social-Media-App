import 'package:flutter/foundation.dart';
import '../../services/network_status_service.dart';

class ConnectivityBannerController {
  ConnectivityBannerController._();

  static final ValueNotifier<int> offlineFlashTrigger = ValueNotifier<int>(0);

  static void notifyBlockedByOffline() {
    offlineFlashTrigger.value++;
  }

  static Future<void> notifyIfOffline() async {
    final isOnline = await NetworkStatusService.instance.isConnected();
    if (!isOnline) notifyBlockedByOffline();
  }
}
