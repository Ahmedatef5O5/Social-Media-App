import 'package:googleapis_auth/auth_io.dart';
import 'package:social_media_app/core/secrets/app_secrets.dart';

class FcmTokenService {
  String? _cachedToken;
  DateTime? _expiry;

  Future<String> getValidToken() async {
    if (_cachedToken != null &&
        _expiry != null &&
        DateTime.now().isBefore(_expiry!)) {
      return _cachedToken!;
    }

    final token = await _generateAccessToken();
    _cachedToken = token;
    _expiry = DateTime.now().add(const Duration(minutes: 55));
    return token;
  }

  Future<String> _generateAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": AppSecrets.fcmProjectId,
      "private_key": AppSecrets.fcmPrivateKey.trim(),
      "client_email": AppSecrets.fcmClientEmail,
      "client_id": AppSecrets.fcmClientId,
      "token_uri": "https://oauth2.googleapis.com/token",
    };

    final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(credentials, scopes);
    final token = client.credentials.accessToken.data;
    client.close();

    return token;
  }
}
