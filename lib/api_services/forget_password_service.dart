import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sms_service.dart';

// Temporary storage for verification codes (in production, use database/redis)
Map<String, String> _verificationCodes = {};

class ForgetPasswordService {
  static const String baseUrl = 'http://192.168.1.6:8000/api'; // Same as ApiService

  // Send verification code via SMS after validating username
  static Future<Map<String, dynamic>> sendVerificationCode(String username) async {
    // First, get all customers to find the one with matching username
    final response = await http.get(Uri.parse('$baseUrl/costomers'));

    if (response.statusCode != 200) {
      return {'success': false, 'message': 'Gagal mengambil data customer'};
    }

    final customers = json.decode(response.body) as List;
    final customer = customers.firstWhere(
      (c) => c['username'] == username,
      orElse: () => null,
    );

    if (customer == null) {
      return {'success': false, 'message': 'Username tidak ditemukan'};
    }

    // Generate a 6-digit verification code
    final verificationCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

    // Store the verification code with customer ID as key
    _verificationCodes[customer['id_costomer']] = verificationCode;

    // Get phone number and ensure it starts with country code
    String phoneNumber = customer['cos_hp'];
    if (!phoneNumber.startsWith('62')) {
      phoneNumber = '62${phoneNumber.startsWith('0') ? phoneNumber.substring(1) : phoneNumber}';
    }

    // Send SMS via Fonnte
    final message = 'Kode verifikasi reset password Anda: $verificationCode\n\nGunakan kode ini untuk melanjutkan reset password.';
    await SmsService.sendSms(phoneNumber, message);

    return {
      'success': true,
      'message': 'Kode verifikasi telah dikirim ke nomor HP Anda',
      'verification_code': verificationCode, // For testing - remove in production
      'customer_id': customer['id_costomer'],
      'customer_phone': phoneNumber,
    };
  }

  // Verify the entered code against stored code
  static Future<Map<String, dynamic>> verifyCode(String customerId, String code) async {
    final storedCode = _verificationCodes[customerId];

    if (storedCode == null) {
      return {'success': false, 'message': 'Kode verifikasi telah kadaluarsa. Silakan minta kode baru.'};
    }

    if (storedCode == code) {
      // Clear the code after successful verification
      _verificationCodes.remove(customerId);
      return {'success': true, 'message': 'Kode verifikasi benar'};
    } else {
      return {'success': false, 'message': 'Kode verifikasi salah'};
    }
  }

  // Reset password - CALL REAL API with detailed logging
  static Future<Map<String, dynamic>> resetPassword(String customerId, String newPassword) async {
    print('🔄 Attempting to reset password for customer: $customerId');
    print('📤 Sending request to: $baseUrl/reset-password');

    final requestBody = jsonEncode({
      'id_costomer': customerId,
      'password': newPassword,
    });
    print('📦 Request body: $requestBody');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response headers: ${response.headers}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Password reset successful: $responseData');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password berhasil diubah'
        };
      } else if (response.statusCode == 302) {
        // Handle redirect - this might be a Laravel redirect
        print('⚠️  Received redirect (302). This might indicate authentication issue.');
        return {
          'success': false,
          'message': 'Server mengalihkan request. Periksa autentikasi API.'
        };
      } else {
        print('❌ Password reset failed with status: ${response.statusCode}');
        try {
          final errorData = json.decode(response.body);
          print('❌ Error data: $errorData');
          return {
            'success': false,
            'message': errorData['message'] ?? 'Gagal reset password'
          };
        } catch (e) {
          print('❌ Failed to parse error response: $e');
          return {
            'success': false,
            'message': 'Gagal reset password - Response tidak valid'
          };
        }
      }
    } catch (e) {
      print('❌ Network error during password reset: $e');
      return {
        'success': false,
        'message': 'Gagal reset password - Error jaringan: $e'
      };
    }
  }
}
