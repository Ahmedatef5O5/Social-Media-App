import '../models/update_info.dart';

/// State machine of the OTA update flow:
///
///   Initial ─► Checking ─► Available ─► Downloading ─► ReadyToInstall
///                 │                                         │ (app restart)
///                 ├──────────────► ConfirmedRunning ◄───────┘
///                 └──────────────► Failed
///
/// `ReadyToInstall` means the patch is on disk; Shorebird applies it on the next
/// cold start. Nothing here ever restarts the app on its own.
sealed class UpdateState {
  const UpdateState(this.info);
  final UpdateInfo info;
}

class UpdateInitial extends UpdateState {
  const UpdateInitial(super.info);
}

class UpdateChecking extends UpdateState {
  const UpdateChecking(super.info);
}

class UpdateAvailable extends UpdateState {
  const UpdateAvailable(super.info, {this.availableTrack});
  final String? availableTrack;
}

class UpdateDownloading extends UpdateState {
  const UpdateDownloading(super.info);
}

class UpdateReadyToInstall extends UpdateState {
  const UpdateReadyToInstall(super.info);
}

/// The running binary is up to date (or a patch survived startup).
class UpdateConfirmedRunning extends UpdateState {
  const UpdateConfirmedRunning(super.info);
}

class UpdateFailed extends UpdateState {
  const UpdateFailed(super.info, this.message);
  final String message;
}
