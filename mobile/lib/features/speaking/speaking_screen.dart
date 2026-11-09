import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tts/tts_service.dart';
import '../../core/stt/stt_service.dart';
import '../../core/widgets/ltr.dart';

class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({Key? key}) : super(key: key);

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  final TtsService _tts = TtsService();
  final SttService _stt = SttService();

  final String _sentence = 'Hello, my name is Sara.';
  final String _sentenceAr = 'مرحبًا، اسمي سارة.';
  final String _tip = 'انطق th في «the» بوضع طرف اللسان بين الأسنان.';

  bool _isListening = false;
  String _recognizedText = '';
  int? _score;
  List<(String, bool)> _chips = [];

  void _listen() async {
    if (_isListening) {
      await _stt.stop();
      setState(() => _isListening = false);
      _evaluateSpeech();
    } else {
      setState(() {
        _isListening = true;
        _recognizedText = '';
        _score = null;
      });

      await _stt.listen(
        onResult: (text) {
          setState(() {
            _recognizedText = text;
          });
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
            _evaluateSpeech();
          }
        },
      );
    }
  }

  void _evaluateSpeech() {
    final targetWords = _sentence.toLowerCase().replaceAll(RegExp(r'[^a-z\s]'), '').split(' ');
    final saidWords = _recognizedText.toLowerCase().replaceAll(RegExp(r'[^a-z\s]'), '').split(' ');

    int matched = 0;
    List<(String, bool)> chips = [];

    for (var tw in targetWords) {
      if (saidWords.contains(tw)) {
        matched++;
        chips.add((tw, true));
      } else {
        chips.add((tw, false));
      }
    }

    int score = targetWords.isNotEmpty ? ((matched / targetWords.length) * 100).round() : 0;
    setState(() {
      _score = score;
      _chips = chips;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التكلم — Speaking'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sentence display card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Ltr(
                      child: Text(
                        _sentence,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sentenceAr,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () => _tts.speak(_sentence),
                        ),
                        IconButton(
                          icon: const Icon(Icons.slow_motion_video),
                          onPressed: () => _tts.speak(_sentence, slow: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pronunciation tip
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_tip, style: const TextStyle(fontSize: 13, color: AppTheme.warning))),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Score Ring & Chips
              if (_score != null) ...[
                Text(
                  'وضوح النطق: $_score%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _score! >= 80 ? AppTheme.success : AppTheme.warning,
                  ),
                ),
                const SizedBox(height: 12),
                Ltr(
                  child: Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: _chips.map((c) {
                      return Chip(
                        label: Text(c.$1, style: TextStyle(color: c.$2 ? Colors.white : Colors.white70)),
                        backgroundColor: c.$2 ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.danger.withValues(alpha: 0.3),
                        avatar: Icon(c.$2 ? Icons.check : Icons.close, size: 16, color: c.$2 ? AppTheme.success : AppTheme.danger),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const Spacer(),

              // Microphone button
              Center(
                child: GestureDetector(
                  onTap: _listen,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? AppTheme.danger : AppTheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? AppTheme.danger : AppTheme.primary).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(_isListening ? Icons.stop : Icons.mic, size: 40, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isListening ? 'جاري الاستماع إليك... اضغط للإيقاف' : 'اضغط على الميكروفون وتكلم',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

