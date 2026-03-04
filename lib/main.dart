import 'package:flutter/material.dart';
import 'package:social_media_app/core/themes/app_themes.dart';
import 'package:social_media_app/features/auth/views/auth_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: AppThemes.lightTheme,
      home: AuthView(),
    );
  }
}
