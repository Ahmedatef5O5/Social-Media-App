import 'dart:async';
import 'comment_events.dart';

class CommentEventBus {
  CommentEventBus._();
  static final instance = CommentEventBus._();

  final _controller = StreamController<CommentEvent>.broadcast();

  Stream<CommentEvent> get stream => _controller.stream;

  void emit(CommentEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
