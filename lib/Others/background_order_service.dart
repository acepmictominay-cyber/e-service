import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:azza_service/config/api_config.dart';

// Constants for background service
const String _backgroundTaskKey = 'background_order_check';
const String _lastOrderIdsKey = 'background_last_order_ids';

class BackgroundOrderService {
  /// Initialize WorkManager for background order checking
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to false in production
    );

    // Register periodic task (minimum 15 minutes on Android, but we'll use 1 minute)
    await Workmanager().registerPeriodicTask(
      _backgroundTaskKey,
      _backgroundTaskKey,
      frequency: const Duration(minutes: 1), // Check every 1 minute
      initialDelay: const Duration(seconds: 10),
      constraints: Constraints(
        networkType: NetworkType.connected, // Only when network is available
      ),
    );
  }

  /// Stop background checking
  static Future<void> stop() async {
    await Workmanager().cancelByUniqueName(_backgroundTaskKey);
  }
}

/// Callback dispatcher for WorkManager (must be top-level function)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize background isolate
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize local notifications for background
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      final FlutterLocalNotificationsPlugin localNotifications =
          FlutterLocalNotificationsPlugin();
      await localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

      // Check for new orders
      await _checkForNewOrders(localNotifications);

      return true;
    } catch (e) {
      return false;
    }
  });
}

Future<void> _checkForNewOrders(
    FlutterLocalNotificationsPlugin localNotifications) async {
  try {
    // Get stored technician kry_kode
    final prefs = await SharedPreferences.getInstance();
    final kryKode = prefs.getString('kry_kode');

    if (kryKode == null || kryKode.isEmpty) {
      return;
    }

    // Fetch orders from API
    final response = await http.get(
      Uri.parse('${ApiConfig.apiBaseUrl}/transaksi'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      return;
    }

    final List<dynamic> allTransaksi = json.decode(response.body);

    // Filter orders for this technician with status 'waiting'
    final orders = allTransaksi.where((item) {
      final isForThisTechnician = item['kry_kode'] == kryKode;
      final isWaiting =
          item['trans_status']?.toString().toLowerCase() == 'waiting';
      return isForThisTechnician && isWaiting;
    }).toList();

    // Get previously seen order IDs
    final lastOrderIds = prefs.getStringList(_lastOrderIdsKey) ?? [];

    // Find new orders
    final newOrders = orders.where((order) {
      final orderId = order['trans_kode']?.toString();
      return orderId != null && !lastOrderIds.contains(orderId);
    }).toList();

    if (newOrders.isNotEmpty) {
      // Show notification for new orders
      await _showNewOrderNotification(
          localNotifications, newOrders.length, newOrders.first);

      // Update stored order IDs
      final currentOrderIds = orders
          .map((o) => o['trans_kode']?.toString())
          .where((id) => id != null)
          .toList();
      await prefs.setStringList(
          _lastOrderIdsKey, currentOrderIds.cast<String>());
    }
  } catch (e) {
    // Handle error silently
  }
}

Future<void> _showNewOrderNotification(
    FlutterLocalNotificationsPlugin localNotifications,
    int count,
    dynamic order) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'background_order_channel',
    'Pesanan Baru (Background)',
    channelDescription: 'Notifikasi pesanan baru dari background check',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    playSound: true,
  );

  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails();

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  final customerName = order['cos_nama'] ?? 'Customer';
  final orderId = order['trans_kode'] ?? 'Unknown';

  final title = count == 1 ? '📦 Pesanan Baru!' : '📦 $count Pesanan Baru!';
  final body = 'Pesanan dari $customerName (ID: $orderId)';

  await localNotifications.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: title,
    body: body,
    notificationDetails: platformChannelSpecifics,
    payload: 'background_new_order_$orderId',
  );
}
