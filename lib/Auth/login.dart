import 'package:azza_service/Auth/forget_password.dart';
import 'package:azza_service/Home/home.dart';
import 'package:azza_service/Admin/admin_home.dart';
import 'package:azza_service/Others/session_manager.dart';
import 'package:azza_service/Others/user_point_data.dart';
import 'package:azza_service/Teknisi/teknisi_home.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/utils/error_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // haptic feedback
import 'package:google_fonts/google_fonts.dart';
import 'regist.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool showPassword = false;
  bool isLoading = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
              begin: const Offset(0.04, 0), // geser dikit dari kanan
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _goToRegister() async {
    if (!isLogin) return;
    HapticFeedback.selectionClick();
    setState(() => isLogin = false); // animasikan saklar
    await Future.delayed(
      const Duration(milliseconds: 240),
    ); // tunggu indikator geser
    if (!mounted) return;
    Navigator.of(context).pushReplacement(_smoothRoute(const AuthPage()));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final padding = screenSize.width * 0.06;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : const Color(0xFF0D47A1),
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

                // Form container
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
                          // Toggle login/daftar (segmented switch)
                          SizedBox(
                            height: screenSize.height * 0.06,
                            child: _buildSegmentedSwitch(screenSize),
                          ),
                          const SizedBox(height: 24),

                          // Input fields
                          _buildTextField(
                            'username',
                            false,
                            icon: Icons.person,
                          ),
                          SizedBox(height: screenSize.height * 0.02),
                          _buildTextField('Kata sandi', true),

                          if (isLogin)
                            Padding(
                              padding: EdgeInsets.only(
                                top: screenSize.height * 0.01,
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgetPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Lupa Kata Sandi',
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : const Color(0xFF0D47A1),
                                      fontSize: screenSize.width * 0.035,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          SizedBox(height: screenSize.height * 0.03),

                          // Tombol utama
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF0D47A1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: screenSize.height * 0.02,
                              ),
                            ),
                            onPressed: () async {
                              if (isLoading) return;
                              String username = _usernameController.text.trim();
                              String password = _passwordController.text.trim();

                              if (username.isEmpty || password.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Username dan password wajib diisi',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() => isLoading = true);

                              try {
                                // Hardcoded Admin Login
                                if (username.toLowerCase() == 'admin' &&
                                    password == 'Admin123') {
                                  setState(() => isLoading = false);

                                  // Simpan session sebagai admin
                                  await SessionManager.saveUserSession(
                                    'admin001',
                                    'Administrator',
                                    0,
                                    role: 'admin',
                                  );

                                  if (!mounted) return;
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AdminHomePage(),
                                    ),
                                    (route) => false,
                                  );
                                  return;
                                }

                                final result = await ApiService.login(
                                  username,
                                  password,
                                );
                                setState(() => isLoading = false);

                                if (result['success']) {
                                  final user = result['user'];
                                  final role = result['role'] ?? 'customer';
                                  final poin = int.tryParse(
                                        user['cos_poin'].toString(),
                                      ) ??
                                      0;

                                  // Simpan session dengan role
                                  await SessionManager.saveUserSession(
                                    user['id_costomer']?.toString() ??
                                        user['kry_kode']?.toString() ??
                                        '',
                                    user['cos_nama'] ?? user['kry_nama'] ?? '',
                                    poin,
                                    role: role,
                                  );

                                  UserPointData.setPoints(poin);

                                  // Navigasi berdasarkan role
                                  Widget nextPage;
                                  if (role == 'karyawan') {
                                    nextPage = const TeknisiHomePage();
                                  } else if (role == 'admin') {
                                    nextPage = const AdminHomePage();
                                  } else {
                                    nextPage = const HomePage(
                                      isFreshLogin: true,
                                    );
                                  }

                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => nextPage,
                                    ),
                                    (route) => false,
                                  );
                                } else {
                                  final message =
                                      ErrorUtils.sanitizeServerMessage(
                                    result['message'] ?? 'Login gagal',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                }
                              } catch (e) {
                                setState(() => isLoading = false);
                                ErrorUtils.showErrorSnackBar(context, e,
                                    customMessage:
                                        'Gagal masuk. Periksa kredensial Anda');
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

            // Overlay loading indicator
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Segmented switch ala saklar untuk Masuk/Daftar
  Widget _buildSegmentedSwitch(Size screenSize) {
    final double height = screenSize.height * 0.06;
    const Color blue = Color(0xFF0D47A1);
    const Color light = Color.fromARGB(255, 209, 224, 255);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : light, // warna tidak aktif
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: blue.withOpacity(0.25), width: 1),
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
                      color: blue.withOpacity(0.30),
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
                    onTap: () {
                      if (!isLogin) {
                        HapticFeedback.selectionClick();
                        setState(() => isLogin = true);
                      }
                    },
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        style: GoogleFonts.poppins(
                          color: isLogin ? Colors.white : blue,
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
                    onTap: _goToRegister, // gunakan transisi halus
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

  Widget _buildTextField(String hint, bool isPassword, {IconData? icon}) {
    final screenSize = MediaQuery.of(context).size;
    final controller =
        hint == 'username' ? _usernameController : _passwordController;

    return Semantics(
      label:
          hint == 'username' ? 'Masukkan nama pengguna' : 'Masukkan kata sandi',
      textField: true,
      child: TextField(
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
              : const Color(0xFF0D47A1).withOpacity(0.15),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF0D47A1),
                    size: screenSize.width * 0.05,
                  ),
                  onPressed: () => setState(() => showPassword = !showPassword),
                )
              : (icon != null
                  ? Icon(
                      icon,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0D47A1),
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
      ),
    );
  }
}
