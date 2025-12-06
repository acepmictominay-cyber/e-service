import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:azza_service/config/api_config.dart';

class BirthdayNotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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
      },
    );

    // Request permissions for iOS
    final iOSPermissions = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    // Request permissions for Android
    final androidPermission = await flutterLocalNotificationsPlugin
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
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Use real API to get customer data
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/costomers'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final customers = data['data'] as List<dynamic>;

        // Get already sent notifications for today
        final prefs = await SharedPreferences.getInstance();
        final sentNotifications = prefs.getStringList(todayKey) ?? [];

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
                }
              }
            } catch (e) {
              // Handle parsing error silently
            }
          }
        }

        // Save updated sent notifications
        await prefs.setStringList(todayKey, sentNotifications);
      }
    } catch (e) {
      // Handle error silently
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
    final allKeys = prefs.getKeys().where((key) => key.startsWith('birthday_notifications_sent_')).toList();
    for (var key in allKeys) {
      await prefs.remove(key);
    }
  }

  // Method to schedule daily check (call this when app starts)
  static void scheduleDailyBirthdayCheck() {
    // Check immediately
    checkAndSendBirthdayNotifications();

    // Schedule to check every hour (in production, you might want to use workmanager for more reliable scheduling)
    // Note: This timer will only run when app is active. Background notifications are handled by BackgroundServiceManager
    Timer.periodic(const Duration(hours: 1), (timer) {
      checkAndSendBirthdayNotifications();
    });
  }

  // Method to check if background service is available (for Android)
  static bool get isBackgroundServiceAvailable {
    // Background service is available on Android via WorkManager
    return true; // Assume available for now
  }
}
