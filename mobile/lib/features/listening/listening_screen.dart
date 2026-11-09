import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tts/tts_service.dart';
import '../../core/widgets/ltr.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({Key? key}) : super(key: key);

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final TtsService _tts = TtsService();

  final String _sentence = 'I drink coffee every morning.';
  final String _sentenceAr = 'أشرب القهوة كل صباح.';
  final String _question = 'ماذا يشرب المتحدث كل صباح؟';
  final List<String> _options = ['قهوة', 'حليب', 'شاي'];
  final int _correctIndex = 0;

  int? _selected;
  bool _answered = false;

  void _playAudio({bool slow = false}) {
    _tts.speak(_sentence, slow: slow);
  }

  @override
  void initState() {
    super.initState();
    _playAudio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاستماع — Listening'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sound buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _playAudio(),
                    icon: const Icon(Icons.volume_up),
                    label: const Text('استمع'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => _playAudio(slow: true),
                    icon: const Icon(Icons.slow_motion_video),
                    label: const Text('أبطأ'),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              Text(
                _question,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Options
              ..._options.asMap().entries.map((entry) {
                final idx = entry.key;
                final text = entry.value;

                Color bg = AppTheme.surface;
                Color border = AppTheme.border;

                if (_answered) {
                  if (idx == _correctIndex) {
                    bg = AppTheme.success.withOpacity(0.2);
                    border = AppTheme.success;
                  } else if (_selected == idx) {
                    bg = AppTheme.danger.withOpacity(0.2);
                    border = AppTheme.danger;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      if (!_answered) {
                        setState(() {
                          _selected = idx;
                          _answered = true;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border, width: 2),
                      ),
                      child: RegExp(r'[a-zA-Z]').hasMatch(text)
                          ? Ltr(
                              child: Text(
                                text,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Text(
                              text,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                );
              }),

              const Spacer(),

              if (_answered) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Ltr(
                        child: Text(
                          _sentence,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _sentenceAr,
                        style: const TextStyle(color: Colors.white70),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _answered = false;
                      _selected = null;
                      _playAudio();
                    });
                  },
                  child: const Text('التمرين التالي ➔'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

