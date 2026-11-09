import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tts/tts_service.dart';
import '../../core/widgets/ltr.dart';
import '../../core/widgets/mobile_frame.dart';
import 'mouth_diagram_painter.dart';

class PhonicsScreen extends StatefulWidget {
  final List<PhonicsItemModel>? initialItems;

  const PhonicsScreen({Key? key, this.initialItems}) : super(key: key);

  @override
  State<PhonicsScreen> createState() => _PhonicsScreenState();
}

class _PhonicsScreenState extends State<PhonicsScreen> {
  final TtsService _tts = TtsService();
  final TextEditingController _searchController = TextEditingController();

  List<PhonicsItemModel> _allItems = [];
  List<PhonicsItemModel> _filteredItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'all';
  bool _isSlow = false;

  // Listening Drill State: map from phonicsItemId -> DrillState
  final Map<String, _DrillState> _drills = {};

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'الكل 🌟'},
    {'id': 'consonants', 'label': 'أصوات غير موجودة 🗣️'},
    {'id': 'vowels', 'label': 'حروف العلة والحركات 🎶'},
    {'id': 'iraqi_challenges', 'label': 'التحديات العراقية 🇮🇶'},
    {'id': 'endings_stress', 'label': 'النهايات والتشديد 🎯'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialItems != null) {
      _allItems = widget.initialItems!;
      _isLoading = false;
      _applyFilter();
    } else {
      _loadPhonics();
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPhonics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await ApiClient.instance.getPhonics();
      setState(() {
        _allItems = items;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل بيانات النطق من الخادم. تأكد من اتصال الإنترنت.';
      });
    }
  }

  void _onSearchChanged() {
    _applyFilter();
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredItems = _allItems.where((item) {
        final matchesCat = _selectedCategory == 'all' || item.category.toLowerCase() == _selectedCategory;
        if (!matchesCat) return false;

        if (query.isEmpty) return true;

        final matchesSymbol = item.symbol.toLowerCase().contains(query);
        final matchesIpa = item.ipaOrSpelling.toLowerCase().contains(query);
        final matchesArabic = item.arabicApprox.toLowerCase().contains(query);
        final matchesExample = item.exampleWords.any((w) => w.toLowerCase().contains(query));

        return matchesSymbol || matchesIpa || matchesArabic || matchesExample;
      }).toList();
    });
  }

  void _speak(String text, {bool? slow}) {
    _tts.speak(text, slow: slow ?? _isSlow);
  }

  void _toggleSpeed() {
    setState(() {
      _isSlow = !_isSlow;
    });
  }

  _DrillState _getOrCreateDrill(PhonicsItemModel item) {
    if (!_drills.containsKey(item.id)) {
      _drills[item.id] = _initDrill(item);
    }
    return _drills[item.id]!;
  }

  _DrillState _initDrill(PhonicsItemModel item) {
    if (item.minimalPairs.isEmpty) {
      return _DrillState.empty();
    }
    final rand = Random();
    final pairIndex = rand.nextInt(item.minimalPairs.length);
    final pair = item.minimalPairs[pairIndex];
    final pickFirst = rand.nextBool();
    final targetWord = pickFirst ? pair.word1 : pair.word2;

    return _DrillState(
      pair: pair,
      targetWord: targetWord,
      selectedWord: null,
      isCorrect: null,
    );
  }

  void _resetDrill(PhonicsItemModel item) {
    setState(() {
      _drills[item.id] = _initDrill(item);
    });
    final drill = _drills[item.id]!;
    if (drill.targetWord.isNotEmpty) {
      _speak(drill.targetWord);
    }
  }

  void _checkDrillAnswer(PhonicsItemModel item, String selected) {
    final drill = _getOrCreateDrill(item);
    if (drill.selectedWord != null) return; // already answered

    final isCorrect = (selected.toLowerCase().trim() == drill.targetWord.toLowerCase().trim());
    setState(() {
      _drills[item.id] = drill.copyWith(
        selectedWord: selected,
        isCorrect: isCorrect,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MobileFrame(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('مخارج الحروف وحروف العلة'),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                !_isSlow ? Icons.speed : Icons.slow_motion_video,
                color: !_isSlow ? Colors.white70 : AppTheme.secondary,
              ),
              tooltip: !_isSlow ? 'سرعة عادية (1.0x)' : 'سرعة بطيئة (0.6x)',
              onPressed: _toggleSpeed,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'إعادة تحميل',
              onPressed: _loadPhonics,
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
              Icon(Icons.error_outline, size: 54, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPhonics,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildSearchAndCategories(),
        Expanded(
          child: _filteredItems.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _filteredItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return _buildPhonicsCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchAndCategories() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.only(top: 8, bottom: 12, left: 14, right: 14),
      child: Column(
        children: [
          // Search input
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث عن صوت، رمز، أو كلمة مثال...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal Categories Filter
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['id'];
                return ChoiceChip(
                  label: Text(
                    cat['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surfaceVariant,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = cat['id']!;
                      });
                      _applyFilter();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhonicsCard(PhonicsItemModel item) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Symbol, IPA, Kind Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Ltr(
                      child: Text(
                        item.symbol,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Ltr(
                      child: Text(
                        item.ipaOrSpelling,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, color: AppTheme.primary, size: 28),
                tooltip: 'استمع للرمز',
                onPressed: () {
                  final firstExample = item.exampleWords.isNotEmpty ? item.exampleWords.first : item.symbol;
                  _speak(firstExample);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Arabic Approximation
          Text(
            item.arabicApprox,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white),
          ),
          const SizedBox(height: 12),

          // Mouth Diagram (Anatomical CustomPainter)
          MouthDiagramWidget(
            diagramType: item.mouthDiagramType,
            size: 110,
          ),
          const SizedBox(height: 10),

          // Mouth Tip Arabic text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('👅 ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    item.mouthTipAr,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Example words section
          Row(
            children: [
              const Expanded(
                child: Text(
                  'كلمات تدريبية (اضغط للاستماع):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isSlow ? '0.6x' : '1.0x',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isSlow ? AppTheme.secondary : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Ltr(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: item.exampleWords.map((word) {
                return ActionChip(
                  avatar: const Icon(Icons.volume_up, size: 14, color: AppTheme.primary),
                  label: Text(
                    word,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  backgroundColor: AppTheme.surfaceVariant,
                  onPressed: () => _speak(word),
                );
              }).toList(),
            ),
          ),

          // Minimal Pairs Section
          if (item.minimalPairs.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: AppTheme.border),
            const SizedBox(height: 8),
            const Text(
              'أزواج دنيا مميزة (Minimal Pairs):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildMinimalPairsTable(item),
            const SizedBox(height: 14),

            // Interactive Listening Drill: "أي كلمة سمعت؟"
            _buildListeningDrill(item),
          ],

          // Tongue Twister Section
          if (item.tongueTwister.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildTongueTwister(item),
          ],
        ],
      ),
    );
  }

  Widget _buildMinimalPairsTable(PhonicsItemModel item) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border.withOpacity(0.4)),
      ),
      child: Column(
        children: item.minimalPairs.take(6).map((pair) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // Word 1 button
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _speak(pair.word1),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.volume_up, size: 14, color: Colors.blueAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Ltr(
                                  child: Text(
                                    pair.word1,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  pair.meaningAr1,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Text('⚡', style: TextStyle(fontSize: 13)),
                // Word 2 button
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _speak(pair.word2),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.volume_up, size: 14, color: AppTheme.secondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Ltr(
                                  child: Text(
                                    pair.word2,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  pair.meaningAr2,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListeningDrill(PhonicsItemModel item) {
    final drill = _getOrCreateDrill(item);
    if (drill.pair == null) return const SizedBox.shrink();

    final pair = drill.pair!;
    final isAnswered = drill.selectedWord != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF142033),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.hearing, size: 18, color: AppTheme.secondary),
                    SizedBox(width: 6),
                    Text(
                      'تمرين: أي كلمة سمعت؟',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, color: AppTheme.primary, size: 22),
                tooltip: 'استمع للكلمة المستهدفة',
                onPressed: () => _speak(drill.targetWord),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Choices buttons
          Row(
            children: [
              Expanded(
                child: _buildDrillChoiceButton(
                  item: item,
                  word: pair.word1,
                  meaningAr: pair.meaningAr1,
                  drill: drill,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDrillChoiceButton(
                  item: item,
                  word: pair.word2,
                  meaningAr: pair.meaningAr2,
                  drill: drill,
                ),
              ),
            ],
          ),

          // Feedback & next question
          if (isAnswered) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  drill.isCorrect == true ? Icons.check_circle : Icons.cancel,
                  color: drill.isCorrect == true ? AppTheme.success : AppTheme.error,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    drill.isCorrect == true
                        ? 'أحسنت! الإجابة صحيحة (+5 XP)'
                        : 'خطأ! الكلمة المنطوقة كانت "${drill.targetWord}"',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: drill.isCorrect == true ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _resetDrill(item),
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('تدريب آخر', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrillChoiceButton({
    required PhonicsItemModel item,
    required String word,
    required String meaningAr,
    required _DrillState drill,
  }) {
    final isSelected = (drill.selectedWord == word);
    Color buttonColor = AppTheme.surfaceVariant;
    Color textColor = Colors.white;

    if (drill.selectedWord != null) {
      if (word.toLowerCase().trim() == drill.targetWord.toLowerCase().trim()) {
        buttonColor = AppTheme.success.withOpacity(0.35);
        textColor = Colors.greenAccent;
      } else if (isSelected) {
        buttonColor = AppTheme.error.withOpacity(0.35);
        textColor = Colors.redAccent;
      }
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: buttonColor,
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border,
          width: isSelected ? 1.5 : 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: drill.selectedWord == null
          ? () {
              _checkDrillAnswer(item, word);
            }
          : () => _speak(word),
      child: Column(
        children: [
          Ltr(
            child: Text(
              word,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            meaningAr,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTongueTwister(PhonicsItemModel item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Text('🌀 ', style: TextStyle(fontSize: 15)),
                    Expanded(
                      child: Text(
                        'لسان معقّد (Tongue Twister):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, size: 18, color: Colors.amber),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'استمع للتحدي الصوتي',
                onPressed: () => _speak(item.tongueTwister),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Ltr(
            child: Text(
              item.tongueTwister,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.tongueTwisterAr,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 54, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'لم نجد نتائج مطابقة لبحثك',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedCategory = 'all';
                });
                _applyFilter();
              },
              child: const Text('إعادة ضبط التصفيات'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrillState {
  final MinimalPairModel? pair;
  final String targetWord;
  final String? selectedWord;
  final bool? isCorrect;

  _DrillState({
    required this.pair,
    required this.targetWord,
    this.selectedWord,
    this.isCorrect,
  });

  factory _DrillState.empty() {
    return _DrillState(
      pair: null,
      targetWord: '',
      selectedWord: null,
      isCorrect: null,
    );
  }

  _DrillState copyWith({
    MinimalPairModel? pair,
    String? targetWord,
    String? selectedWord,
    bool? isCorrect,
  }) {
    return _DrillState(
      pair: pair ?? this.pair,
      targetWord: targetWord ?? this.targetWord,
      selectedWord: selectedWord ?? this.selectedWord,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}
