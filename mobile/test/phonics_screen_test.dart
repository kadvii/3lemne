import 'package:alemni_mobile/core/api/api_client.dart';
import 'package:alemni_mobile/core/widgets/mobile_frame.dart';
import 'package:alemni_mobile/features/phonics/mouth_diagram_painter.dart';
import 'package:alemni_mobile/features/phonics/phonics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PhonicsItemModel parses complete blueprint data properly', () {
    final json = {
      'id': 'ph-1',
      'kind': 'Letter',
      'category': 'consonants',
      'symbol': 'P vs B',
      'ipaOrSpelling': '/p/ vs /b/',
      'arabicApprox': 'حرف P انفجاري',
      'mouthTipAr': 'أغلق الشفتين تماماً',
      'mouthDiagramType': 'bilabial_p_b',
      'exampleWords': ['pen', 'pan', 'park'],
      'minimalPairs': [
        {
          'word1': 'pin',
          'word2': 'bin',
          'meaningAr1': 'دبوس',
          'meaningAr2': 'سلة مهملات',
        }
      ],
      'tongueTwister': 'Peter Piper picked a peck.',
      'tongueTwisterAr': 'بيتر بايبر التقط مكيالاً.',
    };

    final model = PhonicsItemModel.fromJson(json);
    expect(model.id, 'ph-1');
    expect(model.category, 'consonants');
    expect(model.symbol, 'P vs B');
    expect(model.mouthDiagramType, 'bilabial_p_b');
    expect(model.exampleWords.length, 3);
    expect(model.minimalPairs.length, 1);
    expect(model.minimalPairs.first.word1, 'pin');
    expect(model.minimalPairs.first.meaningAr1, 'دبوس');
    expect(model.tongueTwister, 'Peter Piper picked a peck.');
  });

  testWidgets('MouthDiagramWidget renders with label and custom painter', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MouthDiagramWidget(diagramType: 'bilabial_p_b'),
        ),
      ),
    );

    expect(find.byType(MouthDiagramWidget), findsOneWidget);
    expect(find.text('إطباق الشفتين وحبس الهواء'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('MouthDiagramWidget renders interdental diagram label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MouthDiagramWidget(diagramType: 'interdental_th'),
        ),
      ),
    );

    expect(find.text('طرف اللسان بين الأسنان'), findsOneWidget);
  });

  testWidgets('PhonicsScreen renders MobileFrame and displays phonics items with drills', (tester) async {
    final mockItem = PhonicsItemModel(
      id: 'item-1',
      kind: 'Letter',
      category: 'consonants',
      symbol: 'P vs B',
      ipaOrSpelling: '/p/ vs /b/',
      arabicApprox: 'حرف P انفجاري مهموس',
      mouthTipAr: 'أغلق الشفتين تماماً',
      mouthDiagramType: 'bilabial_p_b',
      exampleWords: ['pen', 'pan'],
      minimalPairs: [
        MinimalPairModel(
          word1: 'pin',
          word2: 'bin',
          meaningAr1: 'دبوس',
          meaningAr2: 'سلة مهملات',
        ),
      ],
      tongueTwister: 'Peter Piper picked peppers.',
      tongueTwisterAr: 'بيتر بايبر التقط فلفلاً.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PhonicsScreen(initialItems: [mockItem]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MobileFrame), findsOneWidget);
    expect(find.text('مخارج الحروف وحروف العلة'), findsOneWidget);
    expect(find.text('P vs B'), findsOneWidget);
    expect(find.text('/p/ vs /b/'), findsOneWidget);
    expect(find.text('تمرين: أي كلمة سمعت؟'), findsOneWidget);
    expect(find.text('pin'), findsWidgets);
    expect(find.text('bin'), findsWidgets);
  });
}
