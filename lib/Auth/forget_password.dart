import 'package:azza_service/Auth/reset_password.dart';
import 'package:azza_service/api_services/forget_password_service.dart';
import 'package:azza_service/api_services/sms_service.dart';
import 'package:azza_service/utils/error_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  bool _isLoading = false;
  String? _customerId;
  bool _codeSent = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.06;

    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : const Color(0xFF0D47A1),
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
                        : 'Masukkan username dan nomor HP untuk verifikasi',
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
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: screenSize.height * 0.05,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_codeSent) ...[
                        _buildTextField(
                          controller: _usernameController,
                          hint: 'Username',
                          icon: Icons.person,
                        ),
                        SizedBox(height: screenSize.height * 0.02),
                        _buildTextField(
                          controller: _phoneController,
                          hint: 'Nomor HP',
                          icon: Icons.phone,
                        ),
                        SizedBox(height: screenSize.height * 0.03),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: screenSize.height * 0.02,
                            ),
                          ),
                          onPressed: _isLoading ? null : _sendVerificationCode,
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
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
                            padding: EdgeInsets.symmetric(
                              vertical: screenSize.height * 0.02,
                            ),
                          ),
                          onPressed: _isLoading ? null : _verifyCode,
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
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
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF1976D2),
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
    final phone = _phoneController.text.trim();
    if (username.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username dan nomor HP wajib diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ForgetPasswordService.sendVerificationCodeByUsername(
        username,
        phone,
      );

      if (result['success']) {
        // Get phone number and verification code from result
        final phoneNumber = result['phone'] ?? result['customer_phone'];
        final verificationCode = result['code'] ?? result['verification_code'];

        // Send SMS via Zenziva
        await SmsService.sendSms(
          phoneNumber,
          'Kode verifikasi Anda adalah: $verificationCode',
        );

        setState(() {
          _codeSent = true;
          _customerId = result['customer_id'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode verifikasi telah dikirim ke WhatsApp Anda'),
          ),
        );
      } else {
        final message = ErrorUtils.sanitizeServerMessage(
          result['message'] ?? 'Gagal mengirim kode',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      ErrorUtils.showErrorSnackBar(context, e, customMessage: 'Gagal mengirim kode verifikasi');
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
        final message = ErrorUtils.sanitizeServerMessage(result['message']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      ErrorUtils.showErrorSnackBar(context, e, customMessage: 'Gagal memverifikasi kode');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool obscureText = false,
  }) {
    final screenSize = MediaQuery.of(context).size;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: screenSize.width * 0.035,
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black54,
        ),
        filled: true,
        fillColor:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : const Color(0xFF1976D2).withOpacity(0.15),
        prefixIcon:
            icon != null
                ? Icon(
                  icon,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0D47A1),
                )
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
