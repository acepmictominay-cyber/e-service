import 'dart:async';

import 'package:azza_service/Beli/shop.dart';
import 'package:azza_service/Chat/chat_page.dart';
import 'package:azza_service/Home/Home.dart';
import 'package:azza_service/Others/checkout.dart';
import 'package:azza_service/Others/informasi.dart';
import 'package:azza_service/Others/notifikasi.dart';
import 'package:azza_service/Others/riwayat.dart';
import 'package:azza_service/Others/user_point_data.dart';
import 'package:azza_service/Profile/profile.dart';
import 'package:azza_service/Service/Service.dart';
import 'package:azza_service/Service/perbaikan_service.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/config/api_config.dart';
import 'package:azza_service/models/promo_model.dart';
import 'package:azza_service/models/voucher_model.dart';
import 'package:azza_service/Others/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TukarPoinPage extends StatefulWidget {
  const TukarPoinPage({super.key});

  @override
  State<TukarPoinPage> createState() => _TukarPoinPageState();
}

class _TukarPoinPageState extends State<TukarPoinPage> {
  int currentIndex = 3;
  List<Promo> promoList = [];
  bool _isLoading = true;
  List<Voucher> voucherList = [];
  bool _isVoucherLoading = true;
  List<UserVoucher> userVouchers = [];

  // ====== Tambahan untuk Banner ======
  final PageController _pageController = PageController();
  int _currentBanner = 0;
  late final List<String> _bannerImages;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _fetchPromo();
    _fetchVouchers();
    _fetchUserVouchers();
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

  Future<void> _fetchVouchers() async {
    try {
      final response = await ApiService.getVouchers();
      debugPrint("📊 Total vouchers received from API: ${response.length}");
      setState(() {
        voucherList =
            response.map<Voucher>((json) => Voucher.fromJson(json)).toList();
        debugPrint("✅ Parsed vouchers in app: ${voucherList.length}");
        _isVoucherLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading vouchers: $e");
      setState(() => _isVoucherLoading = false);
    }
  }

  Future<void> _fetchUserVouchers() async {
    try {
      final session = await SessionManager.getUserSession();
      final customerId = session['id']?.toString();
      if (customerId != null) {
        final response = await ApiService.getUserVouchers(customerId);
        setState(() {
          userVouchers =
              response
                  .map<UserVoucher>((json) => UserVoucher.fromJson(json))
                  .toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading user vouchers: $e");
    }
  }

  bool _isVoucherClaimed(Voucher voucher) {
    return userVouchers.any((uv) => uv.voucherId == voucher.voucherId);
  }

  Future<void> _claimVoucher(Voucher voucher) async {
    if (_isVoucherClaimed(voucher)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Voucher sudah diklaim')));
      return;
    }

    try {
      final session = await SessionManager.getUserSession();
      final customerId = session['id']?.toString();
      if (customerId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User tidak ditemukan')));
        return;
      }

      final response = await ApiService.claimVoucher(
        customerId,
        voucher.voucherId,
      );
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voucher ${voucher.voucherCode} berhasil diklaim!'),
          ),
        );
        // Refresh vouchers and user vouchers
        _fetchVouchers();
        _fetchUserVouchers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal claim voucher')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _getVoucherImageUrl(Voucher voucher) {
    if (voucher.image == null || voucher.image!.isEmpty) {
      return ''; // Return empty string for default icon
    }

    String imagePath = voucher.image!.trim();

    // If it's already a full URL, return as is
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // For voucher images, they are stored in assets/Vocer/ subdirectory
    // Check if the path already includes the subdirectory
    if (imagePath.startsWith('assets/Vocer/')) {
      return '${ApiConfig.storageBaseUrl}$imagePath';
    } else {
      // If not, prepend the voucher subdirectory
      return '${ApiConfig.storageBaseUrl}assets/Vocer/$imagePath';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ==== HEADER ====
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
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
                  icon: const Icon(Icons.smart_toy, color: Colors.white),
                  tooltip: 'AI Assistant',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatPage()),
                    );
                  },
                ),
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
                      color: Theme.of(context).cardColor,
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
                              'assets/logo/point.png',
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
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black54,
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
                                  icon: Icon(
                                    Icons.history,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black54,
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

                  // ==== VOUCHER BULAN INI ====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Semua Voucher",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child:
                              _isVoucherLoading
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : voucherList.isEmpty
                                  ? const Center(
                                    child: Text("Tidak ada voucher tersedia"),
                                  )
                                  : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: voucherList.length,
                                    itemBuilder: (context, index) {
                                      final voucher = voucherList[index];
                                      return _voucherCard(context, voucher);
                                    },
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
                    height: 280,
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

                  const SizedBox(height: 20),
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
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedItemColor: Colors.white,
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
            icon: ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.white70, BlendMode.srcIn),
              child: Image.asset(
                'assets/image/promo.png',
                width: 24,
                height: 24,
              ),
            ),
            activeIcon: ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              child: Image.asset(
                'assets/image/promo.png',
                width: 24,
                height: 24,
              ),
            ),
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
        color: active ? const Color(0xFF0041c3) : Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _voucherCard(BuildContext context, Voucher voucher) {
    final imageUrl = _getVoucherImageUrl(voucher);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voucher Image - using image from database or default icon
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child:
                imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: 79,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            width: double.infinity,
                            height: 79,
                            color: Colors.blue.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0041c3),
                                ),
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            width: double.infinity,
                            height: 79,
                            color: Colors.blue.shade100,
                            child: const Icon(
                              Icons.card_giftcard,
                              size: 40,
                              color: Color(0xFF0041c3),
                            ),
                          ),
                    )
                    : Container(
                      width: double.infinity,
                      height: 79,
                      color: Colors.blue.shade100,
                      child: const Icon(
                        Icons.card_giftcard,
                        size: 40,
                        color: Color(0xFF0041c3),
                      ),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher.description ?? 'Diskon ${voucher.discountPercent}%',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed:
                        voucher.isActive && !_isVoucherClaimed(voucher)
                            ? () => _claimVoucher(voucher)
                            : null,
                    child: Text(
                      voucher.isActive
                          ? (_isVoucherClaimed(voucher) ? "Claimed" : "Claim")
                          : "Expired",
                      style: const TextStyle(
                        color: Colors.white,
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
}

// Enhanced Product Card - Using shop.dart style
Widget _productCard(BuildContext context, Promo promo) {
  final name = promo.tipeProduk;
  final poin = promo.koin.toString();
  final img =
      promo.gambar.startsWith('http')
          ? promo.gambar
          : '${ApiConfig.storageBaseUrl}${promo.gambar}';
  final diskon = promo.diskon;

  return GestureDetector(
    onTap: () {
      // Optional: Add tap functionality if needed
    },
    child: Container(
      width: 190,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF0041c3).withOpacity(0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section dengan Badge
          Stack(
            children: [
              Container(
                height: 135,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.grey.shade50, Colors.grey.shade100],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: CachedNetworkImage(
                    imageUrl: img,
                    fit: BoxFit.contain,
                    height: 135,
                    width: double.infinity,
                    placeholder:
                        (context, url) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey.shade100,
                                Colors.grey.shade200,
                              ],
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0041c3),
                              ),
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey.shade200,
                                Colors.grey.shade300,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey.shade400,
                                size: 30,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No Image',
                                style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              ),
              // Discount Badge - sama seperti shop.dart badge style
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF6B6B),
                        const Color(0xFFFF6B6B).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    "-$diskon%",
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Content Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Product Name
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.grey.shade800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Price & Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Poin dengan Coin Icon
                      Row(
                        children: [
                          Text(
                            poin,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Image.asset(
                            'assets/logo/point.png',
                            width: 16,
                            height: 16,
                          ),
                        ],
                      ),
                      // Tukar Button
                      ElevatedButton(
                        onPressed: () async {
                          final session = await SessionManager.getUserSession();
                          final customerId = session['id']?.toString();

                          if (customerId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('User tidak ditemukan'),
                              ),
                            );
                            return;
                          }

                          final currentPoints = UserPointData.userPoints.value;

                          if (currentPoints >= promo.koin) {
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
                          } else {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  backgroundColor: Theme.of(context).cardColor,
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.amber.shade600,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Poin Tidak Cukup',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    'Poin Anda tidak cukup untuk menukar produk ini. Anda membutuhkan ${promo.koin} poin.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white70
                                              : Colors.black54,
                                    ),
                                  ),
                                  actions: [
                                    Center(
                                      child: ElevatedButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0041c3,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          elevation: 2,
                                        ),
                                        child: Text(
                                          'OK',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0041c3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: const Size(60, 28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          "Tukar",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _promoCard(
  BuildContext context, {
  required String imageUrl,
  required String title,
  required String description,
}) {
  return Container(
    width: 260,
    margin: const EdgeInsets.only(right: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
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
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
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
                        builder:
                            (context) => InformasiPage(
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
                      color: Color(0xFF0041c3),
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
