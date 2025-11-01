import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class BirthdayNotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _birthdayNotificationKey = 'birthday_notifications_sent';

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap - could navigate to app
        print('Notification tapped: ${response.payload}');
      },
    );

    // Request permissions for iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request permissions for Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> checkAndSendBirthdayNotifications() async {
    try {
      // Get current date
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentDay = now.day;

      // Dummy data for testing - replace with API call later
      final customers = [
        {
          'id_costomer': 'TEST004',
          'cos_nama': 'Acep',
          'cos_tgl_lahir': '${now.year}-${currentMonth.toString().padLeft(2, '0')}-${currentDay.toString().padLeft(2, '0')}', // Today's date for testing
        },
       
        {
          'id_costomer': 'TEST003',
          'cos_nama': 'Bob Johnson',
          'cos_tgl_lahir': '${now.year}-${(currentMonth % 12 + 1).toString().padLeft(2, '0')}-${currentDay.toString().padLeft(2, '0')}', // Next month
        },
      ];

      // Uncomment below to use real API instead of dummy data
      /*
      final response = await http.get(
        Uri.parse('http://192.168.1.15:8000/api/costomers'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response: $data'); // Debug log
        final customers = data['data'] as List<dynamic>;
      */

        // Get already sent notifications for today
        final prefs = await SharedPreferences.getInstance();
        final sentNotifications = prefs.getStringList(_birthdayNotificationKey) ?? [];

        for (var customer in customers) {
          final cosTglLahir = customer['cos_tgl_lahir'];
          if (cosTglLahir != null && cosTglLahir.toString().isNotEmpty && cosTglLahir != '0000-00-00') {
            try {
              // Parse birth date
              final birthDate = DateTime.parse(cosTglLahir);
              final birthMonth = birthDate.month;
              final birthDay = birthDate.day;

              // Check if today is their birthday
              if (birthMonth == currentMonth && birthDay == currentDay) {
                final customerId = customer['id_costomer'].toString();
                final customerName = customer['cos_nama'] ?? 'Pelanggan';

                // Check if notification already sent today
                if (!sentNotifications.contains(customerId)) {
                  await _sendBirthdayNotification(customerName, customerId);
                  sentNotifications.add(customerId);
                  print('Birthday notification sent to $customerName (ID: $customerId)');
                }
              }
            } catch (e) {
              print('Error parsing birth date for customer ${customer['id_costomer']}: $e');
            }
          }
        }

        // Save updated sent notifications
        await prefs.setStringList(_birthdayNotificationKey, sentNotifications);

        // Clear old notifications (keep only today's)
        final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final allKeys = prefs.getKeys().where((key) => key.startsWith('birthday_notifications_')).toList();
        for (var key in allKeys) {
          if (key != _birthdayNotificationKey) {
            await prefs.remove(key);
          }
        }
      // } // Uncomment this closing brace when using real API
    } catch (e) {
      print('Error checking birthday notifications: $e');
    }
  }

  static Future<void> _sendBirthdayNotification(String customerName, String customerId) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'birthday_channel',
      'Birthday Notifications',
      channelDescription: 'Notifications for customer birthdays',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      customerId.hashCode, // Unique ID based on customer ID
      'Selamat Ulang Tahun! 🎉',
      'Halo $customerName, selamat ulang tahun! Semoga hari Anda menyenangkan.',
      platformChannelSpecifics,
      payload: 'birthday_$customerId',
    );
  }

  static Future<void> resetDailyNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_birthdayNotificationKey);
  }

  // Method to schedule daily check (call this when app starts)
  static void scheduleDailyBirthdayCheck() {
    // Check immediately
    checkAndSendBirthdayNotifications();

    // Schedule to check every hour (in production, you might want to use workmanager for more reliable scheduling)
    Timer.periodic(const Duration(hours: 1), (timer) {
      checkAndSendBirthdayNotifications();
    });
  }
}
