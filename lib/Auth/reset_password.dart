import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:azza_service/api_services/forget_password_service.dart';
import 'package:azza_service/utils/password_utils.dart';
import 'login.dart'; // pastikan arah import sesuai lokasi file kamu
import '../Others/custom_dialog.dart';

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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : const Color(0xFF0D47A1),
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
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: padding, vertical: screenSize.height * 0.05),
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
                          padding: EdgeInsets.symmetric(
                              vertical: screenSize.height * 0.02),
                        ),
                        onPressed: _isLoading ? null : _resetPassword,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
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
      CustomDialog.show(
        context: context,
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha((0.1 * 255).round()),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error,
            color: Colors.red,
            size: 24,
          ),
        ),
        title: 'Peringatan',
        content: const Text('Kata sandi baru wajib diisi'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Hash password for security before sending to backend
      final hashedPassword = hashPassword(newPassword);
      final result = await ForgetPasswordService.resetPassword(
          widget.customerId, hashedPassword);
      if (result['success'] ?? false) {
        if (mounted) {
          CustomDialog.show(
            context: context,
            icon: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha((0.1 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
            title: 'Berhasil',
            content: const Text('Kata sandi berhasil diubah!'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        }
      } else {
        if (mounted) {
          CustomDialog.show(
            context: context,
            icon: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha((0.1 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error,
                color: Colors.red,
                size: 24,
              ),
            ),
            title: 'Error',
            content: Text(result['message'] ?? 'Gagal reset password'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomDialog.show(
          context: context,
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha((0.1 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error,
              color: Colors.red,
              size: 24,
            ),
          ),
          title: 'Error',
          content: Text('Terjadi kesalahan: $e'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      }
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
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white54
              : Colors.black54,
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : const Color(0xFF1976D2).withAlpha((0.15 * 255).round()),
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
