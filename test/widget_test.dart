// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:e_service/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Splash screen animation test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Wait for the 2 second delay
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify that we navigate to login screen
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
