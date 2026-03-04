import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppSecrets {
  static String supabaseUrl = dotenv.get('SUPABASE_URL', fallback: '');
  static String supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: '');
}
