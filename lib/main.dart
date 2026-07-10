import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/bootstrap/app_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final String savedTheme = prefs.getString('user_theme_key') ?? 'ocean';

  runApp(buildApp(savedTheme));
}
