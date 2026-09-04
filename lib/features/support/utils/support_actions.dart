import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/toast/app_toast.dart';

class SupportActions {
  const SupportActions._();

  static Future<void> sendFeedback(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'ahmedateif0@gmail.com',
      queryParameters: {
        'subject': 'Syncra App Feedback',
        'body': 'Hi Ahmed,\n\n',
      },
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        AppToast.error('Could not open your email app.');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error('Could not open your email app.');
      }
    }
  }
}
