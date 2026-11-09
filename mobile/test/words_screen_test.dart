import 'package:alemni_mobile/core/api/api_client.dart';
import 'package:alemni_mobile/core/widgets/mobile_frame.dart';
import 'package:alemni_mobile/features/words/words_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SavedWordModel calculates SRS stage correctly', () {
    final now = DateTime.now();
    final day1Word = SavedWordModel(
      id: '1',
      wordId: 'w1',
      english: 'market',
      arabic: 'سوق',
      addedAt: now,
    );
    expect(day1Word.srsStageLabel, 'مراجعة Day 1');

    final day7Word = SavedWordModel(
      id: '2',
      wordId: 'w2',
      english: 'weather',
      arabic: 'طقس',
      addedAt: now.subtract(const Duration(days: 4)),
    );
    expect(day7Word.srsStageLabel, 'مراجعة Day 7');

    final masteredWord = SavedWordModel(
      id: '3',
      wordId: 'w3',
      english: 'challenge',
      arabic: 'تحدي',
      addedAt: now.subtract(const Duration(days: 20)),
    );
    expect(masteredWord.srsStageLabel, 'متقنة 🏆');
  });

  testWidgets('WordsScreen displays saved words and SRS stage badge', (tester) async {
    final mockWords = [
      SavedWordModel(
        id: '1',
        wordId: 'w1',
        english: 'breakfast',
        arabic: 'فطور',
        addedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: WordsScreen(initialWords: mockWords),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MobileFrame), findsOneWidget);
    expect(find.text('مفرداتي المحفوظة'), findsOneWidget);
    expect(find.text('breakfast'), findsOneWidget);
    expect(find.text('فطور'), findsOneWidget);
    expect(find.text('مراجعة Day 1'), findsOneWidget);
  });

  testWidgets('WordsScreen toggles Flashcard SRS mode', (tester) async {
    final mockWords = [
      SavedWordModel(
        id: '1',
        wordId: 'w1',
        english: 'consequence',
        arabic: 'عاقبة / نتيجة',
        addedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: WordsScreen(initialWords: mockWords),
      ),
    );
    await tester.pumpAndSettle();

    // Tap review mode icon
    final reviewButton = find.byIcon(Icons.style_outlined);
    expect(reviewButton, findsOneWidget);
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();

    expect(find.text('مراجعة البطاقات الذكية (SRS)'), findsOneWidget);
    expect(find.text('consequence'), findsOneWidget);
    expect(find.text('اكشف المعنى'), findsOneWidget);

    // Tap reveal
    await tester.tap(find.text('اكشف المعنى'));
    await tester.pumpAndSettle();

    expect(find.text('عاقبة / نتيجة'), findsOneWidget);
    expect(find.text('تذكرتها ✅'), findsOneWidget);
    expect(find.text('نسيتها ❌'), findsOneWidget);
  });
}
