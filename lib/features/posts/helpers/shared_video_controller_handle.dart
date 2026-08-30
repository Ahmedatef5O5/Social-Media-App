import 'package:video_player/video_player.dart';

class SharedVideoControllerHandle {
  SharedVideoControllerHandle(this.controller);

  final VideoPlayerController controller;

  int _refCount = 0;
  bool _disposed = false;

  void acquire() {
    if (_disposed) {
      assert(false, 'acquire() called after the controller was disposed.');
      return;
    }
    _refCount++;
  }

  void release() {
    if (_disposed) return;
    _refCount--;
    if (_refCount <= 0) {
      _disposed = true;
      controller.dispose();
    }
  }
}
