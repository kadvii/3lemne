import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/mobile_frame.dart';
import 'models/chinese_word.dart';
import 'widgets/chinese_flashcard_widget.dart';

class ChineseLearningScreen extends ConsumerStatefulWidget {
  const ChineseLearningScreen({super.key});

  @override
  ConsumerState<ChineseLearningScreen> createState() =>
      _ChineseLearningScreenState();
}

class _ChineseLearningScreenState extends ConsumerState<ChineseLearningScreen> {
  final PageController _pageController = PageController();
  final Map<int, GlobalKey<ChineseFlashcardWidgetState>> _cardKeys = {};

  List<ChineseWord> _words = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchWords();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchWords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rawList = await ApiClient.instance.getWords(languageCode: 'zh');
      final words = rawList
          .map((item) => ChineseWord.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _words = words;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر الاتصال بالسيرفر لجلب كلمات الصينية: $e';
        _isLoading = false;
      });
    }
  }

  void _flipCurrentCard() {
    _cardKeys[_currentIndex]?.currentState?.flip();
  }

  void _nextCard() {
    if (_currentIndex < _words.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🇨🇳', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text(
              'تعلم الصينية (HSK 1)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث الكلمات',
            onPressed: _fetchWords,
          ),
        ],
      ),
      body: MobileFrame(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFE11D48),
            ),
            const SizedBox(height: 18),
            Text(
              'جاري تحميل مفردات HSK 1 الصينية...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Color(0xFFE11D48),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                ),
                onPressed: _fetchWords,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_words.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد كلمات صينية متاحة حالياً.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    final currentWord = _words[_currentIndex];
    final progress = (_currentIndex + 1) / _words.length;

    return Column(
      children: [
        // Top Progress header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'البطاقة ${_currentIndex + 1} من ${_words.length}',
                    style: const TextStyle(
                      color: Color(0xFFFDA4AF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'المستوى: ${currentWord.level}',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFF1E293B),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFE11D48),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Center Flashcard Swiper
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _words.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final key = _cardKeys.putIfAbsent(
                index,
                () => GlobalKey<ChineseFlashcardWidgetState>(),
              );

              return ChineseFlashcardWidget(
                key: key,
                word: _words[index],
              );
            },
          ),
        ),

        // Bottom Controls
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Row(
            children: [
              // Previous Button
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  padding: const EdgeInsets.all(14),
                ),
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded, // Under RTL this points back
                  size: 20,
                  color: Colors.white70,
                ),
                tooltip: 'البطاقة السابقة',
                onPressed: _currentIndex > 0 ? _prevCard : null,
              ),

              const SizedBox(width: 12),

              // Flip Card Button
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  onPressed: _flipCurrentCard,
                  icon: const Icon(Icons.flip_rounded, size: 22),
                  label: const Text(
                    'اقلب البطاقة ↺',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Next Button
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  padding: const EdgeInsets.all(14),
                ),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded, // Under RTL this points next
                  size: 20,
                  color: Colors.white70,
                ),
                tooltip: 'البطاقة التالية',
                onPressed:
                    _currentIndex < _words.length - 1 ? _nextCard : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
