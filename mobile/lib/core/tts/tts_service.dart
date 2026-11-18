import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  String _currentLanguage = 'en-US';

  Future<void> init([String languageCode = 'en-US']) async {
    if (_isInitialized && _currentLanguage == languageCode) return;
    try {
      final targetLang = _resolveLanguage(languageCode);
      final isAvailable = await _tts.isLanguageAvailable(targetLang);

      if (isAvailable == true) {
        await _tts.setLanguage(targetLang);
        _currentLanguage = targetLang;
      } else {
        debugPrint('TtsService: Language $targetLang not available on this device');
      }

      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5); // Natural rate
      _isInitialized = true;
    } catch (e) {
      debugPrint('TtsService init error: $e');
    }
  }

  /// Speaks text in the specified language ('zh' for Chinese zh-CN, 'en' for English en-US)
  Future<void> speak(
    String text, {
    String languageCode = 'en-US',
    bool slow = false,
  }) async {
    try {
      final targetLang = _resolveLanguage(languageCode);

      // Re-configure language if different from active one
      if (!_isInitialized || _currentLanguage != targetLang) {
        final isAvailable = await _tts.isLanguageAvailable(targetLang);
        if (isAvailable == true) {
          await _tts.setLanguage(targetLang);
          _currentLanguage = targetLang;
        } else {
          debugPrint('TtsService: Language $targetLang is not available on this device');
        }
      }

      await _tts.stop();
      await _tts.setSpeechRate(slow ? 0.3 : 0.5);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TtsService speak error: $e');
    }
  }

  /// Convenience method matching speak(text, languageCode)
  Future<void> speakWithLang(String text, String languageCode, {bool slow = false}) =>
      speak(text, languageCode: languageCode, slow: slow);

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Helper to speak Chinese Mandarin specifically
  Future<void> speakChinese(String text, {bool slow = false}) =>
      speak(text, languageCode: 'zh', slow: slow);

  /// Helper to speak English specifically
  Future<void> speakEnglish(String text, {bool slow = false}) =>
      speak(text, languageCode: 'en', slow: slow);

  String _resolveLanguage(String code) {
    if (code.toLowerCase().startsWith('zh')) {
      return 'zh-CN';
    }
    return 'en-US';
  }
}


