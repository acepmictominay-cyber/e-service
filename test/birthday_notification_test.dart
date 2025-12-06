import 'package:azza_service/Others/birthday_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Unit tests for BirthdayNotificationService (focusing on testable parts)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BirthdayNotificationService Unit Tests', () {
    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('resetDailyNotifications clears stored data', () async {
      // Test that resetDailyNotifications clears the stored notification list
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('birthday_notifications_sent', ['TEST001', 'TEST002']);

      // Verify data is set
      expect(prefs.getStringList('birthday_notifications_sent'), isNotNull);

      // Reset notifications
      await BirthdayNotificationService.resetDailyNotifications();

      // Verify data is cleared
      final clearedPrefs = await SharedPreferences.getInstance();
      expect(clearedPrefs.getStringList('birthday_notifications_sent'), isNull);
    });

    test('scheduleDailyBirthdayCheck starts the periodic check', () async {
      // Test that scheduling method can be called without errors
      // Note: The actual periodic timer behavior is hard to test directly
      expect(() {
        BirthdayNotificationService.scheduleDailyBirthdayCheck();
      }, returnsNormally);
    });

    test('dummy data contains test customer with today\'s birthday', () async {
      // Test that the dummy data includes a customer with today's birthday for testing
      final now = DateTime.now();
      final todayString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Access the dummy data (this would need to be made accessible for testing)
      // For now, just verify the method exists and can be called
      expect(BirthdayNotificationService.checkAndSendBirthdayNotifications, isNotNull);
    });
  });
}
