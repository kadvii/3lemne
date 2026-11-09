import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage("en-US");
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5); // Natural rate
      _isInitialized = true;
    } catch (_) {}
  }

  Future<void> speak(String text, {bool slow = false}) async {
    await init();
    try {
      await _tts.stop();
      await _tts.setSpeechRate(slow ? 0.3 : 0.5);
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

