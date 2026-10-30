import 'package:social_media_app/core/services/app_system_status.dart';

/// Which blocking screen (if any) covers the app.
enum GateScreen { none, maintenance, forceUpdate, suspended }

/// Pure decision function shared by the gate widget and the back-button
/// blocker, so what the user sees and what Back does can never disagree.
///
/// Priority: maintenance > forced update > suspension.
///  * Maintenance blocks everyone who is not on the bypass list. A signed-out
///    staff member may open the login screen ([staffSignInMode]) because bypass
///    is per-user and unknowable before sign-in.
///  * A suspension screen only makes sense for a signed-in caller.
GateScreen decideGate(
  AppSystemStatus status, {
  required bool authenticated,
  bool staffSignInMode = false,
}) {
  if (status.blocksForMaintenance) {
    final staffMayPass = staffSignInMode && !authenticated;
    if (!staffMayPass) return GateScreen.maintenance;
  }
  if (status.updateRequired) return GateScreen.forceUpdate;
  if (status.isCallerSuspended && authenticated) return GateScreen.suspended;
  return GateScreen.none;
}
