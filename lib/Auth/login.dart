import 'package:e_service/Auth/forget_password.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/session_manager.dart';
import 'package:e_service/Others/user_point_data.dart';
import 'package:e_service/Teknisi/teknisi_home.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final padding = screenSize.width * 0.06;

    return Scaffold(
      backgroundColor: Colors.blue,
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
                      Image.asset(
                        'assets/image/logo.png',
                        width:
                            isLandscape
                                ? screenSize.width * 0.2
                                : screenSize.width * 0.45,
                        height:
                            isLandscape
                                ? screenSize.height * 0.15
                                : screenSize.height * 0.12,
                      ),
                      Container(
                        width:
                            isLandscape
                                ? screenSize.width * 0.2
                                : screenSize.width * 0.45,
                        margin: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Service | Penjualan | Pengadaan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenSize.width * 0.035,
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
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
                          // Toggle login/daftar
                          Container(
                            height: screenSize.height * 0.06,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => isLogin = true),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            isLogin
                                                ? Colors.blue
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Masuk',
                                        style: GoogleFonts.poppins(
                                          color:
                                              isLogin
                                                  ? Colors.white
                                                  : Colors.black54,
                                          fontWeight: FontWeight.w500,
                                          fontSize: screenSize.width * 0.04,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => const AuthPage(),
                                          ),
                                        ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            !isLogin
                                                ? Colors.blue
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Daftar',
                                        style: GoogleFonts.poppins(
                                          color:
                                              !isLogin
                                                  ? Colors.white
                                                  : Colors.black54,
                                          fontWeight: FontWeight.w500,
                                          fontSize: screenSize.width * 0.04,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                                        builder:
                                            (context) =>
                                                const ForgetPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Lupa Kata Sandi',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF1976D2),
                                      fontSize: screenSize.width * 0.035,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          SizedBox(height: screenSize.height * 0.03),

                          // ✅ TOMBOL LOGIN - DIPERBAIKI
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isLogin ? Colors.white : Colors.blue,
                              foregroundColor:
                                  isLogin ? Colors.blue : Colors.white,
                              side: const BorderSide(color: Colors.blue),
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
                                final result = await ApiService.login(
                                  username,
                                  password,
                                );

                                print('🔐 [LOGIN] API Response: $result');

                                setState(() => isLoading = false);

                                if (result['success']) {
                                  final user = result['user'];
                                  final role = result['role'] ?? 'customer';

                                  print('👤 [LOGIN] Full user object: $user');
                                  print('🎭 [LOGIN] Role: $role');

                                  if (user['kry_kode'] != null) {
                                    // LOGIN TEKNISI
                                    final kryKode =
                                        user['kry_kode']!.toString();
                                    final kryNama =
                                        user['kry_nama']?.toString() ??
                                        user['username']?.toString() ??
                                        'Teknisi';

                                    print(
                                      '💾 [LOGIN] Saving technician session:',
                                    );
                                    print('   kry_kode: $kryKode');
                                    print('   kry_nama: $kryNama');

                                    await SessionManager.saveUserSession(
                                      kryKode,
                                      kryNama,
                                      0,
                                      role: 'technician',
                                      kryKode: kryKode,
                                    );

                                    final savedKryKode =
                                        await SessionManager.getkry_kode();
                                    print(
                                      '✅ [LOGIN] Verified kry_kode: $savedKryKode',
                                    );

                                    if (mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const TeknisiHomePage(),
                                        ),
                                      );
                                    }
                                  } else {
                                    // LOGIN CUSTOMER
                                    final poin =
                                        int.tryParse(
                                          user['cos_poin'].toString(),
                                        ) ??
                                        0;

                                    await SessionManager.saveUserSession(
                                      user['id_costomer']?.toString() ?? '',
                                      user['cos_nama'] ?? '',
                                      poin,
                                      role: 'customer',
                                    );

                                    UserPointData.setPoints(poin);

                                    if (mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => const HomePage(
                                                isFreshLogin: true,
                                              ),
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result['message'] ?? 'Login gagal',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() => isLoading = false);
                                print('❌ [LOGIN] Error: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
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

  Widget _buildTextField(String hint, bool isPassword, {IconData? icon}) {
    final screenSize = MediaQuery.of(context).size;
    final controller =
        hint == 'username' ? _usernameController : _passwordController;

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
        fillColor: Colors.blue.withOpacity(0.15),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.blue,
                    size: screenSize.width * 0.05,
                  ),
                  onPressed: () => setState(() => showPassword = !showPassword),
                )
                : (icon != null
                    ? Icon(
                      icon,
                      color: Colors.blue,
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
