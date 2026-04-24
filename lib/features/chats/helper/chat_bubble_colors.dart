import 'package:flutter/material.dart';

Color getReceiverBubbleColor(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return isDarkMode
      ? Theme.of(context).colorScheme.surfaceContainerHigh
      : Colors.grey.shade200;
}

Color getSenderBubbleColor(BuildContext context) {
  return Theme.of(context).primaryColor;
}
