import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tts/tts_service.dart';
import '../../core/widgets/ltr.dart';
import 'word_lookup_sheet.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({Key? key}) : super(key: key);

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final TtsService _tts = TtsService();
  final ScrollController _scrollController = ScrollController();

  // State
  String _currentLevel = 'A1';
  ReadingStoryModel? _story;
  bool _isLoading = true;
  String? _errorMessage;

  // Reading settings
  int _fontSizeIndex = 1; // 0 = 16, 1 = 19, 2 = 23
  static const List<double> _fontSizes = [16.0, 19.0, 23.0];
  static const List<String> _fontSizeLabels = ['صغير', 'متوسط', 'كبير'];

  // Audio state
  bool _isPlayingFullAudio = false;

  // Evidence highlighting from comprehension questions
  int? _highlightedSentenceIndex;

  // Card-by-Card Questions Flow State
  bool _isQuizStarted = false;
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // questionIndex -> optionIndex
  final Map<int, bool> _confirmedQuestions = {}; // questionIndex -> confirmed
  bool _isSubmittingAnswers = false;
  StoryAnswersResult? _answersResult;

  // Memory cache for word lookups & saved words tracking
  final Map<String, WordLookupResult> _wordCache = {};
  final Set<String> _savedWordIds = {};

  // Scroll progress (0.0 to 1.0)
  double _scrollProgress = 0.0;

  // TapGestureRecognizers list to prevent memory leaks
  final List<TapGestureRecognizer> _gestureRecognizers = [];

  @override
  void initState() {
    super.initState();
    _loadFontSizePreference();
    _scrollController.addListener(_onScroll);
    _loadStory();
  }

  @override
  void dispose() {
    _disposeGestureRecognizers();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tts.stop();
    super.dispose();
  }

  void _disposeGestureRecognizers() {
    for (final recognizer in _gestureRecognizers) {
      recognizer.dispose();
    }
    _gestureRecognizers.clear();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0) {
      final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      if ((progress - _scrollProgress).abs() > 0.02) {
        setState(() {
          _scrollProgress = progress;
        });
      }
    }
  }

  Future<void> _loadFontSizePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('reading_font_size');
    if (savedIndex != null && savedIndex >= 0 && savedIndex < _fontSizes.length) {
      setState(() {
        _fontSizeIndex = savedIndex;
      });
    }
  }

  Future<void> _setFontSize(int index) async {
    setState(() {
      _fontSizeIndex = index;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reading_font_size', index);
  }

  Future<void> _loadStory({String? excludeId}) async {
    _tts.stop();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _answersResult = null;
      _selectedAnswers.clear();
      _confirmedQuestions.clear();
      _isQuizStarted = false;
      _currentQuestionIndex = 0;
      _highlightedSentenceIndex = null;
      _isPlayingFullAudio = false;
    });

    try {
      final story = await ApiClient.instance.getReadingStory(
        level: _currentLevel,
        excludeId: excludeId,
      );
      if (!mounted) return;
      setState(() {
        _story = story;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر تحميل قصة القراءة. يرجى التحقق من اتصالك بالإنترنت.';
        _isLoading = false;
      });
    }
  }

  void _onLevelChanged(String newLevel) {
    if (_currentLevel == newLevel) return;
    setState(() {
      _currentLevel = newLevel;
    });
    _loadStory();
  }

  Future<void> _toggleFullAudio() async {
    if (_story == null) return;
    if (_isPlayingFullAudio) {
      await _tts.stop();
      setState(() {
        _isPlayingFullAudio = false;
      });
    } else {
      setState(() {
        _isPlayingFullAudio = true;
      });
      final fullText = _story!.sentences.map((s) => s.english).join(' ');
      await _tts.speak(fullText);
      if (mounted) {
        setState(() {
          _isPlayingFullAudio = false;
        });
      }
    }
  }

  void _onWordTapped(String rawWord) {
    final cleanWord = rawWord.replaceAll(RegExp(r"[^a-zA-Z']"), '').trim();
    if (cleanWord.isEmpty) return;

    _tts.speak(cleanWord);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => WordLookupBottomSheet(
        word: cleanWord,
        cachedResult: _wordCache[cleanWord.toLowerCase()],
        isSavedInitially: _savedWordIds.contains(cleanWord.toLowerCase()),
        onCacheResult: (result) {
          _wordCache[cleanWord.toLowerCase()] = result;
        },
        onWordSaved: (wordId) {
          _savedWordIds.add(cleanWord.toLowerCase());
          if (wordId != null) _savedWordIds.add(wordId);
          setState(() {});
        },
        tts: _tts,
      ),
    );
  }

  void _confirmCurrentQuestion() {
    if (!_selectedAnswers.containsKey(_currentQuestionIndex)) return;
    setState(() {
      _confirmedQuestions[_currentQuestionIndex] = true;
    });
  }

  Future<void> _finishQuizAndSubmit() async {
    if (_story == null || _isSubmittingAnswers) return;

    setState(() {
      _isSubmittingAnswers = true;
    });

    try {
      final total = _story!.questions.length;
      final answersList = List<int>.generate(
        total,
        (i) => _selectedAnswers[i] ?? -1,
      );

      final result = await ApiClient.instance.submitReadingAnswers(
        storyId: _story!.id,
        selectedAnswers: answersList,
      );

      if (!mounted) return;
      setState(() {
        _answersResult = result;
        _isSubmittingAnswers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmittingAnswers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء تصحيح الإجابات.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  void _jumpToEvidenceSentence(int sentenceIndex) {
    setState(() {
      _highlightedSentenceIndex = sentenceIndex;
    });

    _scrollController.animateTo(
      180.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تحديد الجملة الشاهدة رقم $sentenceIndex باللون الأصفر في النص أعلاه 👆'),
        backgroundColor: Colors.amber.shade800,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getGenreColor(String genre) {
    switch (genre.toLowerCase()) {
      case 'mystery':
        return Colors.deepPurple;
      case 'adventure':
        return Colors.deepOrange;
      case 'nature':
        return Colors.teal;
      case 'technology':
        return Colors.indigo;
      case 'history':
        return Colors.brown;
      case 'travel':
        return Colors.cyan.shade800;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_story != null ? _story!.titleAr : 'القراءة والمطالعة'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.format_size),
            tooltip: 'تغيير حجم الخط',
            initialValue: _fontSizeIndex,
            onSelected: _setFontSize,
            itemBuilder: (context) => [
              for (int i = 0; i < _fontSizes.length; i++)
                PopupMenuItem(
                  value: i,
                  child: Row(
                    children: [
                      if (i == _fontSizeIndex)
                        const Icon(Icons.check, size: 18, color: Colors.blueAccent)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text('خط ${_fontSizeLabels[i]} (${_fontSizes[i].toInt()}px)'),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              _isPlayingFullAudio ? Icons.stop_circle : Icons.volume_up_outlined,
              color: _isPlayingFullAudio ? Colors.orangeAccent : Colors.white,
            ),
            tooltip: _isPlayingFullAudio ? 'إيقاف الاستماع' : 'استمع للنص كاملاً',
            onPressed: _toggleFullAudio,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_scrollProgress > 0)
              LinearProgressIndicator(
                value: _scrollProgress,
                minHeight: 3,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            _buildLevelSelector(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSelector() {
    const levels = ['A1', 'A2', 'B1', 'B2'];
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: levels.map((lvl) {
          final isSelected = _currentLevel == lvl;
          return ChoiceChip(
            label: Text(
              lvl,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
            selected: isSelected,
            selectedColor: AppTheme.primary,
            backgroundColor: AppTheme.surfaceVariant,
            onSelected: (_) => _onLevelChanged(lvl),
          );
        }).toList(),
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
              const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _loadStory(),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_story == null) {
      return const Center(child: Text('لا توجد قصة متاحة.'));
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildStoryHeader(_story!),
        const SizedBox(height: 20),
        _buildStoryBodyBook(_story!),
        const SizedBox(height: 28),
        _buildQuizSection(_story!),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStoryHeader(ReadingStoryModel story) {
    final genreColor = _getGenreColor(story.genre);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            genreColor.withOpacity(0.3),
            AppTheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: genreColor.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: genreColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: genreColor.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      story.emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Ltr(
                        child: Text(
                          story.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story.titleAr,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeaderBadge(Icons.bar_chart, story.level, AppTheme.primary),
                _buildHeaderBadge(Icons.category, story.genre, genreColor),
                _buildHeaderBadge(Icons.text_fields, '${story.wordCount} كلمة', Colors.blueGrey),
                _buildHeaderBadge(Icons.timer_outlined, '~${story.estimatedMinutes} دقيقة', Colors.amber),
              ],
            ),
          ],
        ),
      );
    }

  Widget _buildHeaderBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryBodyBook(ReadingStoryModel story) {
    final fontSize = _fontSizes[_fontSizeIndex];
    final paragraphs = story.paragraphs;
    final sortedKeys = paragraphs.keys.toList()..sort();

    _disposeGestureRecognizers();

    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < sortedKeys.length; i++) ...[
              if (i > 0) const SizedBox(height: 18),
              _buildBookParagraph(paragraphs[sortedKeys[i]]!, fontSize),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookParagraph(List<StorySentenceModel> sentences, double fontSize) {
    final spans = <InlineSpan>[];

    for (int sIdx = 0; sIdx < sentences.length; sIdx++) {
      final sentence = sentences[sIdx];
      final isHighlighted = _highlightedSentenceIndex == sentence.orderIndex;

      final words = sentence.english.split(' ');
      for (int wIdx = 0; wIdx < words.length; wIdx++) {
        final rawWord = words[wIdx];
        final cleanWord = rawWord.replaceAll(RegExp(r"[^a-zA-Z']"), '').toLowerCase();
        final isSaved = _savedWordIds.contains(cleanWord);

        final recognizer = TapGestureRecognizer()
          ..onTap = () => _onWordTapped(rawWord);
        _gestureRecognizers.add(recognizer);

        spans.add(
          TextSpan(
            text: rawWord + (wIdx < words.length - 1 ? ' ' : ''),
            recognizer: recognizer,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.75,
              color: isHighlighted
                  ? Colors.amber.shade200
                  : Colors.white,
              backgroundColor: isHighlighted
                  ? Colors.amber.shade900.withOpacity(0.4)
                  : Colors.transparent,
              decoration: isSaved ? TextDecoration.underline : TextDecoration.none,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: AppTheme.primary,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }

      if (sIdx < sentences.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return Ltr(
      child: RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(children: spans),
      ),
    );
  }

  Widget _buildQuizSection(ReadingStoryModel story) {
    if (!_isQuizStarted && _answersResult == null) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _isQuizStarted = true;
              _currentQuestionIndex = 0;
            });
          },
          icon: const Icon(Icons.quiz_outlined, size: 20),
          label: Text('اختبر فهمك للقصة (${story.questions.length} أسئلة)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    if (_answersResult != null) {
      return _buildResultsCard();
    }

    return _buildCardByCardWizard(story);
  }

  Widget _buildCardByCardWizard(ReadingStoryModel story) {
    final questions = story.questions;
    if (questions.isEmpty) return const SizedBox.shrink();

    final q = questions[_currentQuestionIndex];
    final selectedOption = _selectedAnswers[_currentQuestionIndex];
    final isConfirmed = _confirmedQuestions[_currentQuestionIndex] == true;
    final isLast = _currentQuestionIndex == questions.length - 1;

    return Card(
      color: AppTheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'السؤال ${_currentQuestionIndex + 1} من ${questions.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    q.type.toUpperCase(),
                    style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / questions.length,
              minHeight: 5,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
            const SizedBox(height: 18),
            if (q.questionEn != null && q.questionEn!.isNotEmpty) ...[
              Ltr(
                child: Text(
                  q.questionEn!,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              q.questionAr,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 18),
            for (int optIdx = 0; optIdx < q.options.length; optIdx++) ...[
              _buildOptionTile(
                optionText: q.options[optIdx],
                optionIndex: optIdx,
                selectedIndex: selectedOption,
                isConfirmed: isConfirmed,
                onSelect: isConfirmed
                    ? null
                    : () {
                        setState(() {
                          _selectedAnswers[_currentQuestionIndex] = optIdx;
                        });
                      },
              ),
              const SizedBox(height: 10),
            ],
            if (isConfirmed && q.evidenceSentenceIndex != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _jumpToEvidenceSentence(q.evidenceSentenceIndex!),
                icon: const Icon(Icons.find_in_page_outlined, size: 18, color: Colors.amberAccent),
                label: const Text('عرض الدليل من النص 👆', style: TextStyle(color: Colors.amberAccent)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.amberAccent.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (!isConfirmed)
              ElevatedButton(
                onPressed: selectedOption != null ? _confirmCurrentQuestion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('تأكيد الإجابة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              )
            else
              Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentQuestionIndex--;
                          });
                        },
                        child: const Text('السابق'),
                      ),
                    ),
                  if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isLast) {
                          _finishQuizAndSubmit();
                        } else {
                          setState(() {
                            _currentQuestionIndex++;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLast ? AppTheme.success : AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isLast ? 'إنهاء وعرض النتيجة' : 'السؤال التالي 👈',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String optionText,
    required int optionIndex,
    required int? selectedIndex,
    required bool isConfirmed,
    required VoidCallback? onSelect,
  }) {
    final isSelected = selectedIndex == optionIndex;
    Color borderColor = Colors.white12;
    Color bgColor = AppTheme.surfaceVariant;
    Widget? trailingIcon;

    if (isSelected) {
      borderColor = AppTheme.primary;
      bgColor = AppTheme.primary.withOpacity(0.15);
      trailingIcon = const Icon(Icons.check_circle, color: AppTheme.primary, size: 20);
    }

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Ltr(
                child: Text(
                  optionText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (trailingIcon != null) trailingIcon,
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    final res = _answersResult!;
    final isPassed = res.score >= 60;
    return Card(
      color: AppTheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          children: [
            Icon(
              isPassed ? Icons.emoji_events : Icons.refresh,
              size: 56,
              color: isPassed ? Colors.amber : Colors.orangeAccent,
            ),
            const SizedBox(height: 12),
            Text(
              isPassed ? 'أحسنت! أداء رائع' : 'حاول مرة أخرى للمزيد من الإتقان',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'أجبت بشكل صحيح على ${res.correctCount} من ${res.totalQuestions} (${res.score}%)',
              style: const TextStyle(fontSize: 15, color: Colors.white70),
            ),
            if (res.xpAwarded > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '+${res.xpAwarded} نقطة خبرة XP',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _answersResult = null;
                        _selectedAnswers.clear();
                        _confirmedQuestions.clear();
                        _currentQuestionIndex = 0;
                        _isQuizStarted = true;
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('إعادة الاختبار'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _loadStory(excludeId: _story?.id),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('قصة جديدة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
