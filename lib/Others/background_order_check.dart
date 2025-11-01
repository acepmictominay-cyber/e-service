import 'dart:convert';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_service/Others/new_order_notification_service.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:e_service/Others/session_manager.dart';
import 'package:firebase_core/firebase_core.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("🔄 Background task berjalan: $task");

    try {
      await Firebase.initializeApp();
      await initializeBackgroundNotifications();

      final technicianId = await SessionManager.getkry_kode();
      if (technicianId == null) return Future.value(true);

      final fetchedOrders = await ApiService.getkry_kode(technicianId);
      final count = fetchedOrders.length;

      // Simpan count terakhir di shared prefs
      final prefs = await SharedPreferences.getInstance();
      final previousCount = prefs.getInt('previous_order_count') ?? 0;

      if (count > previousCount) {
        print(
          "📊 Pesanan baru terdeteksi di background ($count vs $previousCount), akan dikirim notifikasi saat app aktif",
        );
      }

      // Update stored count
      await prefs.setInt('previous_order_count', count);
    } catch (e) {
      print("❌ Error di background check: $e");
    }

    return Future.value(true);
  });
}

// Initialize notification service in background isolate
Future<void> initializeBackgroundNotifications() async {
  await NewOrderNotificationService.initialize();
}
