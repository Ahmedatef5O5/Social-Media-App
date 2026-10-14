import 'package:supabase_flutter/supabase_flutter.dart' show User;

/// Describes HOW the signed-in user authenticates (password, OAuth, or both).

class AccountAuthInfo {
  final bool hasPassword;
  final List<String> oauthProviders;

  const AccountAuthInfo({
    required this.hasPassword,
    required this.oauthProviders,
  });

  factory AccountAuthInfo.fromUser(User user) {
    final providers = <String>{};

    final rawList = user.appMetadata['providers'];
    if (rawList is List) providers.addAll(rawList.whereType<String>());

    final rawSingle = user.appMetadata['provider'];
    if (rawSingle is String) providers.add(rawSingle);

    final identities = user.identities;
    if (identities != null) {
      for (final identity in identities) {
        providers.add(identity.provider);
      }
    }

    final hasPasswordFlag = user.userMetadata?['has_password'] == true;
    final hasPassword = providers.contains('email') || hasPasswordFlag;

    final oauth =
        providers
            .where((p) => p != 'email' && p != 'phone' && p != 'anonymous')
            .toList();

    return AccountAuthInfo(hasPassword: hasPassword, oauthProviders: oauth);
  }

  bool get isOAuthLinked => oauthProviders.isNotEmpty;

  bool get isOAuthOnly => isOAuthLinked && !hasPassword;

  String get oauthLabel => oauthProviders.map(labelFor).join(' & ');

  String get signInMethodLabel {
    if (hasPassword && isOAuthLinked) return 'Email & Password + $oauthLabel';
    if (isOAuthLinked) return '$oauthLabel Account';
    return 'Email & Password';
  }

  static String labelFor(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return 'Google';
      case 'facebook':
        return 'Facebook';
      case 'azure':
        return 'Microsoft';
      case 'apple':
        return 'Apple';
      case 'github':
        return 'GitHub';
      default:
        if (provider.isEmpty) return provider;
        return '${provider[0].toUpperCase()}${provider.substring(1)}';
    }
  }
}
