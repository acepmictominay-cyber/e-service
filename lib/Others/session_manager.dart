import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyUserId = 'id_costomer';
  static const String _keyUserName = 'cos_nama';
  static const String _keyPoin = 'cos_poin';
  static const String _keyRole = 'role';
  static const String _keyKryKode = 'kry_kode';

  // Simpan data login
  static Future<void> saveUserSession(
    String id,
    String name,
    int poin, {
    String? role,
    String? kryKode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString(_keyUserId, id);
    await prefs.setString(_keyUserName, name);
    await prefs.setInt(_keyPoin, poin);
    
    if (role != null) {
      await prefs.setString(_keyRole, role);
      print('💾 [SESSION] Role saved: $role');
    }
    
    if (kryKode != null) {
      await prefs.setString(_keyKryKode, kryKode);
      print('💾 [SESSION] kry_kode saved: $kryKode');
    }
    
    print('✅ [SESSION] Session saved successfully');
  }

  // Ambil data login
  static Future<Map<String, dynamic>> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_keyUserId),
      'name': prefs.getString(_keyUserName),
      'poin': prefs.getInt(_keyPoin) ?? 0,
      'role': prefs.getString(_keyRole),
      'kryKode': prefs.getString(_keyKryKode),
    };
  }

  // Hapus data login (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyPoin);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyKryKode);
    await prefs.setBool('isLoggedIn', false);
    print('🗑️ [SESSION] Session cleared');
  }

  // Cek apakah sudah login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Update poin saja
  static Future<void> updateUserPoin(int poin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPoin, poin);
  }

  // Get customer ID
  static Future<String?> getCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  // Get technician ID (kry_kode)
  static Future<String?> getkry_kode() async {
    final prefs = await SharedPreferences.getInstance();
    final kryKode = prefs.getString(_keyKryKode);
    print('🔍 [SESSION] Getting kry_kode: $kryKode');
    return kryKode;
  }
}