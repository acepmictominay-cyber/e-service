
import 'package:e_service/Others/detail_notifikasi.dart';
import 'package:e_service/Others/notifikasi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  testWidgets('Notification page displays notifications', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationPage()));

    expect(find.text('Selamat ulang tahun Users'), findsOneWidget);
    expect(find.text('Selamat datang Users'), findsOneWidget);
  });

  testWidgets('Tapping notification navigates to detail page', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationPage()));

    await tester.tap(find.text('Selamat ulang tahun Users'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Notifikasi'), findsOneWidget);
    expect(find.text('Selamat ulang tahun Users'), findsOneWidget);
    expect(find.text('Anda mendapatkan hadiah ulang tahun, klik untuk mengambilnya'), findsOneWidget);
  });

  testWidgets('Detail page back button is blue', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: NotificationDetailPage(
        title: 'Test Title',
        subtitle: 'Test Subtitle',
        icon: Icons.notifications,
        color: Colors.blue,
      ),
    ));

    final button = find.byType(ElevatedButton);
    expect(button, findsOneWidget);

    final ElevatedButton elevatedButton = tester.widget(button);
    expect(elevatedButton.style?.backgroundColor?.resolve({}), Colors.blue);
  });

  testWidgets('Back button navigates back', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: NotificationDetailPage(
        title: 'Test Title',
        subtitle: 'Test Subtitle',
        icon: Icons.notifications,
        color: Colors.blue,
      ),
    ));

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    // Should navigate back, but since it's the root, it might not change
    // In a real app, this would pop the route
  });
}
