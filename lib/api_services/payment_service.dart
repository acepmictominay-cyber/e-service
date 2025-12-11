import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../Others/doku_webview.dart';
import '../Others/midtrans_webview.dart';

import 'package:azza_service/config/api_config.dart';
import 'package:azza_service/utils/error_handler.dart' as error_handler;

class PaymentService {
  // Environment Configuration
  static const bool _isProduction = false; // Set to true for production

  // Public getter for environment check
  static bool get isProduction => _isProduction;

  // Doku Configuration
  static String get dokuBaseUrl => ApiConfig.dokuBaseUrl;
  static String get dokuClientKey => ApiConfig.dokuClientKey;
  static String get dokuSignature => ApiConfig.dokuSignature;
  static String get dokuTokenEndpoint => ApiConfig.dokuTokenEndpoint;

  // Midtrans Configuration
  static String get midtransServerKey => ApiConfig.midtransServerKey;
  static String get midtransClientKey => ApiConfig.midtransClientKey;

  // Dynamic URLs based on environment
  static String get baseUrl => ApiConfig.apiBaseUrl;
  static String get webhookUrl => ApiConfig.webhookBaseUrl;

  /// 🔹 Get Doku Access Token
  static Future<String> _getDokuAccessToken() async {
    final timestamp =
        DateTime.now().toUtc().toIso8601String().replaceAll('Z', '+00:00');

    final url = Uri.parse('$dokuBaseUrl$dokuTokenEndpoint');

    try {
      final response = await http.post(
        url,
        headers: {
          'X-SIGNATURE': dokuSignature,
          'X-TIMESTAMP': timestamp,
          'X-CLIENT-KEY': dokuClientKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
            {'grantType': 'client_credentials', 'additionalInfo': {}}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['accessToken'] != null) {
        return data['accessToken'];
      } else {
        throw Exception(
            'Failed to get Doku access token: ${data['responseMessage'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error getting Doku access token: $e');
    }
  }

  /// 🔹 Create Doku Payment
  static Future<Map<String, dynamic>> _createDokuPayment({
    required String accessToken,
    required String orderId,
    required int amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    List<Map<String, dynamic>>? itemDetails,
  }) async {
    final url = Uri.parse('$dokuBaseUrl/payment-api/v1.0/create-payment');

    final orderData = <String, dynamic>{
      'invoice_number': orderId,
      'amount': amount,
      'currency': 'IDR',
      'callback_url': webhookUrl,
      'auto_redirect': true,
    };

    if (itemDetails != null && itemDetails.isNotEmpty) {
      orderData['line_items'] = itemDetails
          .map((item) => {
                'name': item['name'] ?? 'Item',
                'price': item['price'] ?? item['amount'] ?? 0,
                'quantity': item['quantity'] ?? 1,
              })
          .toList();
    }

    final requestBody = {
      'order': orderData,
      'customer': {
        'name': customerName,
        'email': customerEmail,
        'phone': customerPhone,
      },
      'payment': {
        'payment_due_date': 60, // 60 minutes
      },
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['order'] != null) {
        return data;
      } else {
        throw Exception(
            'Failed to create Doku payment: ${data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error creating Doku payment: $e');
    }
  }

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
    String? transKode,
    String? paymentType,
  }) async {
    // Always use real API for Midtrans sandbox testing
    final url = Uri.parse('$baseUrl/payment/charge');

    try {
      // Check if this is service payment (has paymentType dp/full/cancel)
      final isServicePayment =
          paymentType != null && ['dp', 'full', 'cancel'].contains(paymentType);

      final requestBody = isServicePayment
          ? {
              // Minimal format for service payments
              'trans_kode': transKode ?? orderId,
              'cos_kode': customerId,
              'amount': amount,
              'paymentType': paymentType,
              // Production-ready: Include webhook URL for real-time notifications
              if (_isProduction) 'notification_url': webhookUrl,
            }
          : {
              // Full format for product payments - include paymentType
              'cos_kode': customerId,
              'amount': amount,
              'kode_barang': kodeBarang ?? '34GM',
              'paymentType': paymentType ??
                  'product', // Include paymentType for validation
              // Tambahkan data lengkap untuk Midtrans transaction
              'transaction_details': {
                'order_id':
                    orderId ?? 'order_${DateTime.now().millisecondsSinceEpoch}',
                'gross_amount': amount,
              },
              'customer_details': {
                'first_name': customerName ?? 'Customer',
                'email': customerEmail ?? 'customer@example.com',
                'phone': customerPhone ?? '08123456789',
              },
              'item_details': itemDetails ??
                  [
                    {
                      'id': kodeBarang ?? '34GM',
                      'price': amount,
                      'quantity': 1,
                      'name': 'Product Purchase',
                    }
                  ],
              // Production-ready: Include webhook URL for real-time notifications
              if (_isProduction) 'notification_url': webhookUrl,
            };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal membuat pembayaran');
      }
    } catch (e) {
      throw Exception('Error creating payment: $e');
    }
  }

  /// 🔹 Jalankan UI pembayaran Doku menggunakan WebView
  static Future<void> startDokuPayment({
    required BuildContext context,
    required String orderId,
    required int amount,
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    List<Map<String, dynamic>>? itemDetails,
    String? transKode,
    String? paymentType,
    required Function(String) onTransactionFinished,
  }) async {
    try {
      // Get Doku access token
      final accessToken = await _getDokuAccessToken();

      // Create Doku payment
      final paymentData = await _createDokuPayment(
        accessToken: accessToken,
        orderId: orderId,
        amount: amount,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        itemDetails: itemDetails,
      );

      final redirectUrl = paymentData['order']['url'];

      // Tampilkan WebView dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => DokuWebView(
            redirectUrl: redirectUrl,
            orderId: orderId,
            onTransactionFinished: (result) {
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop(); // Close dialog
              }
              onTransactionFinished(result);
            },
          ),
        );
      }
    } catch (e) {
      // Tampilkan error ke user
      if (context.mounted) {
        final userMessage = error_handler.ErrorHandler.handlePaymentError(
          e,
          context: 'PaymentService.startDokuPayment',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulai pembayaran: $userMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  /// 🔹 Jalankan UI pembayaran Midtrans menggunakan WebView
  static Future<void> startMidtransPayment({
    required BuildContext context,
    required String orderId,
    required int amount,
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    List<Map<String, dynamic>>? itemDetails,
    String? transKode,
    String? paymentType,
    required Function(String) onTransactionFinished,
  }) async {
    try {
      // Create payment via backend API
      final paymentData = await createPayment(
        customerId: customerId,
        amount: amount,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        orderId: orderId,
        itemDetails: itemDetails,
        transKode: transKode,
        paymentType: paymentType,
      );

      if (paymentData['success'] == true) {
        final redirectUrl = paymentData['redirect_url'];

        // Tampilkan WebView dialog
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => MidtransWebView(
              redirectUrl: redirectUrl,
              orderId: orderId,
              onTransactionFinished: (result) {
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop(); // Close dialog
                }
                onTransactionFinished(result);
              },
            ),
          );
        }
      } else {
        throw Exception(
            paymentData['message'] ?? 'Gagal membuat pembayaran Midtrans');
      }
    } catch (e) {
      // Tampilkan error ke user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulai pembayaran Midtrans: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  /// 🔹 Cek status pembayaran Doku
  static Future<Map<String, dynamic>> _getDokuPaymentStatus(
      String orderId) async {
    try {
      final accessToken = await _getDokuAccessToken();
      final url = Uri.parse(
          '$dokuBaseUrl/payment-api/v1.0/check-status?invoice_number=$orderId');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['order'] != null) {
        return data['order'];
      } else {
        throw Exception(
            'Failed to get Doku payment status: ${data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error getting Doku payment status: $e');
    }
  }

  /// 🔹 Cek status pembayaran dari backend (fallback to Doku if needed)
  static Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    // Try backend first
    final url = Uri.parse('$baseUrl/payment/status/$orderId');

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        // Fallback to Doku direct check
        return await _getDokuPaymentStatus(orderId);
      }
    } catch (e) {
      // Fallback to Doku direct check
      try {
        return await _getDokuPaymentStatus(orderId);
      } catch (dokuError) {
        throw Exception('Error getting payment status: $e');
      }
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
        throw Exception(
            data['message'] ?? 'Gagal mendapatkan riwayat pembayaran');
      }
    } catch (e) {
      throw Exception('Error getting payment history: $e');
    }
  }

  /// 🔹 Helper untuk mengecek apakah transaksi sukses
  static bool isTransactionSuccess(String status) {
    // Status yang valid dari Doku:
    // - "SUCCESS" atau "COMPLETED" = sukses
    // - "PENDING" = menunggu
    // - "FAILED" atau "CANCELLED" atau "EXPIRED" = gagal
    // Also support Midtrans statuses for backward compatibility

    final statusLower = status.toLowerCase();

    // Jika status kosong atau cancel/failed, berarti gagal/dibatalkan
    if (statusLower.isEmpty ||
        statusLower == 'cancel' ||
        statusLower == 'cancelled' ||
        statusLower == 'failure' ||
        statusLower == 'failed') {
      return false;
    }

    return statusLower == 'success' ||
        statusLower == 'completed' ||
        statusLower == 'capture' ||
        statusLower == 'settlement';
  }

  /// 🔹 Helper untuk mendapatkan pesan status yang user-friendly
  static String getStatusMessage(String status) {
    final statusLower = status.toLowerCase();

    if (statusLower.isEmpty) {
      return 'Pembayaran dibatalkan';
    }

    switch (statusLower) {
      case 'success':
      case 'completed':
      case 'capture':
      case 'settlement':
        return 'Pembayaran berhasil';
      case 'pending':
        return 'Menunggu pembayaran';
      case 'failed':
      case 'failure':
      case 'deny':
        return 'Pembayaran ditolak';
      case 'expired':
      case 'expire':
        return 'Pembayaran kadaluarsa';
      case 'cancel':
      case 'cancelled':
        return 'Pembayaran dibatalkan';
      default:
        return 'Status: $status';
    }
  }
}
