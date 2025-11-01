import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:e_service/models/technician_order_model.dart';

class ApiService {
  // Ganti dengan alamat server Laravel kamu
  static const String baseUrl = 'http://192.168.1.6:8000/api';

  //Customer
  static Future<List<dynamic>> getCostomers() async {
    final response = await http.get(Uri.parse('$baseUrl/costomers'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data costomer');
    }
  }

  static Future<Map<String, dynamic>> getCostomerById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/costomers/$id'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Gagal mengambil data costomer');
    }
  }

  static Future<void> addCostomer(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/costomers'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal menambahkan costomer');
    }
  }

  static Future<Map<String, String>> uploadProfile(File file) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload-profile'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      final resBody = await response.stream.bytesToString();
      final data = json.decode(resBody);
      return {'url': data['url'], 'path': data['path']};
    } else {
      throw Exception('Gagal upload foto profil');
    }
  }

  static Future<void> updateCostomer(
    String id,
    Map<String, dynamic> data,
  ) async {
    var uri = Uri.parse('$baseUrl/costomers/$id');

    var response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'_method': 'PUT', ...data}),
    );

    if (response.statusCode != 200) {
      print('Gagal update: ${response.body}');
      throw Exception('Gagal memperbarui profil');
    }
  }

  static Future<void> deleteCostomer(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/costomers/$id'));

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus costomer');
    }
  }

  //Produk
  static Future<List<dynamic>> getProduk() async {
    final response = await http.get(Uri.parse('$baseUrl/produk'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data produk');
    }
  }

  static Future<List<dynamic>> getPromo() async {
    final response = await http.get(Uri.parse('$baseUrl/promo'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data promo');
    }
  }

  //AUTH
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data.containsKey('role')) {
        return data;
      } else {
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Login berhasil',
          'user': data['user'],
          'role': 'customer',
        };
      }
    } else if (response.statusCode == 401) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal login');
    }
  }

  static Future<Map<String, dynamic>> registerUser(
    String name,
    String username,
    String password,
    String nohp,
    String tglLahir,
  ) async {
    String formattedNohp =
        nohp.startsWith('0') ? '62${nohp.substring(1)}' : nohp;

    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'cos_nama': name,
        'username': username,
        'password': password,
        'cos_hp': formattedNohp,
        'cos_tgl_lahir': tglLahir,
      }),
    );

    return json.decode(response.body);
  }

  //Transaksi
  static Future<Map<String, dynamic>> createTransaksi(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transaksi'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal membuat transaksi: ${response.body}');
    }
  }

  // ✅ GET technician orders by kry_kode - UPDATED WITH DEBUG LOGS
  static Future<List<TechnicianOrder>> getkry_kode(String kryKode) async {
    print('🔍 [API] Fetching orders for kry_kode: $kryKode');

    final response = await http.get(Uri.parse('$baseUrl/transaksi'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('📊 [API] Total transaksi from server: ${data.length}');

      // Debug: Print semua kry_kode yang ada
      final allKryCodes = data.map((item) => item['kry_kode']).toSet();
      print('📋 [API] All kry_kode in database: $allKryCodes');

      final filteredData =
          data.where((item) {
            final itemKryKode = item['kry_kode']?.toString();
            final match = itemKryKode == kryKode;

            if (match) {
              print(
                '✅ [API] Match found - trans_kode: ${item['trans_kode']}, kry_kode: $itemKryKode, status: ${item['trans_status']}',
              );
            }

            return match;
          }).toList();

      print('📦 [API] Filtered orders for $kryKode: ${filteredData.length}');

      if (filteredData.isEmpty) {
        print('⚠️ [API] No orders found for kry_kode: $kryKode');
        print('   Make sure:');
        print('   1. Database has transaksi with kry_kode = "$kryKode"');
        print('   2. kry_kode is exact match (case-sensitive)');
        return [];
      }

      // Fetch customer data for each transaction
      final List<TechnicianOrder> orders = [];
      for (var item in filteredData) {
        print('🔄 [API] Processing transaction: ${item['trans_kode']}');

        final cosKode = item['cos_kode'];
        if (cosKode != null && cosKode.toString().isNotEmpty) {
          try {
            print('   Fetching customer data for cos_kode: $cosKode');
            final customerResponse = await http.get(
              Uri.parse('$baseUrl/costomers/$cosKode'),
            );

            if (customerResponse.statusCode == 200) {
              final customerData = json.decode(customerResponse.body);
              // Merge customer data into transaction data
              item['cos_nama'] = customerData['cos_nama'];
              item['cos_alamat'] = customerData['cos_alamat'];
              item['cos_hp'] = customerData['cos_hp'];

              print('   ✅ Customer data merged: ${customerData['cos_nama']}');
            } else {
              print(
                '   ⚠️ Customer API returned ${customerResponse.statusCode} for $cosKode',
              );
            }
          } catch (e) {
            print('   ❌ Failed to fetch customer $cosKode: $e');
          }
        } else {
          print('   ⚠️ No cos_kode in transaction ${item['trans_kode']}');
        }

        try {
          final order = TechnicianOrder.fromMap(item);
          orders.add(order);
          print(
            '   ✅ Order object created: ${order.orderId}, status: ${order.status.name}',
          );
        } catch (e) {
          print('   ❌ Failed to create TechnicianOrder: $e');
          print('   Item data: $item');
        }
      }

      print('🎯 [API] Successfully created ${orders.length} order objects');
      return orders;
    } else {
      print('❌ [API] HTTP Error: ${response.statusCode}');
      print('   Response: ${response.body}');
      throw Exception('Gagal memuat data pesanan teknisi');
    }
  }

  // GET semua transaksi
  static Future<List<dynamic>> getTransaksi() async {
    final response = await http.get(Uri.parse('$baseUrl/transaksi'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data transaksi');
    }
  }

  // UPDATE status transaksi
  static Future<Map<String, dynamic>> updateTransaksiStatus(
    String transKode,
    String status,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transaksi/$transKode'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'_method': 'PUT', 'trans_status': status}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal update status transaksi: ${response.body}');
    }
  }

  // UPDATE ket_keluhan + trans_total (Temuan Kerusakan)
  static Future<Map<String, dynamic>> updateTransaksiTemuan(
    String transKode,
    String ketKeluhan,
    num transTotal, {
    String? alsoSetStatus,
  }) async {
    final uri = Uri.parse('$baseUrl/transaksi/$transKode');
    final payload = {
      '_method': 'PUT',
      'ket_keluhan': ketKeluhan,
      'trans_total': transTotal,
      if (alsoSetStatus != null) 'trans_status': alsoSetStatus,
    };

    print('[ApiService.updateTransaksiTemuan] PUT $uri');
    print('  payload: $payload');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    print('[ApiService.updateTransaksiTemuan] status: ${res.statusCode}');
    print('[ApiService.updateTransaksiTemuan] body  : ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body);
      return data is Map<String, dynamic> ? data : {'data': data};
    } else {
      throw Exception('Gagal simpan temuan transaksi: ${res.body}');
    }
  }

  // DRIVER LOCATION TRACKING
  static Future<Map<String, dynamic>> updateDriverLocation(
    String transKode,
    String kryKode,
    double latitude,
    double longitude,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/driver_location/update.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'trans_kode': transKode,
        'kry_kode': kryKode,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal update lokasi driver: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getDriverLocation(
    String transKode,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/driver_location/get.php?trans_kode=$transKode'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal ambil lokasi driver: ${response.body}');
    }
  }
}
