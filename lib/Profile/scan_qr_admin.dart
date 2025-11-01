import 'dart:convert';
import 'package:e_service/Others/user_detail.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';


class AdminScanQrPage extends StatefulWidget {
  const AdminScanQrPage({super.key});

  @override
  State<AdminScanQrPage> createState() => _AdminScanQrPageState();
}

class _AdminScanQrPageState extends State<AdminScanQrPage> {
  final MobileScannerController controller = MobileScannerController();
  bool isNavigating = false; // 🔸 cegah navigasi ganda

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleQrDetection(String code) {
    if (isNavigating) return; // cegah multiple scan
    isNavigating = true;

    try {
      // Decode data JSON dari QR
      final Map<String, dynamic> userData = jsonDecode(code);

      // Stop scanner sebelum pindah halaman
      controller.stop();

      // 🔹 Navigasi dengan animasi ke halaman detail user
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => UserDetailPage(data: userData),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 🔸 Animasi slide + fade
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ).then((_) {
        // aktifkan ulang scanner saat kembali
        controller.start();
        isNavigating = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ QR tidak valid atau rusak')),
      );
      controller.start(); // lanjut scan lagi
      isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔹 Header
            Container(
              width: double.infinity,
              color: const Color(0xFF1976D2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Admin QR Scanner",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.verified_user, color: Colors.white, size: 28),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Card Admin Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF1976D2),
                    child: Icon(Icons.admin_panel_settings,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Admin Azzahra",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Hak akses: Scan & Validasi QR User",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🔹 Area Scanner QR
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 🔸 Kamera Scanner
                      MobileScanner(
                        controller: controller,
                        onDetect: (capture) {
                          for (final barcode in capture.barcodes) {
                            if (barcode.rawValue != null) {
                              _handleQrDetection(barcode.rawValue!);
                              break;
                            }
                          }
                        },
                      ),

                      // 🔸 Overlay / Petunjuk saat belum ada QR terdeteksi
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.qr_code_scanner,
                              size: 100, color: Colors.black26),
                          SizedBox(height: 12),
                          Text(
                            "Arahkan kamera ke QR user",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
