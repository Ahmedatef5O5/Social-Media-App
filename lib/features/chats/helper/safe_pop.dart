import 'package:flutter/material.dart';

void safePop(BuildContext context) {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  }
}
