import 'package:e_service/Auth/reset_password.dart';
import 'package:e_service/api_services/forget_password_service.dart';
import 'package:e_service/api_services/sms_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  bool _isLoading = false;
  String? _customerId;
  bool _codeSent = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.06;

    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenSize.height * 0.05),

            // Header logo dan judul
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/image/logo.png',
                    width: screenSize.width * 0.45,
                    height: screenSize.height * 0.12,
                  ),
                  Text(
                    'Lupa Kata Sandi',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: screenSize.width * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  Text(
                    _codeSent
                        ? 'Masukkan kode verifikasi yang telah dikirim'
                        : 'Masukkan username Anda untuk verifikasi',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: screenSize.width * 0.035,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: screenSize.height * 0.04),

            // Box putih utama
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: screenSize.height * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_codeSent) ...[
                        _buildTextField(
                          controller: _usernameController,
                          hint: 'Username',
                          icon: Icons.person,
                        ),
                        SizedBox(height: screenSize.height * 0.03),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                          ),
                          onPressed: _isLoading ? null : _sendVerificationCode,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Kirim Kode Verifikasi',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: screenSize.width * 0.04,
                                  ),
                                ),
                        ),
                      ] else ...[
                        _buildTextField(
                          controller: _verificationCodeController,
                          hint: 'Kode Verifikasi',
                          icon: Icons.verified_outlined,
                        ),
                        SizedBox(height: screenSize.height * 0.03),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                          ),
                          onPressed: _isLoading ? null : _verifyCode,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Verifikasi Kode',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: screenSize.width * 0.04,
                                  ),
                                ),
                        ),
                      ],
                      SizedBox(height: screenSize.height * 0.02),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Kembali ke Halaman Masuk',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1976D2),
                            fontSize: screenSize.width * 0.04,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendVerificationCode() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username wajib diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ForgetPasswordService.sendVerificationCode(username);

      if (result['success']) {
        // Get phone number and verification code from result
        final phoneNumber = result['phone'] ?? result['customer_phone'];
        final verificationCode = result['code'] ?? result['verification_code'];

        // Send SMS via Zenziva
        await SmsService.sendSms(phoneNumber, 'Kode verifikasi Anda adalah: $verificationCode');

        setState(() {
          _codeSent = true;
          _customerId = result['customer_id'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kode verifikasi telah dikirim ke $phoneNumber')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal mengirim kode')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _verifyCode() async {
    final code = _verificationCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode verifikasi wajib diisi')),
      );
      return;
    }

    if (_customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer ID tidak ditemukan')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ForgetPasswordService.verifyCode(_customerId!, code);
      if (result['success']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(customerId: _customerId!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
  }) {
    final screenSize = MediaQuery.of(context).size;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: screenSize.width * 0.035,
          color: Colors.black54,
        ),
        filled: true,
        fillColor: const Color(0xFF1976D2).withValues(alpha: 0.15),
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF0D47A1))
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: screenSize.height * 0.02,
          horizontal: screenSize.width * 0.04,
        ),
      ),
    );
  }
}
