import 'package:speech_to_text/speech_to_text.dart';

class AiChatDictationController {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _stoppedManually = true;

  void Function(String liveWords)? _onLiveUpdate;
  void Function(String finalWords)? _onFinalSegment;

  Future<bool> ensureInitialized() async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(onStatus: _handleStatus);
    } catch (_) {
      _initialized = false;
    }
    return _initialized;
  }

  bool get isListening => _speech.isListening;

  void _handleStatus(String status) {
    if (_stoppedManually) return;
    if (status == 'notListening' || status == 'done') {
      _listenOnce();
    }
  }

  Future<bool> start({
    required void Function(String liveWords) onLiveUpdate,
    required void Function(String finalWords) onFinalSegment,
  }) async {
    final ready = await ensureInitialized();
    if (!ready) return false;
    _onLiveUpdate = onLiveUpdate;
    _onFinalSegment = onFinalSegment;
    _stoppedManually = false;
    await _listenOnce();
    return true;
  }

  Future<void> _listenOnce() {
    return _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          if (result.recognizedWords.trim().isNotEmpty) {
            _onFinalSegment?.call(result.recognizedWords);
          }
        } else {
          _onLiveUpdate?.call(result.recognizedWords);
        }
      },
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(partialResults: true),
    );
  }

  Future<void> stop() {
    _stoppedManually = true;
    return _speech.stop();
  }

  Future<void> cancel() {
    _stoppedManually = true;
    return _speech.cancel();
  }

  void dispose() {
    _stoppedManually = true;
    if (_speech.isListening) _speech.cancel();
  }
}
