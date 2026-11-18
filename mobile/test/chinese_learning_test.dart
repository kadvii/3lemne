import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alemni_mobile/features/chinese_learning/models/chinese_word.dart';
import 'package:alemni_mobile/features/chinese_learning/widgets/chinese_flashcard_widget.dart';

void main() {
  group('Chinese Learning Feature Tests', () {
    test('ChineseWord model parses backend payload properly', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'word': '你好',
        'pinyin': 'nǐ hǎo',
        'arabic': 'مرحباً',
        'englishMeaning': 'hello',
        'level': 'A1',
        'languageCode': 'zh',
      };

      final word = ChineseWord.fromJson(json);

      expect(word.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(word.hanzi, '你好');
      expect(word.pinyin, 'nǐ hǎo');
      expect(word.arabic, 'مرحباً');
      expect(word.english, 'hello');
      expect(word.level, 'A1');
    });

    testWidgets('ChineseFlashcardWidget renders Hanzi & Pinyin and flips to Arabic',
        (tester) async {
      const word = ChineseWord(
        id: '1',
        hanzi: '谢谢',
        pinyin: 'xiè xie',
        arabic: 'شكراً',
        english: 'thank you',
        level: 'A1',
      );

      final key = GlobalKey<ChineseFlashcardWidgetState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChineseFlashcardWidget(
              key: key,
              word: word,
            ),
          ),
        ),
      );

      // Verify Front Side elements
      expect(find.text('谢谢'), findsOneWidget);
      expect(find.text('xiè xie'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

      // Trigger 3D flip
      key.currentState?.flip();
      await tester.pumpAndSettle();

      // Verify Back Side elements
      expect(find.text('شكراً'), findsOneWidget);
      expect(find.text('thank you'), findsOneWidget);
      expect(find.text('المعنى والترجمة'), findsOneWidget);
    });
  });
}
