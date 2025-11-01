import 'dart:convert';
import 'package:e_service/Beli/shop.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/sell.dart';
import 'package:e_service/Profile/profile.dart';
import 'package:e_service/Service/Service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShowQrToAddCoins extends StatefulWidget {
  const ShowQrToAddCoins({super.key});

  @override
  State<ShowQrToAddCoins> createState() => _ShowQrToAddCoinsState();
}

class _ShowQrToAddCoinsState extends State<ShowQrToAddCoins> {
  int currentIndex = 4; // default di tengah (Home)
  
  // 🔹 Nanti nilai ini bisa diganti otomatis dari hasil transaksi.
  final int rewardPoints = 10; 

  void _navigateWithAnimation(Widget page) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.5, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Data QR statis (nanti bisa diisi dari database struk)
    final Map<String, dynamic> qrPayload = {
      "transaction_id": "TRX123456",
      "reward_points": rewardPoints,
      "store_name": "Azzahra Mart",
      "message": "Terima kasih telah berbelanja di Azzahra Mart!",
    };

    // 🔹 Encode jadi string JSON agar bisa dibaca oleh scanner user
    final String qrData = jsonEncode(qrPayload);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Header
            Container(
              color: const Color(0xFF1976D2),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "QR Reward Poin",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Info transaksi / admin
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long, size: 60, color: Colors.black54),
                  const SizedBox(height: 8),
                  const Text(
                    "Azzahra Mart",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Reward poin transaksi: +$rewardPoints",
                    style: const TextStyle(
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 QR Code yang akan discan oleh user
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Scan QR ini untuk mendapatkan reward",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "(QR berisi poin reward yang akan ditambahkan)",
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // 🔹 Bottom Navigation seperti halaman lain
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);

          if (index == 0) {
            _navigateWithAnimation(const ServicePage());
          } else if (index == 1) {
            _navigateWithAnimation(const MarketplacePage());
          } else if (index == 2) {
            _navigateWithAnimation(const HomePage());
          } else if (index == 3) {
            _navigateWithAnimation(const CekHargaPage());
          } else if (index == 4) {
            _navigateWithAnimation(const ProfilePage());
          }
        },
        backgroundColor: const Color(0xFF1976D2),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.build_circle_outlined),
            label: 'Service',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Beli',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell_outlined),
            label: 'Jual',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
