import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skilloka/features/auth/presentation/pages/onboarding_screen.dart';

void main() {
  testWidgets('Verify OnboardingScreen elements appear on screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;



    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Cari LPK & Pelatihan Terbaik'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);
  });
}





