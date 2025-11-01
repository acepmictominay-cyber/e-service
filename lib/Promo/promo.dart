import 'dart:async';

import 'package:e_service/Beli/shop.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/checkout.dart';
import 'package:e_service/Others/informasi.dart'; // Tambahkan import ini
import 'package:e_service/Others/notifikasi.dart';
import 'package:e_service/Others/riwayat.dart';
import 'package:e_service/Others/user_point_data.dart';
import 'package:e_service/Profile/profile.dart';
import 'package:e_service/Service/Service.dart';
import 'package:e_service/Service/cleaning_service.dart';
import 'package:e_service/Service/perbaikan_service.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:e_service/models/promo_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TukarPoinPage extends StatefulWidget {
  const TukarPoinPage({super.key});

  @override
  State<TukarPoinPage> createState() => _TukarPoinPageState();
}

class _TukarPoinPageState extends State<TukarPoinPage> {
  int currentIndex = 3;
  List<Promo> promoList = [];
  bool _isLoading = true;

  // ====== Tambahan untuk Banner ======
  final PageController _pageController = PageController();
  int _currentBanner = 0;
  late final List<String> _bannerImages;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _fetchPromo();
     UserPointData.loadUserPoints();
    // List banner online (bisa diganti sesuai kebutuhan)
    _bannerImages = [
      "https://storage-asset.msi.com/global/picture/promotion/seo_17149799016638843d7c58d2.68846293.jpeg",
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRO4i6FHYhdKWeFFb-ZCPEHyH5VSQlF0EmKug&s",
      "https://tabloidpulsa.id/wp-content/uploads/2024/08/Lenovo-Legion-Go-Promo-Back-To-School.webp",
    ];

    // Timer untuk auto-slide setiap 3 detik
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentBanner + 1) % _bannerImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchPromo() async {
    try {
      final response = await ApiService.getPromo();
      setState(() {
        promoList =
            response.map<Promo>((json) => Promo.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading promo: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ==== HEADER ====
          Container(
            height: 130,
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Image.asset('assets/image/logo.png', width: 130, height: 40),
                const Spacer(),               
                IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ==== ISI HALAMAN (scrollable) ====
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // ==== CARD POIN ====
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ValueListenableBuilder<int>(
                              valueListenable: UserPointData.userPoints,
                              builder: (context, points, _) {
                                return Text(
                                  "$points ",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            Image.asset(
                              'assets/image/coin.png',
                              width: 22,
                              height: 22,
                            ),
                            const SizedBox(width: 4),
                            const Text("Poin", style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Pilih Layanan'),
                                          content: const Text(
                                            'Pilih jenis layanan yang ingin Anda pesan:',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            const CleaningServicePage(),
                                                  ),
                                                );
                                              },
                                              child: const Text('Cleaning'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            const PerbaikanServicePage(),
                                                  ),
                                                );
                                              },
                                              child: const Text('Service'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                const Text(
                                  "Tambah",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.history,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const RiwayatPage(),
                                      ),
                                    );
                                  },
                                ),
                                const Text(
                                  "Riwayat",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==== BANNER (AUTO SLIDE + DOT CLICK) ====
                  Column(
                    children: [
                      SizedBox(
                        height: 150,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _bannerImages.length,
                          onPageChanged: (index) {
                            setState(() => _currentBanner = index);
                          },
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: NetworkImage(_bannerImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_bannerImages.length, (index) {
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: _dot(index == _currentBanner),
                          );
                        }),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ==== PROMO BULAN INI ====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Promo Bulan Ini",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _promoCard(
                                context,
                                imageUrl:
                                    "https://images.unsplash.com/photo-1593642634443-44adaa06623a?auto=format&fit=crop&w=800&q=80",
                                title: "Diskon 20% Service Laptop",
                                description:
                                    "Khusus bulan ini! Service semua jenis laptop lebih hemat.",
                              ),
                              _promoCard(
                                context,
                                imageUrl:
                                    "https://images.unsplash.com/photo-1593642532973-d31b6557fa68",
                                title: "Free Cleaning Keyboard",
                                description:
                                    "Nikmati gratis cleaning untuk pembelian sparepart.",
                              ),
                              _promoCard(
                                context,
                                imageUrl:
                                    "https://images.unsplash.com/photo-1517336714731-489689fd1ca8",
                                title: "Cashback 15% Sparepart",
                                description:
                                    "Dapatkan cashback untuk pembelian sparepart original.",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==== PRODUK TUKAR POIN ====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,  
                      children: const [
                        Text(
                          "Tukarkan",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text("→", style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 200,
                    child:
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: promoList.length,
                              itemBuilder: (context, index) {
                                final promo = promoList[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    left: index == 0 ? 16 : 8,
                                    right: 8,
                                  ),
                                  child: _productCard(context, promo),
                                );
                              },
                            ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ==== BOTTOM NAVIGATION ====
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ServicePage()),
            );
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
          const BottomNavigationBarItem(
            icon: Icon(Icons.build_circle_outlined),
            label: 'Service',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Beli',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/image/promo.png', width: 24, height: 24),
            label: 'Promo',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ==== DOT BANNER ====
  Widget _dot(bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 10 : 8,
      height: active ? 10 : 8,
      decoration: BoxDecoration(
        color: active ? Colors.blue : Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ==== PRODUK CARD ====
Widget _productCard(
  BuildContext context,
  Promo promo,
) {
  String name = promo.tipeProduk;
  String poin = promo.koin.toString();
  String img = promo.gambar.startsWith('http')
      ? promo.gambar
      : 'http://192.168.1.6:8000/storage/${promo.gambar}';
  int diskon = promo.diskon;
  return Container(
    width: 160,
    margin: const EdgeInsets.only(right: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min, // 🔹 biar tinggi fleksibel
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==== GAMBAR PRODUK ====
        Stack(
          children: [
            Container(
              height: 90, // 🔹 dikurangi biar aman di layar kecil
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child:
                    img.startsWith('http')
                        ? Image.network(img, height: 70, fit: BoxFit.contain)
                        : Image.asset(img, height: 70, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "-$diskon%",
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),

        // ==== INFORMASI PRODUK ====
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 🔹 biar fleksibel
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),

              // ==== ROW POIN + KOIN + TOMBOL TUKAR ====
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "$poin ",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Image.asset(
                        'assets/image/coin.png',
                        width: 14,
                        height: 14,
                      ),
                    ],
                  ),

                  // ==== TOMBOL TUKAR ====
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => CheckoutPage(
                                  usePointsFromPromo: true,
                                  produk: {
                                    'nama_produk': promo.tipeProduk,
                                    'harga': promo.harga,
                                    'poin': promo.koin,
                                    'gambar': img,
                                    'deskripsi': promo.tipeProduk,
                                    'kode_barang': promo.kodeBarang,
                                  },
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        minimumSize: const Size(45, 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 1.5,
                        textStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text("Tukar"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _promoCard(BuildContext context, {
  required String imageUrl,
  required String title,
  required String description,
}) {
  return Container(
    width: 260,
    margin: const EdgeInsets.only(right: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),

      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min, // biar fleksibel
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 79, // sedikit lebih tinggi biar proporsional
            fit: BoxFit.cover,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    // Navigasi ke InformasiPage dengan data promo
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InformasiPage(
                          bannerImage: imageUrl,
                          bannerTitle: title,
                          bannerText: description,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Lihat Detail",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}