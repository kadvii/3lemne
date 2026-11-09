import 'package:speech_to_text/speech_to_text.dart';

class SttService {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;

  Future<bool> init() async {
    if (_available) return true;
    _available = await _speech.initialize();
    return _available;
  }

  Future<void> listen({
    required Function(String text) onResult,
    required Function(String status) onStatus,
  }) async {
    final hasInit = await init();
    if (!hasInit) return;

    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      localeId: "en-US",
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  bool get isListening => _speech.isListening;
}

