import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tts/tts_service.dart';
import '../../core/widgets/ltr.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({Key? key}) : super(key: key);

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> with SingleTickerProviderStateMixin {
  final TtsService _tts = TtsService();

  late TabController _tabController;
  String _level = 'A1';

  // --- Word Dictation State ---
  WritingNextItem? _currentWordItem;
  bool _isLoadingWord = true;
  String? _wordError;
  String? _lastWordId;
  String _targetWord = '';

  // Single hidden TextField controller & focus node
  final TextEditingController _wordTextController = TextEditingController();
  final FocusNode _wordFocusNode = FocusNode();

  // Rule R6: Random Partial Hint State
  final Set<int> _revealedHintIndices = {};
  final Map<int, String> _revealedLetters = {};
  int _hintsUsed = 0;
  bool _showVowelsHint = false;
  bool _showSentenceExampleHint = false;

  int _attemptsLeft = 2;
  WritingCheckResult? _checkResult;
  bool _isCheckingWord = false;

  // Scrambled letter chips for touch assistance
  List<String> _letterChips = [];

  // --- Sentence Dictation State ---
  ListeningNextItem? _currentSentenceItem;
  bool _isLoadingSentence = true;
  String? _sentenceError;
  final TextEditingController _sentenceController = TextEditingController();
  final FocusNode _sentenceFocusNode = FocusNode();
  bool _sentenceChecked = false;
  bool _sentencePassed = false;
  List<(String, bool, String?)> _sentenceWordChips = [];

  // Rule R6: Max allowed hints
  int get _maxAllowedHints {
    if (_currentWordItem == null) return 0;
    final len = _currentWordItem!.length;
    final half = (len / 2).floor();
    final cap = min(3, half);
    final maxPossible = max(0, len - 2);
    return min(cap, maxPossible);
  }

  bool get _isHintLimitReached => _revealedHintIndices.length >= _maxAllowedHints;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNextWord();
    _loadNextSentence();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wordTextController.dispose();
    _wordFocusNode.dispose();
    _sentenceController.dispose();
    _sentenceFocusNode.dispose();
    _tts.stop();
    super.dispose();
  }

  // ================= Word Dictation Methods =================

  Future<void> _loadNextWord() async {
    _tts.stop();
    setState(() {
      _isLoadingWord = true;
      _wordError = null;
      _checkResult = null;
      _revealedHintIndices.clear();
      _revealedLetters.clear();
      _hintsUsed = 0;
      _showVowelsHint = false;
      _showSentenceExampleHint = false;
      _attemptsLeft = 2;
      _wordTextController.clear();
      _letterChips = [];
      _targetWord = '';
    });

    try {
      final item = await ApiClient.instance.getWritingNext(level: _level);

      WritingNextItem finalItem = item;
      if (_lastWordId != null && item.id == _lastWordId) {
        try {
          final retry = await ApiClient.instance.getWritingNext(level: _level);
          finalItem = retry;
        } catch (_) {}
      }

      _lastWordId = finalItem.id;

      // Lookup target word for random hint generation
      try {
        final lookup = await ApiClient.instance.lookupWord(finalItem.hintAr);
        if (lookup.found && lookup.word.isNotEmpty) {
          _targetWord = lookup.word.toLowerCase();
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _currentWordItem = finalItem;
        _isLoadingWord = false;
      });

      _generateLetterChips(finalItem.length);
      _wordFocusNode.requestFocus();
      _playWordAudio();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _wordError = 'تعذر جلب الكلمة التالية. تحقق من الاتصال.';
        _isLoadingWord = false;
      });
    }
  }

  void _generateLetterChips(int wordLength) {
    if (_targetWord.isNotEmpty) {
      final letters = _targetWord.split('');
      const alphabet = 'abcdefghijklmnopqrstuvwxyz';
      final random = Random();
      final extraCount = max(2, (8 - letters.length));
      for (int i = 0; i < extraCount; i++) {
        letters.add(alphabet[random.nextInt(alphabet.length)]);
      }
      letters.shuffle();
      setState(() {
        _letterChips = letters;
      });
    } else {
      setState(() {
        _letterChips = [];
      });
    }
  }

  void _playWordAudio({bool slow = false}) {
    if (_checkResult != null) {
      _tts.speak(_checkResult!.word, slow: slow);
    } else if (_targetWord.isNotEmpty) {
      _tts.speak(_targetWord, slow: slow);
    } else if (_currentWordItem != null) {
      _tts.speak(_currentWordItem!.hintAr, slow: slow);
    }
  }

  Future<void> _checkWordAnswer() async {
    if (_currentWordItem == null || _isCheckingWord) return;
    final answer = _wordTextController.text.trim();
    if (answer.isEmpty) return;

    setState(() {
      _isCheckingWord = true;
    });

    try {
      final result = await ApiClient.instance.checkWritingAnswer(
        wordId: _currentWordItem!.wordId,
        answer: answer,
        hintsUsed: _hintsUsed,
      );

      if (!mounted) return;
      setState(() {
        _checkResult = result;
        _isCheckingWord = false;
        if (!result.isCorrect) {
          _attemptsLeft--;
        }
      });

      if (result.isCorrect) {
        _tts.speak(result.word);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCheckingWord = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء التحقق من الكلمة.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  // Rule R6: Random Partial Hint
  void _revealRandomLetterHint() {
    if (_currentWordItem == null || _checkResult?.isCorrect == true) return;

    if (_isHintLimitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ما أكدر أساعدك أكثر، حاول! 💪'),
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final len = _currentWordItem!.length;
    if (_targetWord.isEmpty || _targetWord.length != len) return;

    final availableIndices = <int>[];
    for (int i = 0; i < len; i++) {
      if (!_revealedHintIndices.contains(i)) {
        availableIndices.add(i);
      }
    }

    if (availableIndices.isEmpty) return;

    final randomPos = availableIndices[Random().nextInt(availableIndices.length)];
    final letter = _targetWord[randomPos];

    setState(() {
      _revealedHintIndices.add(randomPos);
      _revealedLetters[randomPos] = letter;
      _hintsUsed++;

      // Automatically sync with typed text if needed
      final current = _wordTextController.text;
      if (current.length <= randomPos) {
        // Pad with revealed letters or spaces
        var padded = current;
        while (padded.length < randomPos) {
          final nextIdx = padded.length;
          padded += _revealedLetters[nextIdx] ?? ' ';
        }
        padded += letter;
        _wordTextController.text = padded.trimRight();
      } else {
        // Replace character at randomPos
        final chars = current.split('');
        chars[randomPos] = letter;
        _wordTextController.text = chars.join('');
      }
      _wordTextController.selection = TextSelection.fromPosition(
        TextPosition(offset: _wordTextController.text.length),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم كشف حرف عشوائي: "$letter" (-1 XP)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onLetterChipTapped(String char) {
    if (_currentWordItem == null || _checkResult?.isCorrect == true) return;
    if (_wordTextController.text.length < _currentWordItem!.length) {
      setState(() {
        _wordTextController.text = _wordTextController.text + char.toLowerCase();
        _wordTextController.selection = TextSelection.fromPosition(
          TextPosition(offset: _wordTextController.text.length),
        );
      });
    }
  }

  void _onBackspaceTapped() {
    if (_wordTextController.text.isNotEmpty) {
      setState(() {
        _wordTextController.text = _wordTextController.text.substring(0, _wordTextController.text.length - 1);
        _wordTextController.selection = TextSelection.fromPosition(
          TextPosition(offset: _wordTextController.text.length),
        );
      });
    }
  }

  // ================= Sentence Dictation Methods =================

  Future<void> _loadNextSentence() async {
    _tts.stop();
    setState(() {
      _isLoadingSentence = true;
      _sentenceError = null;
      _sentenceChecked = false;
      _sentencePassed = false;
      _sentenceWordChips = [];
      _sentenceController.clear();
    });

    try {
      final item = await ApiClient.instance.getListeningNext(level: _level);
      if (!mounted) return;
      setState(() {
        _currentSentenceItem = item;
        _isLoadingSentence = false;
      });
      _playSentenceAudio();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sentenceError = 'تعذر جلب جملة الإملاء.';
        _isLoadingSentence = false;
      });
    }
  }

  void _playSentenceAudio({bool slow = false}) {
    if (_currentSentenceItem != null && _currentSentenceItem!.english.isNotEmpty) {
      _tts.speak(_currentSentenceItem!.english, slow: slow);
    }
  }

  void _checkSentenceAnswer() {
    if (_currentSentenceItem == null) return;
    final target = _currentSentenceItem!.english.trim();
    final typed = _sentenceController.text.trim();

    final targetWords = target.split(RegExp(r'\s+'));
    final typedWords = typed.split(RegExp(r'\s+'));

    final chips = <(String, bool, String?)>[];
    int matchedCount = 0;

    for (int i = 0; i < targetWords.length; i++) {
      final cleanTarget = targetWords[i].replaceAll(RegExp(r"[^a-zA-Z']"), '').toLowerCase();
      final cleanTyped = i < typedWords.length
          ? typedWords[i].replaceAll(RegExp(r"[^a-zA-Z']"), '').toLowerCase()
          : '';

      final isMatch = cleanTarget == cleanTyped;
      if (isMatch) matchedCount++;
      chips.add((targetWords[i], isMatch, i < typedWords.length ? typedWords[i] : null));
    }

    final scoreRatio = targetWords.isNotEmpty ? matchedCount / targetWords.length : 0.0;
    final passed = scoreRatio >= 0.8;

    setState(() {
      _sentenceChecked = true;
      _sentencePassed = passed;
      _sentenceWordChips = chips;
    });

    if (passed) {
      _tts.speak(target);
    }
  }

  // ================= Build UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الكتابة والإملاء — Writing'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: _level,
              dropdownColor: AppTheme.surface,
              underline: const SizedBox(),
              items: ['A1', 'A2', 'B1', 'B2'].map((lvl) {
                return DropdownMenuItem(
                  value: lvl,
                  child: Text(
                    lvl,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null && val != _level) {
                  setState(() => _level = val);
                  _loadNextWord();
                  _loadNextSentence();
                }
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(icon: Icon(Icons.spellcheck), text: 'إملاء الكلمات'),
            Tab(icon: Icon(Icons.short_text), text: 'إملاء الجمل'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWordDictationTab(),
          _buildSentenceDictationTab(),
        ],
      ),
    );
  }

  // ================= Tab 1: Word Dictation =================

  Widget _buildWordDictationTab() {
    if (_isLoadingWord) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_wordError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
            const SizedBox(height: 12),
            Text(_wordError!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadNextWord, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    final item = _currentWordItem!;
    final typedText = _wordTextController.text;
    final isSuccess = _checkResult?.isCorrect == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Audio & Hint Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _playWordAudio(),
                icon: const Icon(Icons.volume_up),
                label: const Text('استمع'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _playWordAudio(slow: true),
                icon: const Icon(Icons.slow_motion_video),
                label: const Text('بطيء'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 10),
              // Rule R6 Random Hint Button
              IconButton(
                icon: Icon(
                  Icons.lightbulb,
                  color: _isHintLimitReached ? Colors.grey : Colors.amber,
                ),
                tooltip: _isHintLimitReached ? 'وصلت للحد الأقصى للتلميحات' : 'كشف حرف عشوائي (-1 XP)',
                onPressed: isSuccess || _isHintLimitReached ? null : _revealRandomLetterHint,
              ),
              if (_hintsUsed > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_hintsUsed/$_maxAllowedHints',
                    style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Meaning & Word Length Card
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('المعنى: ', style: TextStyle(color: Colors.grey, fontSize: 15)),
                  Text(
                    item.hintAr,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.length} أحرف',
                      style: const TextStyle(fontSize: 13, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Alternate Hint Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item.vowelCount != null)
                ActionChip(
                  avatar: const Icon(Icons.format_italic, size: 16, color: Colors.cyanAccent),
                  label: Text(_showVowelsHint ? '${item.vowelCount} حروف صوتية' : 'الحروف الصوتية؟'),
                  backgroundColor: AppTheme.surface,
                  onPressed: () {
                    setState(() {
                      _showVowelsHint = !_showVowelsHint;
                    });
                  },
                ),
              if (item.vowelCount != null && item.exampleEn != null) const SizedBox(width: 8),
              if (item.exampleEn != null)
                ActionChip(
                  avatar: const Icon(Icons.short_text, size: 16, color: Colors.amberAccent),
                  label: Text(_showSentenceExampleHint ? 'إخفاء المثال' : 'مثال بسياق'),
                  backgroundColor: AppTheme.surface,
                  onPressed: () {
                    setState(() {
                      _showSentenceExampleHint = !_showSentenceExampleHint;
                    });
                  },
                ),
            ],
          ),

          if (_showSentenceExampleHint && item.exampleEn != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Ltr(
                child: Text(
                  item.exampleEn!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.amber, fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Hidden Native TextField for smooth keyboard capture
          Opacity(
            opacity: 0.0,
            child: SizedBox(
              height: 1,
              child: TextField(
                controller: _wordTextController,
                focusNode: _wordFocusNode,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                maxLength: item.length,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _checkWordAnswer(),
              ),
            ),
          ),

          // Interactive Letter Boxes
          GestureDetector(
            onTap: () => _wordFocusNode.requestFocus(),
            child: Ltr(
              child: Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: List.generate(item.length, (index) {
                    final isRevealed = _revealedHintIndices.contains(index);
                    String char = '';
                    if (isRevealed) {
                      char = _revealedLetters[index] ?? '';
                    } else if (index < typedText.length) {
                      char = typedText[index];
                    }

                    final isFocused = typedText.length == index && _wordFocusNode.hasFocus;

                    Color boxBg = AppTheme.surface;
                    Color boxBorder = AppTheme.border;

                    if (_checkResult != null && index < _checkResult!.letters.length) {
                      final check = _checkResult!.letters[index];
                      if (check.isCorrect) {
                        boxBg = AppTheme.success.withOpacity(0.18);
                        boxBorder = AppTheme.success;
                      } else {
                        boxBg = AppTheme.danger.withOpacity(0.18);
                        boxBorder = AppTheme.danger;
                      }
                    } else if (isRevealed) {
                      boxBg = Colors.amber.withOpacity(0.15);
                      boxBorder = Colors.amber;
                    } else if (isFocused) {
                      boxBorder = Colors.blueAccent;
                    }

                    return Container(
                      width: 44,
                      height: 52,
                      decoration: BoxDecoration(
                        color: boxBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: boxBorder, width: isFocused || isRevealed ? 2.0 : 1.2),
                      ),
                      child: Center(
                        child: Text(
                          char.toUpperCase(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isRevealed ? Colors.amberAccent : Colors.white,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Letter Chips for touch keyboards
          if (_letterChips.isNotEmpty && !isSuccess) ...[
            const Center(
              child: Text(
                'اختر الحروف باللمس:',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final chip in _letterChips)
                    InkWell(
                      onTap: () => _onLetterChipTapped(chip),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 38,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Center(
                          child: Text(
                            chip.toUpperCase(),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  InkWell(
                    onTap: _onBackspaceTapped,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 46,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.4)),
                      ),
                      child: const Center(
                        child: Icon(Icons.backspace_outlined, size: 18, color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Feedback Result Banner
          if (_checkResult != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSuccess ? AppTheme.success.withOpacity(0.15) : AppTheme.danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSuccess ? AppTheme.success : AppTheme.danger),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? AppTheme.success : AppTheme.danger),
                      const SizedBox(width: 8),
                      Text(
                        isSuccess ? 'إجابة صحيحة! 🎉' : 'حاول مرة أخرى! باقي محاولة واحدة',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  if (isSuccess && _checkResult!.xpAwarded > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '+${_checkResult!.xpAwarded} نقطة خبرة XP (${_hintsUsed} تلميحات مستخدمة)',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Action Button
          if (!isSuccess)
            ElevatedButton(
              onPressed: _isCheckingWord || typedText.isEmpty ? null : _checkWordAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isCheckingWord
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('تحقق من الإملاء', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          else
            ElevatedButton.icon(
              onPressed: _loadNextWord,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('الكلمة التالية 👉', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  // ================= Tab 2: Sentence Dictation =================

  Widget _buildSentenceDictationTab() {
    if (_isLoadingSentence) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sentenceError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
            const SizedBox(height: 12),
            Text(_sentenceError!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadNextSentence, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    final item = _currentSentenceItem!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _playSentenceAudio(),
                icon: const Icon(Icons.volume_up),
                label: const Text('استمع للجملة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _playSentenceAudio(slow: true),
                icon: const Icon(Icons.slow_motion_video),
                label: const Text('استمع ببطء'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Arabic Meaning Hint
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                const Text('المعنى باللغة العربية:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  item.arabic,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Input field
          Ltr(
            child: TextField(
              controller: _sentenceController,
              focusNode: _sentenceFocusNode,
              maxLines: 3,
              style: const TextStyle(fontSize: 18, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Type the full English sentence here...',
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sentence Validation Word Chips
          if (_sentenceChecked) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _sentencePassed ? AppTheme.success.withOpacity(0.15) : AppTheme.danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _sentencePassed ? AppTheme.success : AppTheme.danger),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_sentencePassed ? Icons.check_circle : Icons.info_outline,
                          color: _sentencePassed ? AppTheme.success : AppTheme.danger),
                      const SizedBox(width: 8),
                      Text(
                        _sentencePassed ? 'جملة متقنة! أحسنت (+10 XP)' : 'مقارنة الكلمات المكتوبة:',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Ltr(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _sentenceWordChips.map((chip) {
                        final word = chip.$1;
                        final isOk = chip.$2;
                        final typed = chip.$3;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOk ? AppTheme.success.withOpacity(0.2) : AppTheme.danger.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isOk ? AppTheme.success : AppTheme.danger),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                word,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isOk ? AppTheme.success : AppTheme.danger,
                                ),
                              ),
                              if (!isOk && typed != null && typed.isNotEmpty)
                                Text(
                                  '($typed)',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (!_sentenceChecked)
            ElevatedButton(
              onPressed: _checkSentenceAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تحقق من الجملة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          else
            ElevatedButton.icon(
              onPressed: _loadNextSentence,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('الجملة التالية 👉', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _sentencePassed ? AppTheme.success : AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }
}
