import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azza_service/Service/tracking_driver.dart';

void main() {
  group('TrackingPage Widget Tests', () {
    testWidgets('Widget builds without crashing', (WidgetTester tester) async {
      // Build the TrackingPage widget
      await tester.pumpWidget(
        const MaterialApp(
          home: TrackingPage(queueCode: 'TEST123'),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify that the widget builds successfully
      expect(find.byType(TrackingPage), findsOneWidget);

      // Verify that the queueCode is set correctly
      final trackingPage = tester.widget<TrackingPage>(find.byType(TrackingPage));
      expect(trackingPage.queueCode, 'TEST123');
    });

    testWidgets('App bar displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TrackingPage(queueCode: 'TEST123'),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar is present
      expect(find.byType(AppBar), findsOneWidget);

      // Verify support and chat buttons are present
      expect(find.byIcon(Icons.support_agent), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('Bottom navigation bar is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TrackingPage(queueCode: 'TEST123'),
        ),
      );

      await tester.pumpAndSettle();

      // Verify bottom navigation bar is present
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Verify navigation items
      expect(find.text('Service'), findsOneWidget);
      expect(find.text('Beli'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Promo'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Map placeholder shows when not active', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TrackingPage(queueCode: 'TEST123'),
        ),
      );

      await tester.pumpAndSettle();

      // When status is 'waiting' (default), map should show placeholder
      expect(find.text('Map akan muncul saat teknisi dalam perjalanan'), findsOneWidget);
    });

    testWidgets('Timeline section header displays', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TrackingPage(queueCode: 'TEST123'),
        ),
      );

      await tester.pumpAndSettle();

      // Verify timeline section header is present
      expect(find.text('Riwayat Status'), findsOneWidget);
    });

    testWidgets('Timeline shows default message when no data', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TrackingPage(queueCode: 'TEST123'),
        ),
      );

      await tester.pumpAndSettle();

      // Should show default message when timeline is empty
      expect(find.text('Belum ada pembaruan status.'), findsOneWidget);
    });
  });
}
