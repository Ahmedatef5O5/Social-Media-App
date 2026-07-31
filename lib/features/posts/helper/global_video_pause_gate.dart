import 'package:flutter/material.dart';

class GlobalVideoPauseGate {
  GlobalVideoPauseGate._();
  static final instance = GlobalVideoPauseGate._();

  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);
}
