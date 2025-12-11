import 'dart:async';
import 'dart:convert';

import 'package:azza_service/Others/session_manager.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/utils/error_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // haptic + formatters
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'login.dart';
import '../Home/home.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = false; // default: Daftar
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool isLoading = false;

  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final nohpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final tglLahirController = TextEditingController();

  String tglLahirAsli = "";

  // ROUTE HALUS: fade + slide
  Route _smoothRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(
                -0.04,
                0,
              ), // dari kiri ke kanan (kebalikan Login)
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _goToLogin() async {
    if (isLogin) return;
    HapticFeedback.selectionClick();
    setState(() => isLogin = true); // animasikan saklar
    await Future.delayed(
      const Duration(milliseconds: 240),
    ); // tunggu indikator geser
    if (!mounted) return;
    Navigator.of(context).pushReplacement(_smoothRoute(const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final padding = screenSize.width * 0.06;

    const Color blue = Color(0xFF0D47A1);
    const Color light = Color.fromARGB(255, 209, 224, 255);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : blue,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: screenSize.height * 0.05),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          'assets/image/logo.png',
                          width: isLandscape
                              ? screenSize.width * 0.2
                              : screenSize.width * 0.45,
                          height: isLandscape
                              ? screenSize.height * 0.15
                              : screenSize.height * 0.12,
                        ),
                      ),
                      Container(
                        width: isLandscape
                            ? screenSize.width * 0.2
                            : screenSize.width * 0.45,
                        margin: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Service | Penjualan | Pengadaan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenSize.width * 0.02,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenSize.height * 0.04),

                // White container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: padding,
                        vertical: screenSize.height * 0.04,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Toggle saklar
                          SizedBox(
                            height: screenSize.height * 0.06,
                            child: _buildSegmentedSwitch(
                              screenSize,
                              blue,
                              light,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Form fields
                          if (!isLogin) ...[
                            // Informasi Pribadi Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: blue.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: blue.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Informasi Pribadi',
                                    style: GoogleFonts.poppins(
                                      fontSize: screenSize.width * 0.04,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : blue,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    'Nama Lengkap',
                                    false,
                                    blue: blue,
                                  ),
                                  SizedBox(height: screenSize.height * 0.02),
                                  _buildTextField(
                                    'Username',
                                    false,
                                    icon: Icons.person,
                                    blue: blue,
                                  ),
                                  SizedBox(height: screenSize.height * 0.02),
                                  _buildTextField(
                                    'Nomor HP',
                                    false,
                                    icon: Icons.phone,
                                    blue: blue,
                                  ),
                                  SizedBox(height: screenSize.height * 0.02),
                                  _buildTextField(
                                    'Tanggal Lahir',
                                    false,
                                    icon: Icons.calendar_today,
                                    blue: blue,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            // Informasi Keamanan Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: blue.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: blue.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Informasi Keamanan',
                                    style: GoogleFonts.poppins(
                                      fontSize: screenSize.width * 0.04,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : blue,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    'Kata Sandi',
                                    true,
                                    blue: blue,
                                  ),
                                  SizedBox(height: screenSize.height * 0.02),
                                  _buildTextField(
                                    'Konfirmasi Kata Sandi',
                                    true,
                                    blue: blue,
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            _buildTextField(
                              'Tanggal Lahir',
                              false,
                              icon: Icons.calendar_today,
                              blue: blue,
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            _buildTextField('Kata Sandi', true, blue: blue),
                          ],

                          if (isLogin)
                            Padding(
                              padding: EdgeInsets.only(
                                top: screenSize.height * 0.01,
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Lupa Kata Sandi',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : blue,
                                    fontSize: screenSize.width * 0.035,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(height: screenSize.height * 0.03),

                          // Tombol utama
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: blue,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: screenSize.height * 0.02,
                              ),
                            ),
                            onPressed: () async {
                              if (isLoading) return;

                              if (isLogin) {
                                // Jika toggle pada "Masuk", pakai transisi halus ke Login
                                _goToLogin();
                                return;
                              }

                              // VALIDASI REGISTER
                              if (nameController.text.isEmpty ||
                                  usernameController.text.isEmpty ||
                                  passwordController.text.isEmpty ||
                                  confirmController.text.isEmpty ||
                                  nohpController.text.isEmpty ||
                                  tglLahirController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Harap isi semua kolom terlebih dahulu',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (passwordController.text !=
                                  confirmController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Kata sandi dan konfirmasi tidak sama',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() => isLoading = true);

                              try {
                                final result = await ApiService.registerUser(
                                  nameController.text.trim(),
                                  usernameController.text.trim(),
                                  passwordController.text.trim(),
                                  nohpController.text.trim(),
                                  tglLahirAsli.trim(),
                                );

                                if (!mounted) return;

                                setState(() => isLoading = false);

                                if (result['success'] == true) {
                                  await SessionManager.saveUserSession(
                                    result['costomer']['id_costomer']
                                        .toString(),
                                    result['costomer']['cos_nama'],
                                    int.tryParse(
                                          result['costomer']['cos_poin']
                                              .toString(),
                                        ) ??
                                        0,
                                  );

                                  if (!mounted) return;
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Registrasi berhasil!'),
                                    ),
                                  );

                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const HomePage(
                                        isFreshLogin: true,
                                      ),
                                    ),
                                    (route) => false,
                                  );
                                } else {
                                  String message = result['message'] ??
                                      'Terjadi kesalahan. Coba lagi.';
                                  // Sanitize server message to remove sensitive information
                                  message =
                                      ErrorUtils.sanitizeServerMessage(message);
                                  if (result['code'] != null) {
                                    switch (result['code']) {
                                      case 4091:
                                        message =
                                            'Nomor HP sudah terdaftar. Gunakan nomor lain.';
                                        break;
                                      case 4092:
                                        message =
                                            'Nama dan password sudah digunakan.';
                                        break;
                                      case 422:
                                        message =
                                            'Nomor HP harus berupa angka 10-13 digit.';
                                        break;
                                    }
                                  }
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                }
                              } catch (e) {
                                setState(() => isLoading = false);
                                if (!context.mounted) return;
                                ErrorUtils.showErrorSnackBar(context, e,
                                    customMessage: 'Gagal mendaftarkan akun');
                              }
                            },
                            child: Text(
                              isLogin ? 'Masuk' : 'Daftar',
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
            if (isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Segmented switch ala saklar
  Widget _buildSegmentedSwitch(Size screenSize, Color blue, Color light) {
    final double height = screenSize.height * 0.06;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : light,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: blue.withValues(alpha: 0.25), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Slider indikator aktif
          AnimatedAlign(
            alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutQuad,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [const Color(0xFF2E6BFF), blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Teks + area sentuh
          Row(
            children: [
              // Tab Masuk
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _goToLogin, // gunakan transisi halus
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : (isLogin ? Colors.white : blue),
                          fontWeight: FontWeight.w600,
                          fontSize: screenSize.width * 0.04,
                          letterSpacing: 0.2,
                        ),
                        child: const Text('Masuk'),
                      ),
                    ),
                  ),
                ),
              ),

              // Tab Daftar
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      if (isLogin) {
                        HapticFeedback.selectionClick();
                        setState(() => isLogin = false);
                      }
                    },
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : (isLogin ? blue : Colors.white),
                          fontWeight: FontWeight.w600,
                          fontSize: screenSize.width * 0.04,
                          letterSpacing: 0.2,
                        ),
                        child: const Text('Daftar'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    bool isPassword, {
    IconData? icon,
    required Color blue,
  }) {
    final screenSize = MediaQuery.of(context).size;

    // Tentukan controller
    TextEditingController? controller;
    if (hint == 'Nama Lengkap') {
      controller = nameController;
    } else if (hint == 'Username') {
      controller = usernameController;
    } else if (hint == 'Nomor HP') {
      controller = nohpController;
    } else if (hint == 'Kata Sandi') {
      controller = passwordController;
    } else if (hint == 'Konfirmasi Kata Sandi') {
      controller = confirmController;
    } else if (hint == 'Tanggal Lahir') {
      controller = tglLahirController;
    }

    final bool isConfirm = hint.toLowerCase().contains('konfirmasi');
    final bool isDateField = hint == 'Tanggal Lahir';

    return TextField(
      controller: controller,
      readOnly: isDateField,
      onTap: isDateField
          ? () async {
              FocusScope.of(context).unfocus();
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime(2000, 1, 1),
                firstDate: DateTime(1950, 1, 1),
                lastDate: DateTime.now(),
                locale: const Locale('id', 'ID'),
              );
              if (pickedDate != null) {
                controller?.text = DateFormat(
                  'dd-MM-yyyy',
                ).format(pickedDate); // UI
                tglLahirAsli = DateFormat(
                  'yyyy-MM-dd',
                ).format(pickedDate); // backend
              }
            }
          : null,
      keyboardType:
          hint == 'Nomor HP' ? TextInputType.phone : TextInputType.text,
      inputFormatters: hint == 'Nomor HP'
          ? <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
            ]
          : null,
      obscureText: isPassword &&
          ((isConfirm && !showConfirmPassword) ||
              (!isConfirm && !showPassword)),
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
            : blue.withValues(alpha: 0.12),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  (isConfirm ? showConfirmPassword : showPassword)
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : blue,
                  size: screenSize.width * 0.05,
                ),
                onPressed: () {
                  setState(() {
                    if (isConfirm) {
                      showConfirmPassword = !showConfirmPassword;
                    } else {
                      showPassword = !showPassword;
                    }
                  });
                },
              )
            : (icon != null
                ? Icon(
                    icon,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : blue,
                    size: screenSize.width * 0.05,
                  )
                : null),
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
