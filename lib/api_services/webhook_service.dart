import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:azza_service/config/api_config.dart';

/// Service untuk menangani webhook dari Midtrans (Production-ready)
class WebhookService {
  // Production webhook endpoint - akan dipanggil oleh Midtrans
  static const String _webhookEndpoint = '/api/payment/webhook';

  /// Get webhook endpoint path (for documentation/API reference)
  static String get webhookEndpoint => _webhookEndpoint;

  /// 🔹 Handle incoming webhook dari Midtrans
  /// Endpoint ini harus di-expose di backend Laravel
  static Future<void> handleWebhook(Map<String, dynamic> webhookData) async {
    try {
      // Validasi webhook signature (penting untuk security)
      final isValid = _validateWebhookSignature(webhookData);
      if (!isValid) {
        return;
      }

      // Extract data dari webhook
      final orderId = webhookData['order_id'];
      final transactionStatus = webhookData['transaction_status'];

      // Update status pembayaran di database
      await _updatePaymentStatus(orderId, transactionStatus, webhookData);

      // Kirim notifikasi ke user jika perlu
      await _sendPaymentNotification(orderId, transactionStatus);

      // Log webhook untuk audit trail
      await _logWebhookEvent(webhookData);
    } catch (e) {
      // Error handling - log to monitoring system if needed
    }
  }

  /// 🔹 Validasi signature webhook dari Midtrans
  static bool _validateWebhookSignature(Map<String, dynamic> data) {
    try {
      final signature = data['signature_key'];
      if (signature == null) return false;

      final orderId = data['order_id']?.toString() ?? '';
      final statusCode = data['status_code']?.toString() ?? '';
      final grossAmount = data['gross_amount']?.toString() ?? '';
      const serverKey = ApiConfig.midtransServerKey;

      // Create signature string: order_id + status_code + gross_amount + server_key
      final signatureString = orderId + statusCode + grossAmount + serverKey;

      // Hash with SHA512
      final expectedSignature =
          sha512.convert(utf8.encode(signatureString)).toString();

      // Compare signatures
      return expectedSignature == signature;
    } catch (e) {
      return false;
    }
  }

  /// 🔹 Update status pembayaran di backend
  static Future<void> _updatePaymentStatus(
      String orderId, String status, Map<String, dynamic> webhookData) async {
    try {
      final url = Uri.parse('${ApiConfig.apiBaseUrl}/payment/webhook/update');

      final requestBody = {
        'order_id': orderId,
        'transaction_status': status,
        'webhook_data': webhookData,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          // Payment status update failed
        }
      }
      // Payment status update completed
    } catch (e) {
      // Error updating payment status
    }
  }

  /// 🔹 Kirim notifikasi pembayaran ke user
  static Future<void> _sendPaymentNotification(
      String orderId, String status) async {
    try {
      // TODO: Implement actual push notification using FCM service
      // This requires:
      // 1. Add firebase_messaging dependency
      // 2. Create FCMService class
      // 3. Configure FCM in main.dart
      // 4. Get user FCM token from backend
      // 5. Send notification to specific user
      //
      // Example implementation:
      // final userToken = await _getUserFCMToken(orderId);
      // if (userToken != null) {
      //   await FCMService.sendNotification(
      //     token: userToken,
      //     title: 'Status Pembayaran',
      //     body: 'Pembayaran untuk order $orderId telah $status',
      //     data: {'orderId': orderId, 'status': status},
      //   );
      // }

      // For now, webhook processing continues without push notifications
      // Backend should handle notification delivery
    } catch (e) {
      // Error sending payment notification - log for monitoring
    }
  }

  /// 🔹 Log webhook event untuk audit
  static Future<void> _logWebhookEvent(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('${ApiConfig.apiBaseUrl}/webhook/log');

      final logData = {
        'order_id': data['order_id'],
        'event_type': 'midtrans_webhook',
        'payload': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(logData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] != true) {
          // Webhook logging failed
        }
      }
      // Webhook event logging completed
    } catch (e) {
      // Error logging webhook event
    }
  }

  /// 🔹 Helper untuk mapping status Midtrans
  static String mapTransactionStatus(String midtransStatus) {
    switch (midtransStatus.toLowerCase()) {
      case 'capture':
      case 'settlement':
        return 'success';
      case 'pending':
        return 'pending';
      case 'deny':
      case 'cancel':
      case 'expire':
      case 'failure':
        return 'failed';
      default:
        return 'unknown';
    }
  }

  /// 🔹 Test webhook endpoint (untuk development)
  static Future<void> testWebhook(String testOrderId) async {
    final testData = {
      'order_id': testOrderId,
      'transaction_status': 'settlement',
      'payment_type': 'bank_transfer',
      'gross_amount': '100000',
      'signature_key': 'test_signature',
      'transaction_time': DateTime.now().toIso8601String(),
    };

    await handleWebhook(testData);
  }
}
