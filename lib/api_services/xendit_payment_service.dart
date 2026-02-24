import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/api_config.dart';

/// Service untuk menangani pembayaran melalui Xendit
/// Mendukung: QRIS, Virtual Account, E-Wallet, dan Kartu Kredit
///
/// NOTE: Semua pembayaran diproses melalui backend untuk keamanan
/// karena Secret Key tidak boleh暴露 di frontend
class XenditPaymentService {
  // Environment check
  static bool get isProduction =>
      ApiConfig.serverIp.contains('api.azzahracomputertegal.com');

  // Debug helper
  static void _debugLog(String method, String message, [dynamic data]) {
    if (!isProduction) {
      debugPrint('[Xendit-$method] $message');
      if (data != null) {
        debugPrint('Data: $data');
      }
    }
  }

  // Error handler helper
  static Map<String, dynamic> _handleError(
      String method, dynamic error, http.Response? response) {
    String errorMessage = 'Terjadi kesalahan';

    if (response != null) {
      _debugLog(method, 'Response Status: ${response.statusCode}');
      _debugLog(method, 'Response Body: ${response.body}');

      try {
        final data = json.decode(response.body);
        errorMessage = data['message'] ??
            data['error'] ??
            data['error_message'] ??
            errorMessage;

        // Log specific Xendit error if available
        if (data['error_code'] != null) {
          _debugLog(method, 'Xendit Error Code: ${data['error_code']}');
        }
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }
    } else {
      _debugLog(method, 'No response - Error: $error');
      errorMessage = error.toString();
    }

    return {
      'success': false,
      'message': errorMessage,
      'raw_error': error.toString(),
      'response': response?.body,
    };
  }

  // ========== QRIS PAYMENT ==========

  /// Create QRIS payment request
  /// Returns QR string untuk ditampilkan ke user
  static Future<Map<String, dynamic>> createQrisPayment({
    required String orderId,
    required int amount,
    required String customerId,
    String paymentType = 'product',
  }) async {
    final url = Uri.parse(ApiConfig.xenditQrisUrl);
    _debugLog('QRIS', 'Starting payment for order: $orderId, amount: $amount');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'amount': amount,
          'customer_id': int.tryParse(customerId) ?? customerId,
          'payment_type': paymentType,
          'callback_url': ApiConfig.webhookBaseUrl,
        }),
      );

      _debugLog('QRIS', 'Response status: ${response.statusCode}');

      final data = json.decode(response.body);
      _debugLog('QRIS', 'Response data: $data');

      if (data['success'] == true) {
        return {
          'success': true,
          'qris_string': data['qris_url'] ??
              data['qr_string'] ??
              data['data']?['qris_string'],
          'external_id': data['external_id'] ?? orderId,
          'amount': amount,
          'qr_image_url': data['qr_image_url'] ?? data['data']?['qr_image_url'],
        };
      }

      // Return error details instead of throwing
      return _handleError('QRIS', 'Gagal membuat QRIS', response);
    } catch (e) {
      _debugLog('QRIS', 'Exception: $e');
      return _handleError('QRIS', e, null);
    }
  }

  // ========== VIRTUAL ACCOUNT ==========

  /// Create Virtual Account payment request
  static Future<Map<String, dynamic>> createVirtualAccount({
    required String orderId,
    required int amount,
    required String customerName,
    required String customerId,
    required String bankCode,
    String paymentType = 'product',
  }) async {
    final url = Uri.parse(ApiConfig.xenditVaUrl);
    _debugLog('VA',
        'Starting payment for order: $orderId, amount: $amount, bank: $bankCode');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'amount': amount,
          'customer_name': customerName,
          'customer_id': int.tryParse(customerId) ?? customerId,
          'bank_code': bankCode.toUpperCase(),
          'payment_type': paymentType,
          'callback_url': ApiConfig.webhookBaseUrl,
        }),
      );

      _debugLog('VA', 'Response status: ${response.statusCode}');

      final data = json.decode(response.body);
      _debugLog('VA', 'Response data: $data');

      if (data['success'] == true) {
        return {
          'success': true,
          'va_number': data['va_number'] ??
              data['account_number'] ??
              data['data']?['va_number'],
          'bank_code': data['bank_code'] ?? bankCode.toUpperCase(),
          'external_id': data['external_id'] ?? orderId,
          'amount': amount,
          'expiry_time': data['expiry_time'] ??
              data['expiration_date'] ??
              data['data']?['expiry_time'],
        };
      }

      return _handleError('VA', 'Gagal membuat Virtual Account', response);
    } catch (e) {
      _debugLog('VA', 'Exception: $e');
      return _handleError('VA', e, null);
    }
  }

  // ========== E-WALLET ==========

  /// Create E-Wallet payment request (OVO, DANA, ShopeePay, LinkAja)
  static Future<Map<String, dynamic>> createEWalletPayment({
    required String orderId,
    required int amount,
    required String customerPhone,
    required String customerId,
    required String ewalletType,
    String paymentType = 'product',
  }) async {
    final url = Uri.parse(ApiConfig.xenditEwalletUrl);

    // Convert phone number: remove leading '62' if present, keep '0'
    String mobileNumber = customerPhone;
    if (mobileNumber.startsWith('62')) {
      mobileNumber = '0${mobileNumber.substring(2)}';
    }

    // Map e-wallet type to Xendit channel_code
    final channelCode = getEWalletChannelCode(ewalletType);

    _debugLog('EWALLET',
        'Starting payment for order: $orderId, amount: $amount, type: $ewalletType, channel: $channelCode');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reference_id': orderId,
          'currency': 'IDR',
          'amount': amount,
          'checkout_method': 'ONE_TIME_PAYMENT',
          'channel_code': channelCode,
          'ewallet_type': ewalletType.toUpperCase(),
          'channel_properties': {
            'mobile_number': mobileNumber,
          },
          'callback_url': ApiConfig.webhookBaseUrl,
          'redirect_url': '${ApiConfig.serverIp}/payment/success',
        }),
      );

      _debugLog('EWALLET', 'Response status: ${response.statusCode}');

      final data = json.decode(response.body);
      _debugLog('EWALLET', 'Response data: $data');

      if (data['success'] == true) {
        return {
          'success': true,
          'checkout_url': data['checkout_url'] ?? data['data']?['checkout_url'],
          'reference_id': data['reference_id'] ?? orderId,
          'status': data['status'] ?? 'PENDING',
          'deeplink_url': data['deeplink_url'] ?? data['data']?['deeplink_url'],
          'qr_string': data['qr_string'] ?? data['data']?['qr_string'],
        };
      }

      return _handleError(
          'EWALLET', 'Gagal membuat E-Wallet payment', response);
    } catch (e) {
      _debugLog('EWALLET', 'Exception: $e');
      return _handleError('EWALLET', e, null);
    }
  }

  // ========== INVOICE ==========

  /// Create Invoice payment (bisa bayar dengan berbagai metode)
  static Future<Map<String, dynamic>> createInvoice({
    required String orderId,
    required int amount,
    required String customerEmail,
    required String customerName,
    required List<Map<String, dynamic>> items,
    String paymentType = 'product',
  }) async {
    final url = Uri.parse(ApiConfig.xenditInvoiceUrl);
    _debugLog(
        'INVOICE', 'Starting payment for order: $orderId, amount: $amount');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'amount': amount,
          'customer_email': customerEmail,
          'customer_name': customerName,
          'items': items,
          'payment_type': paymentType,
          'callback_url': ApiConfig.webhookBaseUrl,
          'redirect_url': '${ApiConfig.serverIp}/payment/success',
        }),
      );

      _debugLog('INVOICE', 'Response status: ${response.statusCode}');

      final data = json.decode(response.body);
      _debugLog('INVOICE', 'Response data: $data');

      if (data['success'] == true) {
        return {
          'success': true,
          'invoice_url': data['invoice_url'] ?? data['data']?['invoice_url'],
          'external_id': data['external_id'] ?? orderId,
          'status': data['status'] ?? 'PENDING',
        };
      }

      return _handleError('INVOICE', 'Gagal membuat Invoice', response);
    } catch (e) {
      _debugLog('INVOICE', 'Exception: $e');
      return _handleError('INVOICE', e, null);
    }
  }

  // ========== CHECK STATUS ==========

  /// Check payment status
  static Future<Map<String, dynamic>> checkPaymentStatus(
      String externalId) async {
    final url = Uri.parse('${ApiConfig.xenditStatusUrl}/$externalId');

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['success'] == true) {
        return {
          'status': data['status'] ?? data['data']?['status'],
          'amount': data['amount'] ?? data['data']?['amount'],
          'external_id': externalId,
        };
      }

      throw Exception(data['message'] ?? data['error'] ?? 'Gagal check status');
    } catch (e) {
      throw Exception('Error checking payment status: $e');
    }
  }

  // ========== CANCEL PAYMENT ==========

  /// Cancel pending payment
  static Future<Map<String, dynamic>> cancelPayment(String externalId) async {
    final url = Uri.parse('${ApiConfig.xenditStatusUrl}/$externalId/cancel');

    try {
      final response = await http.post(url);
      final data = json.decode(response.body);

      if (data['success'] == true) {
        return {
          'success': true,
          'status': 'CANCELLED',
        };
      }

      throw Exception(
          data['message'] ?? data['error'] ?? 'Gagal cancel payment');
    } catch (e) {
      throw Exception('Error cancelling payment: $e');
    }
  }

  // ========== HELPER METHODS ==========

  /// Get Xendit channel_code from e-wallet type
  static String getEWalletChannelCode(String ewalletType) {
    switch (ewalletType.toUpperCase()) {
      case 'OVO':
        return 'ID_OVO';
      case 'DANA':
        return 'ID_DANA';
      case 'SHOPEEPAY':
        return 'ID_SHOPEEPAY';
      case 'LINKAJA':
        return 'ID_LINKAJA';
      case 'GOJEK':
        return 'ID_GOPAY';
      default:
        return 'ID_OVO';
    }
  }

  /// Validate payment status - returns true if payment is successful
  static bool isPaymentSuccess(String status) {
    final statusLower = status.toLowerCase();
    return statusLower == 'success' ||
        statusLower == 'completed' ||
        statusLower == 'paid' ||
        statusLower == 'settlement';
  }

  /// Check if payment is pending
  static bool isPaymentPending(String status) {
    final statusLower = status.toLowerCase();
    return statusLower == 'pending' ||
        statusLower == 'processing' ||
        statusLower == 'authorized';
  }

  /// Check if payment is failed
  static bool isPaymentFailed(String status) {
    final statusLower = status.toLowerCase();
    return statusLower == 'failed' ||
        statusLower == 'expired' ||
        statusLower == 'cancelled' ||
        statusLower == 'denied';
  }

  /// Get user-friendly status message
  static String getStatusMessage(String status) {
    final statusLower = status.toLowerCase();

    switch (statusLower) {
      case 'success':
      case 'completed':
      case 'paid':
      case 'settlement':
        return 'Pembayaran berhasil';
      case 'pending':
      case 'processing':
      case 'authorized':
        return 'Menunggu pembayaran';
      case 'failed':
      case 'denied':
        return 'Pembayaran ditolak';
      case 'expired':
        return 'Pembayaran kadaluarsa';
      case 'cancelled':
      case 'cancel':
        return 'Pembayaran dibatalkan';
      default:
        return 'Status: $status';
    }
  }

  /// Format currency to IDR
  static String formatIdr(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}

/// Payment method types for Xendit
enum XenditPaymentMethodType {
  qris('QRIS', 'Scan QR Code', Icons.qr_code_2),
  virtualAccount('Virtual Account', 'VA Bank', Icons.account_balance),
  ewallet('E-Wallet', 'Dompet Digital', Icons.wallet),
  creditCard('Kartu Kredit', 'Credit/Debit Card', Icons.credit_card);

  final String displayName;
  final String description;
  final IconData icon;

  const XenditPaymentMethodType(this.displayName, this.description, this.icon);
}

/// Specific bank codes for VA
enum XenditBankCode {
  bca('BCA', 'Bank Central Asia'),
  bni('BNI', 'Bank Negara Indonesia'),
  bri('BRI', 'Bank Rakyat Indonesia'),
  mandiri('MANDIRI', 'Bank Mandiri'),
  bsi('BSI', 'Bank Syaria Indonesia'),
  btpn('BTPN', 'Bank BTPN'),
  cimb('CIMB', 'Bank CIMB Niaga');

  final String code;
  final String name;

  const XenditBankCode(this.code, this.name);
}

/// Specific e-wallet types
enum XenditEWalletType {
  ovo('OVO', 'OVO'),
  dana('DANA', 'DANA'),
  shopeepay('SHOPEEPAY', 'ShopeePay'),
  linkaja('LINKAJA', 'LinkAja');

  final String code;
  final String name;

  const XenditEWalletType(this.code, this.name);
}
