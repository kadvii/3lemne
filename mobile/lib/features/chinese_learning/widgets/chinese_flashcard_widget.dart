import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/tts/tts_service.dart';
import '../models/chinese_word.dart';

class ChineseFlashcardWidget extends StatefulWidget {
  final ChineseWord word;
  final VoidCallback? onFlipped;

  const ChineseFlashcardWidget({
    super.key,
    required this.word,
    this.onFlipped,
  });

  @override
  State<ChineseFlashcardWidget> createState() => ChineseFlashcardWidgetState();
}

class ChineseFlashcardWidgetState extends State<ChineseFlashcardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final TtsService _tts = TtsService();
  bool _isFront = true;

  bool get isFront => _isFront;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant ChineseFlashcardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to front side when changing words
    if (oldWidget.word.id != widget.word.id) {
      if (!_isFront) {
        _controller.reset();
        _isFront = true;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Toggles flip between front (Hanzi) and back (Arabic)
  void flip() {
    if (_isFront) {
      _controller.forward();
      _isFront = false;
    } else {
      _controller.reverse();
      _isFront = true;
    }
    widget.onFlipped?.call();
  }

  void _speak() {
    _tts.speakChinese(widget.word.hanzi);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final angle = _animation.value * math.pi;
            final isUnder = angle >= (math.pi / 2);

            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015) // 3D perspective depth
                ..rotateY(angle),
              alignment: Alignment.center,
              child: isUnder
                  ? Transform(
                      transform: Matrix4.identity()..rotateY(math.pi),
                      alignment: Alignment.center,
                      child: _buildBackCard(),
                    )
                  : _buildFrontCard(),
            );
          },
        ),
      ),
    );
  }

  /// Front of Card: Hanzi, Pinyin & Speaker
  Widget _buildFrontCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 380, maxHeight: 440),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2433),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE11D48).withValues(alpha: 0.35),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF281822),
            Color(0xFF1A2233),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top row: Language badge & Audio button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🇨🇳', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'HSK 1 • ${widget.word.level}',
                      style: const TextStyle(
                        color: Color(0xFFFDA4AF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: Color(0xFFFBBF24),
                  size: 30,
                ),
                tooltip: 'استمع للنطق الصوتي',
                onPressed: _speak,
              ),
            ],
          ),

          // Center: Large Hanzi & Pinyin (Strict LTR)
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.word.hanzi,
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                        height: 1.1,
                      ),
                    ),
                  ),
                  if (widget.word.pinyin != null &&
                      widget.word.pinyin!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.word.pinyin!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFBBF24), // Amber gold
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 16,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                'المس البطاقة لمعرفة المعنى بالعربية',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Back of Card: Arabic meaning (RTL) & English reference (LTR)
  Widget _buildBackCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 380, maxHeight: 440),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2433),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF132238),
            Color(0xFF1E293B),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top row: Back badge & Audio button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🇸🇦', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6),
                    Text(
                      'المعنى والترجمة',
                      style: TextStyle(
                        color: Color(0xFFBAE6FD),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: Color(0xFF38BDF8),
                  size: 30,
                ),
                tooltip: 'استمع للنطق مجدداً',
                onPressed: _speak,
              ),
            ],
          ),

          // Center: Arabic translation & English reference
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Arabic meaning (RTL)
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    widget.word.arabic,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),

                if (widget.word.english != null &&
                    widget.word.english!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.word.english!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.replay_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                'المس للعودة إلى الرمز الصيني (Hanzi)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
