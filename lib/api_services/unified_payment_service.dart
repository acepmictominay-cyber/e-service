import 'package:flutter/material.dart';
import '../api_services/payment_service.dart';
import '../api_services/api_service.dart';
import '../Others/session_manager.dart';
import '../Others/user_point_data.dart';

enum PaymentType { service, product }

class UnifiedPaymentService {
  /// Unified payment handler for both service and product checkouts
  static Future<void> startUnifiedPayment({
    required BuildContext context,
    required PaymentType paymentType,
    required String orderId,
    required int amount,
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required List<Map<String, dynamic>> itemDetails,
    required Function(String) onSuccess,
    required Function(String) onFailure,
    // Service-specific parameters
    Map<String, dynamic>? serviceData,
    // Product-specific parameters
    Map<String, dynamic>? productData,
  }) async {
    try {
      await PaymentService.startMidtransPayment(
        context: context,
        orderId: orderId,
        amount: amount > 0 ? amount : 1000, // Minimum 1000 for Midtrans
        customerId: customerId,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        itemDetails: itemDetails,
        transKode: orderId, // Pass orderId as transKode
        paymentType: serviceData?['paymentType'] ?? 'product', // Pass paymentType from serviceData or 'product'
        onTransactionFinished: (result) async {
          if (PaymentService.isTransactionSuccess(result)) {
            // Handle successful payment based on type
            await _handlePaymentSuccess(
              paymentType: paymentType,
              orderId: orderId,
              serviceData: serviceData,
              productData: productData,
            );
            onSuccess(orderId);
          } else {
            final errorMessage = PaymentService.getStatusMessage(result);
            onFailure(errorMessage);
          }
        },
      );
    } catch (e) {
      onFailure('Error: $e');
    }
  }

  /// Handle successful payment processing based on payment type
  static Future<void> _handlePaymentSuccess({
    required PaymentType paymentType,
    required String orderId,
    Map<String, dynamic>? serviceData,
    Map<String, dynamic>? productData,
  }) async {
    switch (paymentType) {
      case PaymentType.service:
        await _handleServicePaymentSuccess(orderId, serviceData);
        break;
      case PaymentType.product:
        await _handleProductPaymentSuccess(orderId, productData);
        break;
    }
  }

  /// Handle service payment success (create transaction record)
  static Future<void> _handleServicePaymentSuccess(
    String orderId,
    Map<String, dynamic>? serviceData,
  ) async {
    if (serviceData == null) return;

    // Skip backend operations in development mode
    if (!PaymentService.isProduction) return;

    try {
      String? customerId = await SessionManager.getCustomerId();
      if (customerId == null) throw Exception('Customer ID not found');

      // Create transaction record for service
        final response = await ApiService.createTransaksi({
          'cos_kode': customerId,
          'kry_kode': serviceData['technicianCode'] ?? 'KRY001',
          'trans_total': serviceData['amount'] is int ? serviceData['amount'] : (serviceData['amount'] as num).toInt(),
          'trans_discount': 0.0,
          'trans_tanggal': DateTime.now().toIso8601String().substring(0, 10),
          'trans_status': 'Waiting',
          'merek': serviceData['brand'] ?? '',
          'device': serviceData['device'] ?? '',
          'seri': serviceData['serial'] ?? '',
          'ket_keluhan': serviceData['complaint'] ?? '',
          'status_garansi': serviceData['warrantyStatus'] ?? 'Tidak Ada Garansi',
        });

      if (response['success'] != true) {
        throw Exception('Failed to create transaction: ${response['message']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Handle product payment success (update payment status and handle points)
  static Future<void> _handleProductPaymentSuccess(
    String orderId,
    Map<String, dynamic>? productData,
  ) async {
    if (productData == null) return;

    // Skip backend operations in development mode
    if (!PaymentService.isProduction) return;

    try {
      // Update payment status
      await ApiService.updatePaymentStatus(
        orderCode: orderId,
        paymentStatus: 'paid',
      );

      // Handle point deduction for promo products
      if (productData['usePoints'] == true) {
        final session = await SessionManager.getUserSession();
        final userId = session['id'];
        if (userId != null) {
          int userPoints = UserPointData.userPoints.value;
          final newPoints = userPoints - ((productData['pointsUsed'] ?? 0) as int);
          await ApiService.updateCostomer(userId, {'cos_poin': newPoints.toString()});
          UserPointData.setPoints(newPoints);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Create service payment data structure
  static Map<String, dynamic> createServicePaymentData({
    required String serviceType,
    required List<Map<String, String?>> items,
    required int amount,
    String technicianCode = 'KRY001',
  }) {
    // Extract data from first item (assuming single item per transaction)
    final firstItem = items.isNotEmpty ? items[0] : {};

    return {
      'technicianCode': technicianCode,
      'amount': amount,
      'brand': firstItem['merek'] ?? '',
      'device': firstItem['device'] ?? '',
      'serial': firstItem['seri'] ?? '',
      'complaint': serviceType == 'repair' && firstItem['part'] != null
          ? firstItem['part']!
          : '',
      'warrantyStatus': firstItem['status'] ?? 'Tidak Ada Garansi',
    };
  }

  /// Create product payment data structure
  static Map<String, dynamic> createProductPaymentData({
    required bool usePoints,
    required int pointsUsed,
  }) {
    return {
      'usePoints': usePoints,
      'pointsUsed': pointsUsed,
    };
  }
}
