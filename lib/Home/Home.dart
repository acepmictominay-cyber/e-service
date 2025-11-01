  import 'dart:convert';
  import 'dart:async';
  import 'package:cached_network_image/cached_network_image.dart';
  import 'package:e_service/Beli/detail_produk.dart';
  import 'package:e_service/Beli/shop.dart';
  import 'package:e_service/Others/informasi.dart';
  import 'package:e_service/Others/notifikasi.dart';
  import 'package:e_service/Others/notification_service.dart';
  import 'package:e_service/Others/session_manager.dart';
  import 'package:e_service/Others/user_point_data.dart';
  import 'package:e_service/Profile/profile.dart';
  import 'package:e_service/Promo/promo.dart';
  import 'package:e_service/Service/Service.dart';
  import 'package:e_service/api_services/api_service.dart';
  import 'package:e_service/api_services/payment_service.dart';
  import 'package:e_service/models/notification_model.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
  import 'package:font_awesome_flutter/font_awesome_flutter.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:intl/intl.dart';
  import 'package:midtrans_sdk/midtrans_sdk.dart';
  import 'package:shimmer/shimmer.dart';

  class TierInfo {
    final String label;
    final BoxDecoration decoration;
    final Color textColor;
    TierInfo(this.label, this.decoration, this.textColor);
  }

  class HomePage extends StatefulWidget {
    const HomePage({super.key, this.isFreshLogin = false});

    final bool isFreshLogin;

    @override
    State<HomePage> createState() => _HomePageState();
  }

  class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
    int currentIndex = 2;
    Map<String, dynamic>? userData;
    bool isLoading = true;
    List<dynamic> produkList = [];
    bool isProductLoading = true;

    // non-nullable controller & timer (dijamin diinisialisasi di initState)
    late final PageController _pageController;
    int _currentBannerIndex = 1;
    late final Timer _bannerTimer;
    late final AnimationController _animationController;

  
    @override
    void initState() {
      super.initState();
      _pageController = PageController(
        viewportFraction: 0.85,
        initialPage: 1, // mulai dari array ke-2
      );
      _pageController!.addListener(_onPageChanged);
      _startBannerTimer();
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      _loadUserData();
      _loadProducts();
      UserPointData.loadUserPoints();
    }


    void _page_controller_init() {
      _pageController = PageController(viewportFraction: 0.85, initialPage: _currentBannerIndex);
    }

    @override
    void dispose() {
      // karena late final, pasti sudah diinisialisasi di initState
      _pageController?.dispose();
      _bannerTimer.cancel();
      _animationController.dispose();
      super.dispose();
    }

    // =======================
    // 🔹 MIDTRANS INIT - REMOVED
    // =======================
    // Midtrans SDK initialization removed - now using redirect_url approach

    // =======================
    // 🔹 UTIL FUNCTIONS
    // =======================

    String getFirstImageUrl(dynamic gambarField) {
      if (gambarField == null) return '';

      if (gambarField is List && gambarField.isNotEmpty) {
        return 'http://192.168.1.6:8000/storage/${gambarField.first}';
      }

      if (gambarField is String && gambarField.isNotEmpty) {
        try {
          if (gambarField.contains('[')) {
            final List list = List<String>.from(jsonDecode(gambarField));
            if (list.isNotEmpty) {
              return 'http://192.168.1.6:8000/storage/${list.first}';
            }
          }
        } catch (_) {}
        return 'http://192.168.1.6:8000/storage/$gambarField';
      }

      return '';
    }

    ImageProvider? getImageProvider(dynamic gambarField) {
      final url = getFirstImageUrl(gambarField);
      if (url.isEmpty) return null;
      return NetworkImage(url);
    }

    String formatRupiah(dynamic harga) {
      if (harga == null) return 'Rp 0';
      double number;
      if (harga is String) {
        number = double.tryParse(harga) ?? 0;
      } else if (harga is num) {
        number = harga.toDouble();
      } else {
        number = 0;
      }
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(number);
    }

    // =======================
    // 🔹 LOAD DATA
    // =======================

    Future<void> _loadUserData() async {
      final session = await SessionManager.getUserSession();
      final id = session['id'];
      if (id != null) {
        try {
          final data = await ApiService.getCostomerById(id);
          setState(() {
            userData = data;
            isLoading = false;
          });
          // Show welcome notification if fresh login
          if (widget.isFreshLogin && mounted) {
            _showWelcomeNotification();
          }
        } catch (e) {
          setState(() => isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
          }
        }
      } else {
        setState(() => isLoading = false);
      }
    }

    Future<void> _loadProducts() async {
      try {
        final data = await ApiService.getProduk();
        final filtered = data.where((p) {
          final gambar = p['gambar']?.toString().trim() ?? '';
          return gambar.isNotEmpty;
        }).toList();
        setState(() {
          produkList = filtered;
          isProductLoading = false;
        });
      } catch (e) {
        setState(() => isProductLoading = false);
      }
    }

   void _showWelcomeNotification() async {
  if (!mounted) return;
  final nama = userData?['cos_nama'] ?? 'Pengguna';

  await NotificationService.addNotification(
    NotificationModel(
      title: 'Welcome',
      subtitle: 'Halooo, $nama 👋',
      icon: Icons.waving_hand,
      color: Colors.green,
      textColor: Colors.white,
      timestamp: DateTime.now(),
    ),
  );

  late OverlayEntry overlayEntry;
  final animationController = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  );
  final curvedAnimation = CurvedAnimation(
    parent: animationController,
    curve: Curves.easeOutBack,
  );

  overlayEntry = OverlayEntry(
    builder: (context) {
      return Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 16,
        right: 16,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1.2), // muncul dari atas
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
child: GestureDetector(
onHorizontalDragEnd: (DragEndDetails details) {
if (details.velocity.pixelsPerSecond.dx.abs() > 200) {
HapticFeedback.lightImpact();
animationController.reverse().then((_) {
overlayEntry.remove();
});
}
},
child: Material(
color: Colors.transparent,
child: AnimatedContainer(
duration: const Duration(milliseconds: 500),
curve: Curves.easeInOut,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.green.shade600,
borderRadius: BorderRadius.circular(14),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.25),
blurRadius: 10,
offset: const Offset(0, 5),
),
],
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
const Icon(Icons.waving_hand, color: Colors.white, size: 28),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text(
'Welcome!',
style: GoogleFonts.poppins(
color: Colors.white,
fontWeight: FontWeight.bold,
fontSize: 16,
),
),
Text(
'Halooo, $nama 👋',
style: GoogleFonts.poppins(
color: Colors.white.withOpacity(0.9),
fontSize: 13,
),
),
],
),
),
GestureDetector(
onTap: () {
animationController.reverse().then((_) {
overlayEntry.remove();
});
},
child: const Icon(Icons.close, color: Colors.white, size: 20),
),
],
),
),
),
),
          ),
        ),
      );
    },
  );

  Overlay.of(context).insert(overlayEntry);

  // Jalankan animasi muncul
  animationController.forward();
  HapticFeedback.lightImpact();
  // Hilang otomatis setelah 3 detik
  Timer(const Duration(seconds: 3), () {
    if (overlayEntry.mounted) {
      animationController.reverse().then((_) {
        overlayEntry.remove();
        animationController.dispose();
      });
    }
  });
}

  // =======================
  // 🔹 BANNER LOOP HALUS
  // =======================

  void _onPageChanged() {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentBannerIndex = _pageController!.page?.round() ?? 0;
          });
        }
      });
    }
      void _startBannerTimer() {
      _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_pageController != null && _pageController!.hasClients) {
          int nextPage = _pageController!.page!.round() + 1;
          final int total = 5;

          _pageController!.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );

          setState(() {
            _currentBannerIndex = nextPage % total;
          });
        }
      });
    }


  Widget _buildBannerSlider() {
      final List<String> banners = [
        'https://images.pexels.com/photos/3861972/pexels-photo-3861972.jpeg',
        'https://images.pexels.com/photos/380769/pexels-photo-380769.jpeg',
        'https://images.pexels.com/photos/3861973/pexels-photo-3861973.jpeg',
        'https://www.shutterstock.com/image-photo/panorama-focus-hand-holding-headset-600nw-2296039729.jpg',
        'https://images.pexels.com/photos/267350/pexels-photo-267350.jpeg',
      ];

      final List<String> titles = [
        'Diskon Service Komputer 50%',
        'Upgrade RAM & SSD',
        'Tips Perawatan Laptop',
        'Layanan Cepat & Profesional',
        'Tukar Poin untuk Servis',
      ];

      return Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: banners.length * 1000, // efek looping panjang
              itemBuilder: (context, index) {
                final int realIndex = index % banners.length;

                return AnimatedBuilder(
                  animation: _pageController!,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_pageController!.position.haveDimensions) {
                      value = (_pageController!.page! - index).abs();
                      value = (1 - (value * 0.1)).clamp(0.9, 1.0);
                    }
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(banners[realIndex]),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titles[realIndex],
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                String bannerText = '';
                                if (titles[realIndex] ==
                                    'Tips Perawatan Laptop') {
                                  bannerText = '''
  Tips dan Trik Merawat Laptop Ringan Agar Tidak Cepat Rusak

  1. Jangan Membebani Laptop Anda Terlalu Berat
  Salah satu cara paling sederhana untuk menjaga laptop tetap ringan adalah dengan tidak membebani laptop Anda terlalu berat. Jika Anda menjalankan banyak program berat atau membuka banyak tab browser sekaligus, laptop Anda akan bekerja lebih keras dan lebih panas. Hal ini dapat mengakibatkan kelebihan panas yang berpotensi merusak komponen dalam laptop Anda. Pastikan untuk menutup program yang tidak Anda gunakan dan mengelola aplikasi dengan bijak.

  2. Gunakan Laptop pada Permukaan yang Rata dan Ventilasi yang Baik
  Laptop yang digunakan pada permukaan yang datar dan keras akan membantu menjaga sirkulasi udara yang baik di sekitar laptop. Hindari meletakkan laptop Anda pada permukaan yang empuk seperti kasur atau bantal yang dapat menghalangi ventilasi udara, karena ini dapat menyebabkan laptop menjadi panas berlebihan. Gunakan alas laptop yang keras atau bantuan pendingin laptop jika diperlukan.

  3. Bersihkan Laptop secara Berkala
  Debu dan kotoran dapat mengumpul di dalam laptop dan mengganggu kinerja serta menyebabkan panas berlebihan. Bersihkan laptop secara berkala dengan menggunakan kompresor udara atau alat pembersih khusus untuk elektronik. Pastikan laptop dimatikan saat membersihkannya.

  4. Hindari Guncangan dan Benturan
  Guncangan dan benturan dapat merusak komponen dalam laptop Anda. Selalu pastikan laptop Anda ditempatkan dengan aman dan tidak terpapar risiko fisik yang berlebihan. Gunakan tas laptop yang dirancang khusus untuk melindunginya saat Anda bepergian.

  5. Lakukan Update dan Backup Data Secara Teratur
  Selalu perbarui sistem operasi dan perangkat lunak Anda secara berkala untuk menjaga keamanan dan kinerja laptop. Selain itu, lakukan backup data Anda secara teratur. Jika terjadi masalah atau kerusakan pada laptop, Anda akan memiliki cadangan data yang aman.

  6. Hindari Paparan Suhu yang Ekstrem
  Suhu yang ekstrem, baik terlalu panas maupun terlalu dingin, dapat merusak komponen dalam laptop. Hindari menggunakan laptop di tempat yang terlalu panas atau terlalu dingin. Selain itu, jangan biarkan laptop terkena sinar matahari langsung atau suhu ekstrem.

  7. Gunakan Perangkat Lunak Antivirus dan Anti-Malware
  Instal perangkat lunak antivirus dan anti-malware yang andal untuk melindungi laptop Anda dari serangan virus dan malware yang dapat merusak sistem Anda.

  8. Matikan Laptop dengan Benar
  Selalu matikan laptop Anda dengan benar daripada hanya mengaturnya ke mode sleep atau hibernate. Ini akan membantu menghindari masalah dengan sistem operasi dan perangkat keras.

  Dengan mengikuti tips dan trik di atas, Anda dapat menjaga laptop Anda agar tetap ringan dan tidak cepat rusak. Merawat laptop dengan baik adalah investasi untuk menjaga kinerja laptop Anda dalam jangka panjang, sehingga Anda dapat terus menggunakannya dengan efisien dan tanpa masalah.
  ''';
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => InformasiPage(
                                          bannerImage: banners[realIndex],
                                          bannerTitle: titles[realIndex],
                                          bannerText: bannerText,
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                'Lihat Sekarang',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }



    // =======================
    // 🔹 UI BUILD
    // =======================

    @override
    Widget build(BuildContext context) {
      final nama = userData?['cos_nama'] ?? '-';
      final id = userData?['id_costomer'] ?? '-';

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0,
          title: Image.asset('assets/image/logo.png', width: 95, height: 30),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isLoading ? _buildShimmerMemberCard() : _buildMemberCard(nama, id),
              const SizedBox(height: 10),
              SizedBox(height: 180, child: _buildBannerSlider()),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🔥 Hot Items', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: isProductLoading ? _buildProductShimmer() : produkList.isEmpty ? const Center(child: Text("Tidak ada produk dengan gambar")) : _buildProductList(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ServicePage()));
            } else if (index == 1) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MarketplacePage()));
            } else if (index == 3) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TukarPoinPage()));
            } else if (index == 4) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
            } else {
              setState(() {
                currentIndex = index;
              });
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
              icon: Image.asset('assets/image/promo.png', width: 24, height: 24, color: Colors.white70),
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

    // =======================
    // 🔹 WIDGET HELPERS
    // =======================
    
  TierInfo _getTierInfo(int points) {
    if (points >= 1500) {
      return TierInfo(
        'Sultan',
        BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD700), // Gold
              Color(0xFFFFA500), // Orange gold
              Color(0xFFFF8C00), // Dark orange
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFE082).withOpacity(0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        Colors.white,
      );
    } else if (points >= 500) {
      return TierInfo(
        'Crazy Rich',
        BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E3C72).withOpacity(0.9),
              const Color(0xFF2A5298).withOpacity(0.95),
              const Color(0xFF7E22CE).withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7E22CE).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        Colors.white,
      );
    } else if (points >= 1) {
      return TierInfo(
        'Cuanners',
        BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF42A5F5).withOpacity(0.85),
              const Color(0xFF64B5F6).withOpacity(0.9),
              const Color(0xFF90CAF9).withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF42A5F5).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        Colors.white,
      );
    }
    
    return TierInfo(
      '',
      BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      Colors.black,
    );
  }

  // Ganti bagian _buildMemberCard di home.dart Anda dengan code ini:

  Widget _buildMemberCard(String nama, String id) {
    final foto = userData?['cos_gambar'];

    return ValueListenableBuilder<int>(
      valueListenable: UserPointData.userPoints,
      builder: (context, points, _) {
        final tierInfo = _getTierInfo(points);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: tierInfo.decoration,
          child: Stack(
            children: [
              // Decorative circles in background
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    color: Colors.blue.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.05),
                  ),
                ),
              ),
              
              // Main content
              Row(
                children: [
                  // Profile picture with glow effect
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: (foto != null && foto.toString().isNotEmpty)
                          ? Image.network(
                              "http://192.168.1.6:8000/storage/$foto",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.blue.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    size: 36,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.blue.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                size: 36,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                nama,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),                         
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            id,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Points section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (tierInfo.label.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTierIcon(tierInfo.label),
                              const SizedBox(width: 4),
                              Text(
                                tierInfo.label,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/image/coin.png',
                              width: 18,
                              height: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$points',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Ganti bagian _buildTierIcon di home.dart Anda dengan code ini:

  Widget _buildTierIcon(String label) {
    switch (label) {
      case 'Cuanners':
        return const Icon(
          Icons.stars_rounded,
          color: Colors.white,
          size: 14,
        );
      case 'Crazy Rich':
        return const Icon(
          Icons.diamond_rounded,
          color: Colors.white,
          size: 14,
        );
      case 'Sultan':
        return const FaIcon(
          FontAwesomeIcons.crown,
          color: Color(0xFFFFEB3B),
          size: 16,
        );
      default:
        return const SizedBox.shrink();
    }
  }

    Widget _buildShimmerMemberCard() => Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(16)), child: Row(children: [Container(width: 60, height: 60, color: Colors.grey[400]), const SizedBox(width: 16), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 100, height: 16, color: Colors.grey[400]), const SizedBox(height: 4), Container(width: 50, height: 14, color: Colors.grey[400])])])));

    Widget _buildProductShimmer() => ListView.builder(scrollDirection: Axis.horizontal, itemCount: 3, itemBuilder: (context, index) => Container(width: 160, margin: const EdgeInsets.only(right: 12), child: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12))))));

    Widget _buildProductList() => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: produkList.length,
          itemBuilder: (context, index) {
            final produk = produkList[index];
            final nama = produk['nama_produk'] ?? 'Produk';
            final harga = produk['harga'] ?? 0;
            final rating = produk['rating'] ?? 0;
            final terjual = produk['terjual'] ?? 0;
            final imageProvider = getImageProvider(produk['gambar']);

            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DetailProdukPage(produk: produk)));
              },
              child: Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 3))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        color: Colors.grey[300],
                        image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
                      ),
                      child: imageProvider == null ? const Center(child: Icon(Icons.image_outlined, color: Colors.white70, size: 36)) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(formatRupiah(harga), style: GoogleFonts.poppins(color: Colors.red.shade700, fontWeight: FontWeight.w500, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(children: [const Icon(Icons.star, color: Colors.amber, size: 14), const SizedBox(width: 4), Text('$rating | $terjual terjual', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700))]),
                      ]),
                    ),
                  ],
                ),
              ),
            );
          },
        );
    }


