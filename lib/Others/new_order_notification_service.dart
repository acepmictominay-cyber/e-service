import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewOrderNotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _newOrderNotificationKey = 'new_order_notifications_sent';
  static const String baseUrl = 'http://192.168.1.6:8000/api';

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
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

    // Request permissions for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    print('✅ [NOTIF] Notification service initialized');
  }

  static Future<void> checkAndSendNewOrderNotifications() async {
    try {
      print('🔍 [NOTIF] Checking for new orders...');

      final prefs = await SharedPreferences.getInstance();
      final kryKode = prefs.getString('kry_kode');
      
      if (kryKode == null || kryKode.isEmpty) {
        print('⚠️ [NOTIF] kry_kode not found, skipping check');
        return;
      }

      print('👤 [NOTIF] Checking orders for: $kryKode');

      final response = await http.get(
        Uri.parse('$baseUrl/transaksi'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('❌ [NOTIF] API Error: ${response.statusCode}');
        return;
      }

      final List<dynamic> allTransaksi = json.decode(response.body);
      print('📊 [NOTIF] Total transaksi: ${allTransaksi.length}');

      final orders = allTransaksi.where((item) {
        final isForThisTechnician = item['kry_kode'] == kryKode;
        final isWaiting = item['trans_status']?.toString().toLowerCase() == 'waiting';
        return isForThisTechnician && isWaiting;
      }).toList();

      print('📦 [NOTIF] Orders for $kryKode with status waiting: ${orders.length}');

      final sentNotifications = prefs.getStringList(_newOrderNotificationKey) ?? [];

      int newOrderCount = 0;
      List<String> newOrderIds = [];

      for (var order in orders) {
        final orderId = order['trans_kode']?.toString() ?? '';
        
        if (orderId.isEmpty) continue;

        if (!sentNotifications.contains(orderId)) {
          newOrderIds.add(orderId);
          newOrderCount++;
          print('📦 [NOTIF] New order: $orderId');
        }
      }

      if (newOrderIds.isNotEmpty) {
        for (var orderId in newOrderIds) {
          final orderDetail = orders.firstWhere(
            (o) => o['trans_kode'] == orderId,
            orElse: () => {},
          );
          
          final customerName = orderDetail['cos_nama'] ?? 'Customer';
          
          await _sendNewOrderNotification(
            newOrderCount,
            orderId,
            customerName,
          );

          sentNotifications.add(orderId);
          print('✅ [NOTIF] Notification sent: $orderId');
        }

        await prefs.setStringList(_newOrderNotificationKey, sentNotifications);
        print('💾 [NOTIF] Saved ${newOrderIds.length} order IDs');
      } else {
        print('ℹ️ [NOTIF] No new orders');
      }
    } catch (e) {
      print('❌ [NOTIF] Error: $e');
    }
  }

  static Future<void> _sendNewOrderNotification(
    int count,
    String orderId,
    String customerName,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'new_order_channel',
      'Pesanan Baru',
      channelDescription: 'Notifikasi pesanan baru untuk teknisi',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final title = count == 1 
        ? '📦 Ada pesanan baru!' 
        : '📦 Ada $count pesanan baru!';
    final body = 'Pesanan dari $customerName (ID: $orderId)';

    await flutterLocalNotificationsPlugin.show(
      orderId.hashCode,
      title,
      body,
      platformChannelSpecifics,
      payload: 'new_order_$orderId',
    );

    print('📬 [NOTIF] Displayed: $title - $body');
  }

  static Future<void> sendNewOrderNotification(
    int count,
    List<String> orderIds,
  ) async {
    try {
      for (var orderId in orderIds) {
        await _sendNewOrderNotification(count, orderId, 'Customer');
      }
    } catch (e) {
      print('❌ [NOTIF] Manual send error: $e');
    }
  }

  static Future<void> resetDailyNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_newOrderNotificationKey);
    print('🗑️ [NOTIF] Notifications reset');
  }

  static Future<void> testNotification() async {
    await _sendNewOrderNotification(
      1,
      'TEST_${DateTime.now().millisecondsSinceEpoch}',
      'Test Customer',
    );
  }
}