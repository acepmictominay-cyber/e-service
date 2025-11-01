import 'package:e_service/Others/session_manager.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'login.dart';
import '../Home/Home.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool isLoading = false;

  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final nohpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final tglLahirController = TextEditingController();


  // ⬇️ Tambahkan ini
  String tglLahirAsli = "";

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final padding = screenSize.width * 0.06; // 6% of screen width

    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header logo + title
                SizedBox(height: screenSize.height * 0.05),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/image/logo.png',
                        width: isLandscape ? screenSize.width * 0.2 : screenSize.width * 0.45,
                        height: isLandscape ? screenSize.height * 0.15 : screenSize.height * 0.12,
                      ),
                      Container(
                        width: isLandscape ? screenSize.width * 0.2 : screenSize.width * 0.45,
                        margin: const EdgeInsets.only(top: 0.4),
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: padding, vertical: screenSize.height * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        // Toggle buttons
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
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isLogin
                                          ? Colors.blue
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Masuk',
                                      style: GoogleFonts.poppins(
                                        color: isLogin ? Colors.white : Colors.black54,
                                        fontWeight: FontWeight.w500,
                                        fontSize: screenSize.width * 0.04,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => isLogin = false),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: !isLogin
                                          ? Colors.blue
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Daftar',
                                      style: GoogleFonts.poppins(
                                        color: !isLogin ? Colors.white : Colors.black54,
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

                        // Form fields
                        if (!isLogin) ...[
                          _buildTextField('Nama Lengkap', false),
                          SizedBox(height: screenSize.height * 0.02),
                          _buildTextField('Username', false, icon: Icons.person),
                          SizedBox(height: screenSize.height * 0.02),
                           _buildTextField('Nomor HP', false, icon: Icons.phone),
                            SizedBox(height: screenSize.height * 0.02),
                        ],
                       _buildTextField('Tanggal Lahir', false, icon: Icons.calendar_today),
                        SizedBox(height: screenSize.height * 0.02),
                        _buildTextField('Kata Sandi', true),
                        if (!isLogin) ...[
                          SizedBox(height: screenSize.height * 0.02),
                          _buildTextField('Konfirmasi Kata Sandi', true),
                        ],

                        if (isLogin)
                          Padding(
                            padding: EdgeInsets.only(top: screenSize.height * 0.01),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Lupa Kata Sandi',
                                style: GoogleFonts.poppins(
                                  color: Colors.blue,
                                  fontSize: screenSize.width * 0.035,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: screenSize.height * 0.03),

                        // Tombol utama
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLogin ? Colors.white : Colors.blue,
                            foregroundColor:
                                isLogin ? Colors.blue : Colors.white,
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                          ),
                         onPressed: () async {
                            if (isLoading) return;

                            if (nameController.text.isEmpty || usernameController.text.isEmpty || passwordController.text.isEmpty || nohpController.text.isEmpty || tglLahirController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Harap isi semua kolom terlebih dahulu')),
                              );
                              return;
                            }

                            if (passwordController.text != confirmController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kata sandi dan konfirmasi tidak sama')),
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
                              print('Registration result: $result'); // Debug print
                              setState(() => isLoading = false);

                              if (result['success'] == true) {
                                await SessionManager.saveUserSession(
                                  result['costomer']['id_costomer'].toString(),
                                  result['costomer']['cos_nama'],
                                  int.tryParse(result['costomer']['cos_poin'].toString()) ?? 0,
                                );

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Registrasi berhasil!')),
                                );

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HomePage(isFreshLogin: true)),
                                );
                              } else {
                                String message = result['message'] ?? 'Terjadi kesalahan. Coba lagi.';
                                if (result['code'] != null) {
                                  switch (result['code']) {
                                    case 4091:
                                      message = 'Nomor HP sudah terdaftar. Gunakan nomor lain.';
                                      break;
                                    case 4092:
                                      message = 'Nama dan password sudah digunakan.';
                                      break;
                                    case 422:
                                      message = 'Nomor HP harus berupa angka 10-13 digit.';
                                      break;
                                  }
                                }

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              }
                            } catch (e) {
                              print('Register error: $e'); // Debug print
                              setState(() => isLoading = false);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gagal terhubung ke server.')),
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

  Widget _buildTextField(String hint, bool isPassword, {IconData? icon}) {
  final screenSize = MediaQuery.of(context).size;
  // Deteksi apakah field ini adalah "Konfirmasi Kata Sandi"
  bool isConfirm = hint.toLowerCase().contains('konfirmasi');

  // Pilih controller berdasarkan hint
  TextEditingController? controller;
  if (hint == 'Nama Lengkap') {
    controller = nameController;
  } else if (hint == 'Username') {
    controller = usernameController;
  } else if (hint == 'Nomor HP') {
      controller = nohpController;
  }else if (hint == 'Kata Sandi') {
    controller = passwordController;
  } else if (hint == 'Konfirmasi Kata Sandi') {
    controller = confirmController;
  } else if (hint == 'Tanggal Lahir') {
  controller = tglLahirController;
}
  // Kalau ini field tanggal lahir, buat bisa klik & munculkan DatePicker
  bool isDateField = hint == 'Tanggal Lahir';
  return TextField(
    controller: controller,
    // Tanggal Lahir
    readOnly: isDateField,
    onTap: isDateField
        ? () async {
            FocusScope.of(context).requestFocus(FocusNode()); // Tutup keyboard
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
              
              locale: const Locale('id', 'ID'),
            );
            if (pickedDate != null) {
            controller?.text = DateFormat('dd-MM-yyyy').format(pickedDate); // tampil di UI
            tglLahirAsli = DateFormat('yyyy-MM-dd').format(pickedDate); // dikirim ke backend
          }
          }
        : null,
    // No HP
    keyboardType: hint == 'Nomor HP' ? TextInputType.phone : TextInputType.text,
    // Passowrd
    obscureText: isPassword &&
        ((isConfirm && !showConfirmPassword) ||
         (!isConfirm && !showPassword)),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: screenSize.width * 0.035,
        color: Colors.black54,
      ),
      filled: true,
      fillColor: const Color(0xFF1976D2).withValues(alpha: 0.15),

      // Icon untuk toggle visibility password
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                (isConfirm ? showConfirmPassword : showPassword)
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: const Color(0xFF0D47A1),
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
                  color: const Color(0xFF0D47A1),
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
