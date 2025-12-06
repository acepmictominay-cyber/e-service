import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sms_service.dart';
import 'package:azza_service/config/api_config.dart';

// Temporary storage for verification codes (in production, use database/redis)
Map<String, String> _verificationCodes = {};

class ForgetPasswordService {
  // Base URL is now configurable in ApiConfig
  static String get baseUrl => ApiConfig.apiBaseUrl;

  // Send verification code via WhatsApp after validating username and phone
  static Future<Map<String, dynamic>> sendVerificationCodeByUsername(String username, String phone) async {
    // Normalize phone number: ensure it starts with 62 and remove leading 0 if present
    String normalizedPhone = phone;
    if (!normalizedPhone.startsWith('62')) {
      normalizedPhone = '62${normalizedPhone.startsWith('0') ? normalizedPhone.substring(1) : normalizedPhone}';
    }

    // First, get all customers to find the one with matching username and phone number
    final response = await http.get(Uri.parse('$baseUrl/costomers'));

    if (response.statusCode != 200) {
      return {'success': false, 'message': 'Gagal mengambil data customer'};
    }

    final customers = json.decode(response.body) as List;
    final customer = customers.firstWhere(
      (c) => c['username'] == username && (c['cos_hp'] == normalizedPhone || c['cos_hp'] == phone),
      orElse: () => null,
    );

    if (customer == null) {
      return {'success': false, 'message': 'Username atau nomor HP tidak ditemukan'};
    }

    // Generate a 6-digit verification code
    final verificationCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

    // Store the verification code with customer ID as key
    _verificationCodes[customer['id_costomer']] = verificationCode;

    // Get phone number and ensure it starts with country code
    String finalPhoneNumber = customer['cos_hp'];
    if (!finalPhoneNumber.startsWith('62')) {
      finalPhoneNumber = '62${finalPhoneNumber.startsWith('0') ? finalPhoneNumber.substring(1) : finalPhoneNumber}';
    }

    // Send WhatsApp message via Fonnte
    final message = 'Kode verifikasi reset password Anda: $verificationCode\n\nGunakan kode ini untuk melanjutkan reset password.';
    await SmsService.sendSms(finalPhoneNumber, message);

    return {
      'success': true,
      'message': 'Kode verifikasi telah dikirim ke WhatsApp Anda',
      'verification_code': verificationCode, // For testing - remove in production
      'customer_id': customer['id_costomer'],
      'customer_phone': finalPhoneNumber,
    };
  }

  // Send verification code via SMS after validating phone number
  static Future<Map<String, dynamic>> sendVerificationCode(String phoneNumber) async {
    // Normalize phone number: ensure it starts with 62 and remove leading 0 if present
    String normalizedPhone = phoneNumber;
    if (!normalizedPhone.startsWith('62')) {
      normalizedPhone = '62${normalizedPhone.startsWith('0') ? normalizedPhone.substring(1) : normalizedPhone}';
    }

    // First, get all customers to find the one with matching phone number
    final response = await http.get(Uri.parse('$baseUrl/costomers'));

    if (response.statusCode != 200) {
      return {'success': false, 'message': 'Gagal mengambil data customer'};
    }

    final customers = json.decode(response.body) as List;
    final customer = customers.firstWhere(
      (c) => c['cos_hp'] == normalizedPhone || c['cos_hp'] == phoneNumber,
      orElse: () => null,
    );

    if (customer == null) {
      return {'success': false, 'message': 'Nomor HP tidak ditemukan'};
    }

    // Generate a 6-digit verification code
    final verificationCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

    // Store the verification code with customer ID as key
    _verificationCodes[customer['id_costomer']] = verificationCode;

    // Get phone number and ensure it starts with country code
    String finalPhoneNumber = customer['cos_hp'];
    if (!finalPhoneNumber.startsWith('62')) {
      finalPhoneNumber = '62${finalPhoneNumber.startsWith('0') ? finalPhoneNumber.substring(1) : finalPhoneNumber}';
    }

    // Send SMS via Fonnte
    final message = 'Kode verifikasi reset password Anda: $verificationCode\n\nGunakan kode ini untuk melanjutkan reset password.';
    await SmsService.sendSms(finalPhoneNumber, message);

    return {
      'success': true,
      'message': 'Kode verifikasi telah dikirim ke nomor HP Anda',
      'verification_code': verificationCode, // For testing - remove in production
      'customer_id': customer['id_costomer'],
      'customer_phone': finalPhoneNumber,
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

  static Future<Map<String, dynamic>> resetPassword(String customerId, String newPassword) async {
    final requestBody = jsonEncode({
      'id_costomer': customerId,
      'password': newPassword,
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password berhasil diubah'
        };
      } else if (response.statusCode == 302) {
        // Handle redirect - this might be a Laravel redirect
        return {
          'success': false,
          'message': 'Server mengalihkan request. Periksa autentikasi API.'
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Gagal reset password'
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Gagal reset password - Response tidak valid'
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal reset password - Error jaringan: $e'
      };
    }
  }
}
