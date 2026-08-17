import 'package:hive/hive.dart';

class AiModelPreferenceStore {
  AiModelPreferenceStore(this._box);

  static const String boxName = 'ai_model_preference';
  static const String _preferredProviderKey = 'preferred_provider';
  static const String _cooldownPrefix = 'cooldown:';

  final Box<dynamic> _box;

  String? get preferredProvider => _box.get(_preferredProviderKey) as String?;

  Future<void> setPreferredProvider(String? provider) {
    if (provider == null) return _box.delete(_preferredProviderKey);
    return _box.put(_preferredProviderKey, provider);
  }

  Future<void> markCooldown(String provider, Duration duration) {
    return _box.put(
      '$_cooldownPrefix$provider',
      DateTime.now().add(duration).toIso8601String(),
    );
  }

  bool isInCooldown(String provider) {
    final raw = _box.get('$_cooldownPrefix$provider') as String?;
    if (raw == null) return false;
    final until = DateTime.tryParse(raw);
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }
}
