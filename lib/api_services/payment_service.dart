import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class PaymentService {
  static const String baseUrl = 'http://192.168.1.6:8000/api';
  static const String midtransClientKey = 'Mid-client-yKTO-_jT2d60u3M1';

  /// 🔹 Buat transaksi ke backend
  static Future<Map<String, dynamic>> createPayment({
    required String customerId,
    required int amount,
    String? kodeBarang,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? orderId,
    List<Map<String, dynamic>>? itemDetails,
  }) async {
    final url = Uri.parse('$baseUrl/payment/charge');

    try {
      final requestBody = {
        'id_costomer': customerId,
        'amount': amount,
        'kode_barang': kodeBarang ?? '34GM',
        // Tambahkan data lengkap untuk Midtrans transaction
        'transaction_details': {
          'order_id': orderId ?? 'order_${DateTime.now().millisecondsSinceEpoch}',
          'gross_amount': amount,
        },
        'customer_details': {
          'first_name': customerName ?? 'Customer',
          'email': customerEmail ?? 'customer@example.com',
          'phone': customerPhone ?? '08123456789',
        },
        'item_details': itemDetails ?? [
          {
            'id': kodeBarang ?? '34GM',
            'price': amount,
            'quantity': 1,
            'name': 'Service Repair',
          }
        ],
      };

      print('Payment request to: $url');
      print('Request body: $requestBody');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal membuat pembayaran');
      }
    } catch (e) {
      print('Full error in createPayment: $e');
      throw Exception('Error creating payment: $e');
    }
  }

  /// 🔹 Jalankan UI pembayaran Midtrans menggunakan redirect_url
  static Future<void> startMidtransPayment({
    required BuildContext context,
    required String orderId,
    required int amount,
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    List<Map<String, dynamic>>? itemDetails,
    required Function(String) onTransactionFinished,
  }) async {
    try {
      // Dapatkan redirect_url dari backend
      final paymentData = await createPayment(
        customerId: customerId,
        amount: amount,
        orderId: orderId,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        itemDetails: itemDetails,
      );

      if (!paymentData.containsKey('redirect_url')) {
        throw Exception('Backend tidak mengembalikan redirect_url');
      }

      final redirectUrl = paymentData['redirect_url'];

      // Buka URL menggunakan url_launcher
      if (await canLaunchUrl(Uri.parse(redirectUrl))) {
        await launchUrl(
          Uri.parse(redirectUrl),
          mode: LaunchMode.externalApplication, // Buka di browser eksternal
        );

        // Untuk simulasi callback, kita bisa polling status atau menggunakan deep link
        // Untuk sekarang, kita akan memanggil callback dengan status 'pending'
        // Dalam implementasi nyata, Anda perlu menangani callback dari Midtrans
        onTransactionFinished('pending');
      } else {
        throw Exception('Tidak dapat membuka URL pembayaran');
      }

    } catch (e) {
      print('Error starting Midtrans payment: $e');

      // Tampilkan error ke user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulai pembayaran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  /// 🔹 Cek status pembayaran dari backend
  static Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    final url = Uri.parse('$baseUrl/payment/status/$orderId');
    
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Gagal mendapatkan status pembayaran');
      }
    } catch (e) {
      throw Exception('Error getting payment status: $e');
    }
  }

  /// 🔹 Ambil riwayat pembayaran customer
  static Future<List<dynamic>> getPaymentHistory(String customerId) async {
    final url = Uri.parse('$baseUrl/payment/history/$customerId');
    
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Gagal mendapatkan riwayat pembayaran');
      }
    } catch (e) {
      throw Exception('Error getting payment history: $e');
    }
  }
  

  /// 🔹 Helper untuk mengecek apakah transaksi sukses
  static bool isTransactionSuccess(String status) {
    // Status yang valid dari Midtrans:
    // - "capture" atau "settlement" = sukses
    // - "pending" = menunggu
    // - "deny" atau "cancel" atau "expire" = gagal

    final statusLower = status.toLowerCase();

    // Jika status kosong atau cancel, berarti gagal/dibatalkan
    if (statusLower.isEmpty || statusLower == 'cancel' || statusLower == 'failure') {
      return false;
    }

    return statusLower == 'capture' ||
           statusLower == 'settlement' ||
           statusLower == 'success';
  }

  /// 🔹 Helper untuk mendapatkan pesan status yang user-friendly
  static String getStatusMessage(String status) {
    final statusLower = status.toLowerCase();

    if (statusLower.isEmpty) {
      return 'Pembayaran dibatalkan';
    }

    switch (statusLower) {
      case 'capture':
      case 'settlement':
      case 'success':
        return 'Pembayaran berhasil';
      case 'pending':
        return 'Menunggu pembayaran';
      case 'deny':
        return 'Pembayaran ditolak';
      case 'expire':
        return 'Pembayaran kadaluarsa';
      case 'cancel':
      case 'failure':
        return 'Pembayaran dibatalkan';
      default:
        return 'Status: $status';
    }
  }
}