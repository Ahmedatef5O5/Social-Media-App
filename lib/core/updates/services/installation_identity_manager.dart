import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Persistent, random per-installation id used to correlate update telemetry.
///
/// It is NOT a hardware identifier and is regenerated when the app is
/// reinstalled / its data is cleared, which is exactly the scope we want.
class InstallationIdentityManager {
  InstallationIdentityManager({SharedPreferences? prefs, Uuid? uuid})
    : _prefs = prefs,
      _uuid = uuid ?? const Uuid();

  static const String prefsKey = 'update_installation_id_v1';
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );

  final SharedPreferences? _prefs;
  final Uuid _uuid;
  String? _cached;

  /// Never throws: if storage is unusable an in-memory id is used for this run.
  Future<String> getInstallationId() async {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final stored = prefs.getString(prefsKey);
      if (stored != null && _uuidPattern.hasMatch(stored)) {
        return _cached = stored;
      }
      final fresh = _uuid.v4().toLowerCase();
      await prefs.setString(prefsKey, fresh);
      return _cached = fresh;
    } catch (_) {
      return _cached = _uuid.v4().toLowerCase();
    }
  }
}
