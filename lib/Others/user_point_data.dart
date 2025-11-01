import 'package:e_service/Others/session_manager.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:flutter/foundation.dart';

class UserPointData {
  static ValueNotifier<int> userPoints = ValueNotifier<int>(0);

  static void addPoints(int points) {
    userPoints.value += points;
  }

  static void setPoints(int points) {
    userPoints.value = points;
  }

  static int get currentPoints => userPoints.value;

  /// 🔹 Fungsi baru: Ambil poin user dari backend Laravel berdasarkan session
  static Future<void> loadUserPoints() async {
    try {
      final session = await SessionManager.getUserSession();
      final id = session['id'];

      if (id != null) {
        final data = await ApiService.getCostomerById(id);
        if (data != null && data['cos_poin'] != null) {
          // Ubah ke int dan update ValueNotifier
          userPoints.value = int.tryParse(data['cos_poin'].toString()) ?? 0;
          debugPrint("Poin user berhasil dimuat: ${userPoints.value}");
        } else {
          debugPrint("Data poin tidak ditemukan di response API");
        }
      } else {
        debugPrint("ID user tidak ditemukan di session");
      }
    } catch (e) {
      // Removed error log
    }
  }
}
