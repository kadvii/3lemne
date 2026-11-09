import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alemni_mobile/core/api/api_client.dart';
import 'package:alemni_mobile/core/widgets/ltr.dart';

void main() {
  test('ReadingStoryModel parses blueprint fields correctly', () {
    final json = {
      'id': 'story-123',
      'title': 'The Lost Cat in Baghdad',
      'titleAr': 'القطة الضائعة في بغداد',
      'level': 'A1',
      'genre': 'everyday',
      'emoji': '🐈',
      'setting': 'Baghdad neighborhood',
      'wordCount': 100,
      'estimatedMinutes': 1,
      'sentences': [
        {
          'orderIndex': 1,
          'paragraphIndex': 0,
          'english': 'Zainab lives in Baghdad.',
          'arabic': '',
        }
      ],
      'questions': [
        {
          'id': 'q1',
          'type': 'detail',
          'questionAr': 'أين تعيش زينب؟',
          'questionEn': 'Where does Zainab live?',
          'options': ['Baghdad', 'Basra', 'Mosul', 'Erbil'],
          'evidenceSentenceIndex': 1,
          'explanationAr': 'مذكور في الجملة الأولى.',
          'factId': 'f1',
        }
      ],
    };

    final model = ReadingStoryModel.fromJson(json);
    expect(model.id, 'story-123');
    expect(model.title, 'The Lost Cat in Baghdad');
    expect(model.genre, 'everyday');
    expect(model.emoji, '🐈');
    expect(model.setting, 'Baghdad neighborhood');
    expect(model.sentences.length, 1);
    expect(model.questions.length, 1);
    expect(model.questions.first.factId, 'f1');
    expect(model.questions.first.evidenceSentenceIndex, 1);
  });

  testWidgets('Story sentence inside Ltr retains TextDirection.ltr', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Ltr(
              child: Text('Zainab has a lovely white cat named Mimi.'),
            ),
          ),
        ),
      ),
    );

    final textFinder = find.text('Zainab has a lovely white cat named Mimi.');
    expect(textFinder, findsOneWidget);

    final element = tester.element(textFinder);
    expect(Directionality.of(element), TextDirection.ltr);
  });
}
