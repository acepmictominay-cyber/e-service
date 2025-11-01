import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:e_service/api_services/forget_password_service.dart';
import 'login.dart'; // pastikan arah import sesuai lokasi file kamu

class ResetPasswordScreen extends StatefulWidget {
  final String customerId;

  const ResetPasswordScreen({super.key, required this.customerId});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  bool showPassword = false;
  bool _isLoading = false;

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

            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/image/logo.png',
                    width: screenSize.width * 0.45,
                    height: screenSize.height * 0.12,
                  ),
                  Text(
                    'Atur Ulang Kata Sandi',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: screenSize.width * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  Text(
                    'Masukkan kata sandi baru Anda',
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
                      _buildTextField(
                        controller: _newPasswordController,
                        hint: 'Kata Sandi Baru',
                        isPassword: true,
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
                        onPressed: _isLoading ? null : _resetPassword,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Konfirmasi',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
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

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi baru wajib diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ForgetPasswordService.resetPassword(widget.customerId, newPassword);
      if (result['success'] ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kata sandi berhasil diubah!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal reset password')),
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
    bool isPassword = false,
  }) {
    final screenSize = MediaQuery.of(context).size;
    return TextField(
      controller: controller,
      obscureText: isPassword && !showPassword,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: screenSize.width * 0.035,
          color: Colors.black54,
        ),
        filled: true,
        fillColor: const Color(0xFF1976D2).withValues(alpha: 0.15),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF0D47A1),
                ),
                onPressed: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
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
