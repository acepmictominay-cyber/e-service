import 'dart:convert';
import 'package:http/http.dart' as http;

class SmsService {
  // Ganti dengan token dari Fonnte kamu
  static const String _token = 'jbWWr14pRaPjmYC3dtyh'; // Replace with your actual Fonnte token

  static Future<void> sendSms(String to, String message) async {
    try {
      // Try Fonnte WhatsApp API
      final response = await http.post(
        Uri.parse('https://api.fonnte.com/send'),
        headers: {
          'Authorization': _token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'target': to,
          'message': message,
          'countryCode': '62', // Indonesia
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true || responseData['status'] == 'success') {
          return;
        } else {
          throw Exception('Fonnte API returned unsuccessful status: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Fonnte API failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to send SMS: $e');
    }
  }
}
