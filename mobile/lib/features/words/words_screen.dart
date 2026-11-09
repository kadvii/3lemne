import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tts/tts_service.dart';
import '../../core/widgets/ltr.dart';
import '../../core/widgets/mobile_frame.dart';

class WordsScreen extends StatefulWidget {
  final List<SavedWordModel>? initialWords;

  const WordsScreen({Key? key, this.initialWords}) : super(key: key);

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  final TtsService _tts = TtsService();

  List<SavedWordModel> _words = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Flashcards SRS Mode
  bool _isReviewMode = false;
  int _currentCardIndex = 0;
  bool _isFlipped = false;
  int _reviewedCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialWords != null) {
      _words = List.from(widget.initialWords!);
      _isLoading = false;
    } else {
      _loadWords();
    }
  }

  Future<void> _loadWords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ApiClient.instance.getSavedWords();
      setState(() {
        _words = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل المفردات المحفوظة.';
      });
    }
  }

  Future<void> _deleteWord(int index) async {
    final item = _words[index];
    setState(() {
      _words.removeAt(index);
    });

    if (item.wordId.isNotEmpty) {
      await ApiClient.instance.unsaveWord(item.wordId);
    }
  }

  void _speakAll() async {
    for (var w in _words) {
      await _tts.speak(w.english);
      await Future.delayed(const Duration(milliseconds: 1200));
    }
  }

  void _startReview() {
    if (_words.isEmpty) return;
    setState(() {
      _isReviewMode = true;
      _currentCardIndex = 0;
      _isFlipped = false;
      _reviewedCount = 0;
    });
    _tts.speak(_words[_currentCardIndex].english);
  }

  void _onAnswerReview(bool remembered) {
    setState(() {
      _reviewedCount++;
      if (_currentCardIndex < _words.length - 1) {
        _currentCardIndex++;
        _isFlipped = false;
        _tts.speak(_words[_currentCardIndex].english);
      } else {
        _isReviewMode = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('أتممت مراجعة $_reviewedCount كلمة بنجاح! (+10 XP) 🎉'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MobileFrame(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(_isReviewMode ? 'مراجعة البطاقات الذكية (SRS)' : 'مفرداتي المحفوظة'),
          actions: [
            if (!_isReviewMode && _words.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.style_outlined),
                tooltip: 'بدء المراجعة المتباعدة',
                onPressed: _startReview,
              ),
              IconButton(
                icon: const Icon(Icons.playlist_play),
                tooltip: 'استمع للكل',
                onPressed: _speakAll,
              ),
            ],
            if (_isReviewMode)
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'إنهاء المراجعة',
                onPressed: () {
                  setState(() {
                    _isReviewMode = false;
                  });
                },
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadWords,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_words.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📚', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text(
                'لم تحفظ أي كلمة بعد',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'اقرأ قصة واضغط على أي كلمة لا تعرفها لإضافتها إلى قائمة المراجعة التكرارية (SRS).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    if (_isReviewMode) {
      return _buildFlashcardView();
    }

    return _buildListView();
  }

  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _words[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.volume_up, color: AppTheme.primary),
                onPressed: () => _tts.speak(item.english),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Ltr(
                            child: Text(
                              item.english,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.srsStageLabel,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64B5F6)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.arabic,
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                onPressed: () => _deleteWord(index),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlashcardView() {
    final currentWord = _words[_currentCardIndex];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentCardIndex + 1) / _words.length,
            backgroundColor: AppTheme.surfaceVariant,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'بطاقة ${_currentCardIndex + 1} من ${_words.length}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const Spacer(),

          // Card
          GestureDetector(
            onTap: () {
              setState(() {
                _isFlipped = !_isFlipped;
              });
            },
            child: Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isFlipped ? AppTheme.primary : AppTheme.border,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Ltr(
                        child: Text(
                          currentWord.english,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!_isFlipped) ...[
                        const Icon(Icons.touch_app, size: 28, color: Colors.grey),
                        const SizedBox(height: 6),
                        const Text(
                          'اضغط لكشف المعنى بالعربي',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ] else ...[
                        Text(
                          currentWord.arabic,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentWord.srsStageLabel,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),

          // Recall response buttons
          if (_isFlipped)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _onAnswerReview(false),
                    child: const Text('نسيتها ❌', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _onAnswerReview(true),
                    child: const Text('تذكرتها ✅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  setState(() {
                    _isFlipped = true;
                  });
                },
                icon: const Icon(Icons.visibility),
                label: const Text('اكشف المعنى'),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
