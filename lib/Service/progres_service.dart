import 'package:e_service/Beli/shop.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/notifikasi.dart';
import 'package:e_service/Profile/profile.dart';
import 'package:e_service/Promo/promo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CekProgresServicePage extends StatefulWidget {
  const CekProgresServicePage({super.key});

  @override
  State<CekProgresServicePage> createState() => _CekProgresServicePageState();
}

class _CekProgresServicePageState extends State<CekProgresServicePage> {
  int currentIndex = 0; // posisi default: Service

  // 🔵 Fungsi untuk menampilkan popup poin
  void _showPoinPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // agar popup tidak hilang saat area luar diklik
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF7EA7FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "SELAMAT",
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "Rincian Poin",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _poinRow("Upgrade RAM", "10 Poin"),
                      const SizedBox(height: 8),
                      _poinRow("Upgrade SSD", "15 Poin"),
                      const Divider(height: 20, thickness: 1),
                      _poinRow("Total Poin", "25 Poin", bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _popupButton(
                      text: "Kembali",
                      onPressed: () => Navigator.pop(context),
                    ),
                    _popupButton(
                      text: "Tukar Poin",
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TukarPoinPage()),
                        );
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔹 Widget baris poin
  Widget _poinRow(String label, String value, {bool bold = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 16 : 14,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.monetization_on, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 Tombol dalam popup
  Widget _popupButton({required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(text, style: GoogleFonts.poppins(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: null,
        title: Image.asset('assets/image/logo.png', width: 95, height: 30),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationPage()),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
          if (index == 0) {
            // Stay on current page
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MarketplacePage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TukarPoinPage()),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
        backgroundColor: Colors.blue,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        items: [
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
            icon: currentIndex == 3 ? Image.asset('assets/image/promo.png', width: 24, height: 24) : Opacity(opacity: 0.6, child: Image.asset('assets/image/promo.png', width: 24, height: 24)),
            label: 'Promo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 Search Bar
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Cari nomor servis atau nama...",
                        hintStyle: GoogleFonts.poppins(fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.search, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 📄 Informasi Detail
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow("Nama", "Udin", "Jam Mulai", "10.00"),
                  const SizedBox(height: 8),
                  _infoRow("Device", "Laptop", "Jam Selesai", "10.50"),
                  const SizedBox(height: 8),
                  _infoRow("Merek", "Asus", "", ""),
                  const SizedBox(height: 8),
                  _infoRow("Seri", "xxxxxxxxxx", "", ""),
                  const SizedBox(height: 12),
                  Text("Jenis Service :", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chipService("Upgrade RAM"),
                      _chipService("Upgrade SSD"),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 🔄 Status Progres
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statusBox(
                          color: Colors.green[100]!,
                          icon: Icons.check_circle_outline,
                          label: 'Pengecekan',
                        ),
                        _statusBox(
                          color: Colors.yellow[100]!,
                          icon: Icons.timelapse,
                          label: 'Service',
                        ),
                        _statusBox(
                          color: Colors.red[100]!,
                          icon: Icons.schedule_outlined,
                          label: 'Selesai',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔵 Legend + Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _legendDot(Colors.green, "Selesai"),
                          const SizedBox(width: 6),
                          _legendDot(Colors.yellow, "Proses"),
                          const SizedBox(width: 6),
                          _legendDot(Colors.red, "Menunggu"),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _showPoinPopup(context), // ✅ tampilkan popup
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.black26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Cek Poin',
                          style: GoogleFonts.poppins(color: Colors.black87),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📋 Widget komponen kecil
  Widget _infoRow(String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text("$label1 : ", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              Expanded(child: Text(value1, style: GoogleFonts.poppins(fontSize: 13))),
            ],
          ),
        ),
        if (label2.isNotEmpty)
          Expanded(
            child: Row(
              children: [
                Text("$label2 : ", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                Expanded(child: Text(value2, style: GoogleFonts.poppins(fontSize: 13))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _chipService(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 12)),
    );
  }

  Widget _statusBox({required Color color, required IconData icon, required String label}) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }
}
