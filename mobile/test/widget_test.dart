import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alemni_mobile/core/widgets/ltr.dart';
import 'package:alemni_mobile/main.dart';

void main() {
  testWidgets('Smoke test for AlemniApp', (WidgetTester tester) async {
    await tester.pumpWidget(const AlemniApp());
    expect(find.byType(AlemniApp), findsOneWidget);
  });

  testWidgets("Text('My name is Sara.') inside Ltr renders with TextDirection.ltr under RTL locale",
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Column(
              children: [
                Text('نص عربي RTL'),
                Ltr(
                  child: Text('My name is Sara.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify Arabic text direction is RTL
    final arabicElement = tester.element(find.text('نص عربي RTL'));
    expect(Directionality.of(arabicElement), TextDirection.rtl);

    // Verify English text inside Ltr has TextDirection.ltr
    final englishElement = tester.element(find.text('My name is Sara.'));
    expect(Directionality.of(englishElement), TextDirection.ltr);
  });

  testWidgets('Ltr widget enforces TextDirection.ltr for English content', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        home: Scaffold(
          body: Ltr(
            child: Text('Reading passage sample'),
          ),
        ),
      ),
    );

    final element = tester.element(find.text('Reading passage sample'));
    expect(Directionality.of(element), TextDirection.ltr);
  });
}
