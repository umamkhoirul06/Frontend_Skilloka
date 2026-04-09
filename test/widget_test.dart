// Basic widget test for Skilloka App.
import 'package:flutter_test/flutter_test.dart';
import 'package:skilloka_app/main.dart';

void main() {
  testWidgets('SkillokApp renders without crashing', (WidgetTester tester) async {
    // Build app and trigger a frame.
    await tester.pumpWidget(const SkillokApp());
    // Verify the app initializes
    expect(find.byType(SkillokApp), findsOneWidget);
  });
}
