import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alemni_mobile/core/theme/app_theme.dart';
import 'package:alemni_mobile/features/home/home_screen.dart';

void main() {
  const testSizes = [
    Size(360, 800),  // Standard Android
    Size(390, 844),  // iPhone 13/14/15
    Size(412, 915),  // Pixel 7 / Galaxy
    Size(1920, 1080), // Desktop / Wide Web
  ];

  for (final size in testSizes) {
    testWidgets('HomeScreen renders cleanly without overflow on ${size.width.toInt()}x${size.height.toInt()}',
        (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('ar'),
          home: const HomeScreen(),
          builder: (context, child) {
            return Container(
              color: const Color(0xFF090D16),
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: child ?? const SizedBox(),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Expect no RenderFlex overflows
      expect(tester.takeException(), isNull);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  }
}

