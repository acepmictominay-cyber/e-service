import 'package:azza_service/Chat/chat_page.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:azza_service/Beli/detail_produk.dart';
import 'package:azza_service/Beli/shop.dart' as shop;
import 'package:azza_service/utils/error_utils.dart';
import 'package:azza_service/utils/product_cache.dart';
import 'package:azza_service/Others/session_manager.dart';
import 'package:azza_service/Others/tier_utils.dart';
import 'package:azza_service/Others/user_point_data.dart';
import 'package:azza_service/Profile/profile.dart';
import 'package:azza_service/Promo/promo.dart';
import 'package:azza_service/Service/service.dart';
import 'package:azza_service/Service/tracking_driver.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/artikel/cek_garansi.dart';
import 'package:azza_service/artikel/kebersihan_alat.dart';
import 'package:azza_service/artikel/poin_info.dart';
import 'package:azza_service/artikel/tips.dart';
import 'package:azza_service/config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

// Custom widget that tries multiple URLs for profile images
class _ProfileImageWithFallback extends StatefulWidget {
  final List<String> urls;
  final double radius;

  const _ProfileImageWithFallback({
    required this.urls,
    this.radius = 45,
  });

  @override
  State<_ProfileImageWithFallback> createState() =>
      _ProfileImageWithFallbackState();
}

class _ProfileImageWithFallbackState extends State<_ProfileImageWithFallback> {
  int _currentUrlIndex = 0;
  bool _hasError = false;

  void _tryNextUrl() {
    if (_currentUrlIndex < widget.urls.length - 1) {
      setState(() {
        _currentUrlIndex++;
        _hasError = false;
      });
    } else {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _currentUrlIndex >= widget.urls.length) {
      return Icon(
        Icons.person,
        size: widget.radius * 2 * 0.4, // 40% of diameter
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white70
            : Colors.black.withValues(alpha: 0.7),
      );
    }

    final currentUrl = widget.urls[_currentUrlIndex];

    return Image.network(
      currentUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        _tryNextUrl();
        return Container(); // Will be replaced by next attempt
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(); // Show nothing while loading
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.isFreshLogin = false});

  final bool isFreshLogin;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int currentIndex = 2;
  final ValueNotifier<Map<String, dynamic>?> userData = ValueNotifier(null);
  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<List<dynamic>> produkList = ValueNotifier([]);
  final ValueNotifier<bool> isProductLoading = ValueNotifier(true);

  // Transaction data for status counts
  List<Map<String, dynamic>> serviceTransactions = [];
  List<Map<String, dynamic>> purchaseTransactions = [];
  bool isTransactionLoading = true;

  // Banner data
  final List<String> banners = [
    'assets/image/banner/garansi.jpg',
    'assets/image/banner/tips.png',
    'assets/image/banner/kebersihan.jpg',
    'assets/image/banner/points.png',
  ];

  // non-nullable controller & timer (dijamin diinisialisasi di initState)
  late final PageController _pageController;
  late final Timer _bannerTimer;
  late final AnimationController _animationController;
  late final AnimationController _scaleAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: 1, // mulai dari array ke-2
    );
    _pageController.addListener(_onPageChanged);
    _startBannerTimer();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize scale animation for product cards
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadUserData();
    UserPointData.loadUserPoints();
    _loadProducts();
    _loadTransactionHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh user data when returning to this page
    _loadUserData();
  }

  @override
  void dispose() {
    // karena late final, pasti sudah diinisialisasi di initState
    _pageController.dispose();
    _bannerTimer.cancel();
    _animationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  // Helper untuk generate badge status
  String? _getProductBadge(int index) {
    if (index == 0) return 'HOT';
    if (index < 3) return 'BEST SELLER';
    if (index < 5) return 'NEW';
    return null;
  }

  // Helper untuk get badge color
  Color _getBadgeColor(String? badge) {
    switch (badge) {
      case 'HOT':
        return Colors.red;
      case 'BEST SELLER':
        return Colors.orange;
      case 'NEW':
        return Colors.green;
      default:
        return const Color(0xFF0041c3);
    }
  }

  double _getRatingAsDouble(dynamic rating) {
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) return double.tryParse(rating) ?? 4.5;
    return 4.5;
  }

  // =======================
  // 🔹 MIDTRANS INIT - REMOVED
  // =======================
  // Midtrans SDK initialization removed - now using redirect_url approach

  // =======================
  // 🔹 UTIL FUNCTIONS
  // =======================

  // Status helpers for filter card
  String _getStatusLabel(String status) {
    final labels = {
      'pending': 'Menunggu',
      'confirm': 'Disetujui',
      'in_progress': 'Diproses',
      'on_the_way': 'Dalam Perjalanan',
      'completed': 'Selesai',
      'paid': 'Dibayar',
      'diproses': 'Diproses',
      'dikirim': 'Dikirim',
      'selesai': 'Selesai',
      'menunggu': 'Menunggu',
      'pending_shipping_payment': 'Menunggu Pembayaran Ongkir',
      'cancelled': 'Dibatalkan',
    };
    return labels[status.toLowerCase()] ?? status;
  }

  Color _getStatusColor(String status) {
    final colors = {
      'pending': Colors.orange,
      'confirm': Colors.blue,
      'in_progress': Colors.indigo,
      'on_the_way': Colors.purple,
      'completed': Colors.green,
      'paid': Colors.green,
      'diproses': Colors.blue,
      'dikirim': Colors.purple,
      'selesai': Colors.green,
      'menunggu': Colors.orange,
      'pending_shipping_payment': Colors.orange,
      'cancelled': Colors.red,
    };
    return colors[status.toLowerCase()] ?? Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    final icons = {
      'pending': Icons.hourglass_empty,
      'confirm': Icons.thumb_up_outlined,
      'in_progress': Icons.engineering,
      'on_the_way': Icons.local_shipping,
      'completed': Icons.check_circle,
      'paid': Icons.payment,
      'diproses': Icons.inventory,
      'dikirim': Icons.local_shipping,
      'selesai': Icons.check_circle,
      'menunggu': Icons.hourglass_empty,
      'pending_shipping_payment': Icons.payment,
      'cancelled': Icons.cancel,
    };
    return icons[status.toLowerCase()] ?? Icons.help_outline;
  }

  String getFirstImageUrl(dynamic gambarField) {
    if (gambarField == null) return '';

    if (gambarField is List && gambarField.isNotEmpty) {
      return '${ApiConfig.storageBaseUrl}${gambarField.first}';
    }

    if (gambarField is String && gambarField.isNotEmpty) {
      try {
        if (gambarField.contains('[')) {
          final List list = List<String>.from(jsonDecode(gambarField));
          if (list.isNotEmpty) {
            return '${ApiConfig.storageBaseUrl}${list.first}';
          }
        }
      } catch (_) {}
      return '${ApiConfig.storageBaseUrl}$gambarField';
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

    // NOTE: Multiply by 10 to match backend price format
    // Backend stores prices in smallest currency unit (e.g., rupiah)
    // Frontend displays in standard format, so multiply by 10 for correct display
    // Example: backend price 50000 = frontend display Rp 500,000
    number *= 10;

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final result = formatter.format(number);

    return result;
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
        userData.value = data;
        isLoading.value = false;
      } catch (e) {
        isLoading.value = false;
        if (mounted) {
          ErrorUtils.showErrorSnackBar(context, e,
              customMessage: 'Gagal: Periksa koneksi Anda dan coba lagi');
        }
      }
    } else {
      isLoading.value = false;
    }
  }

  Future<void> _loadProducts() async {
    try {
      // Check if products are already cached from shop.dart
      if (ProductCache.productsLoaded &&
          ProductCache.cachedProdukList.isNotEmpty) {
        // Use cached products
        final filtered = ProductCache.cachedProdukList.where((p) {
          final gambar = p['gambar']?.toString().trim() ?? '';
          return gambar.isNotEmpty;
        }).toList();
        produkList.value = filtered;
        isProductLoading.value = false;
      } else {
        // Load products fresh and cache them
        final data = await ApiService.getProduk();
        final filtered = data.where((p) {
          final gambar = p['gambar']?.toString().trim() ?? '';
          return gambar.isNotEmpty;
        }).toList();
        produkList.value = filtered;
        isProductLoading.value = false;
        // Also cache for shop.dart
        ProductCache.setProducts(filtered);
      }
    } catch (e) {
      isProductLoading.value = false;
    }
  }

  Future<void> _loadTransactionHistory() async {
    if (!mounted) return;
    setState(() => isTransactionLoading = true);

    try {
      final session = await SessionManager.getUserSession();
      final userCosKode = session['id']?.toString();
      if (userCosKode == null || userCosKode.isEmpty) {
        _setEmptyTransactions();
        return;
      }

      // Fetch service transactions
      final serviceData = await ApiService.getOrderList();

      // Fetch purchase transactions
      final purchaseData = await ApiService.getCustomerOrders(userCosKode);

      if (!mounted) return;

      // Process service transactions
      final tempService = <Map<String, dynamic>>[];
      for (final transaksi in serviceData) {
        final transCosKode = transaksi['cos_kode']?.toString();
        if (transCosKode == userCosKode) {
          tempService.add(Map<String, dynamic>.from(transaksi));
        }
      }
    
      // Process purchase transactions
      final tempPurchase = <Map<String, dynamic>>[];
      for (final orderData in purchaseData) {
        final order = orderData['order'];
        if (order == null) continue;

        final orderCode = order['order_code']?.toString();
        if (orderCode == null || orderCode.isEmpty) continue;

        tempPurchase.add({
          'order_code': orderCode,
          'total_payment':
              order['total_payment'] ?? order['total_price'] ?? 0,
          'created_at': order['created_at'],
          'payment_status':
              order['payment_status']?.toString().toLowerCase() ?? 'pending',
          'delivery_status':
              order['delivery_status']?.toString().toLowerCase() ??
                  'menunggu',
          'payment_method': order['payment_method'] ?? 'N/A',
          'expedition_type': order['expedition_type'] ?? 'N/A',
          'items': orderData['items'] ?? [],
        });
      }
    
      // Sort by date (newest first)
      tempService.sort(
        (a, b) => _compareDate(b['trans_tanggal'], a['trans_tanggal']),
      );
      tempPurchase.sort(
        (a, b) => _compareDate(b['created_at'], a['created_at']),
      );

      setState(() {
        serviceTransactions = tempService;
        purchaseTransactions = tempPurchase;
        isTransactionLoading = false;
      });
    } catch (e) {
      if (mounted) _setEmptyTransactions();
    }
  }

  void _setEmptyTransactions() {
    setState(() {
      serviceTransactions = [];
      purchaseTransactions = [];
      isTransactionLoading = false;
    });
  }

  int _compareDate(String? a, String? b) {
    final dateA = DateTime.tryParse(a ?? '') ?? DateTime(1900);
    final dateB = DateTime.tryParse(b ?? '') ?? DateTime(1900);
    return dateA.compareTo(dateB);
  }

  int _getServiceCountByStatus(String status) {
    return serviceTransactions.where((t) {
      final transStatus = t['trans_status']?.toString().toLowerCase() ?? '';
      return transStatus == status.toLowerCase();
    }).length;
  }

  int _getPurchaseCountByStatus(String status) {
    return purchaseTransactions.where((t) {
      final paymentStatus = t['payment_status']?.toString().toLowerCase() ?? '';
      final deliveryStatus =
          t['delivery_status']?.toString().toLowerCase() ?? '';
      final paymentMethod = t['payment_method']?.toString().toLowerCase() ?? '';

      if (status == 'pending') {
        return paymentStatus == 'pending' &&
            paymentMethod != 'pending_shipping_payment';
      } else if (status == 'paid') {
        return paymentStatus == 'paid' && deliveryStatus != 'selesai';
      } else if (status == 'diproses') {
        return deliveryStatus == 'diproses';
      } else if (status == 'dikirim') {
        return deliveryStatus == 'dikirim';
      } else if (status == 'selesai') {
        return deliveryStatus == 'selesai';
      } else if (status == 'pending_shipping_payment') {
        return paymentMethod == 'pending_shipping_payment';
      } else if (status == 'cancelled') {
        return paymentStatus == 'cancelled' || deliveryStatus == 'cancelled';
      }
      return false;
    }).length;
  }

  // =======================
  // 🔹 BANNER LOOP HALUS
  // =======================

  void _onPageChanged() {
    // Banner index tracking removed as it's unused
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        final int total =
            banners.length; // Use actual banner count instead of hardcoded 5

        // DEBUG: Log banner timer activity
        if (kDebugMode) {
        }

        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _buildBannerSlider() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: banners.length * 1000, // efek looping panjang
            itemBuilder: (context, index) {
              final int realIndex = index % banners.length;

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page! - index).abs();
                    value = (1 - (value * 0.1)).clamp(0.9, 1.0);
                  }
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: banners[realIndex].startsWith('assets/')
                          ? AssetImage(banners[realIndex])
                          : NetworkImage(banners[realIndex]),
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
                          Colors.black.withValues(alpha: 0.6),
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
                          Semantics(
                            label: realIndex == 0
                                ? 'Lihat informasi cek garansi'
                                : realIndex == 1
                                    ? 'Lihat tips perawatan'
                                    : realIndex == 2
                                        ? 'Lihat tips kebersihan alat'
                                        : 'Lihat informasi poin',
                            button: true,
                            child: ElevatedButton(
                              onPressed: () {
                                if (realIndex == 0) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CekGaransiPage(),
                                    ),
                                  );
                                } else if (realIndex == 1) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TipsPage(),
                                    ),
                                  );
                                } else if (realIndex == 2) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const KebersihanAlatPage(),
                                    ),
                                  );
                                } else if (realIndex == 3) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PoinInfoPage(),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0041c3),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Lihat Sekarang',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Image.asset('assets/image/logo.png', width: 95, height: 30),
        actions: [
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<Map<String, dynamic>?>(
              valueListenable: userData,
              builder: (context, userDataValue, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: isLoading,
                  builder: (context, loading, _) {
                    if (loading) return _buildShimmerMemberCard();
                    final nama = userDataValue?['cos_nama'] ?? '-';
                    final id = userDataValue?['id_costomer'] ?? '-';
                    return _buildMemberCard(nama, id);
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            _buildHomeStatusGrid(),
            const SizedBox(height: 10),
            SizedBox(height: 180, child: _buildBannerSlider()),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🔥 Hot Items',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: ValueListenableBuilder<bool>(
                valueListenable: isProductLoading,
                builder: (context, loading, _) {
                  if (loading) return _buildProductShimmer();
                  return ValueListenableBuilder<List<dynamic>>(
                    valueListenable: produkList,
                    builder: (context, products, _) {
                      if (products.isEmpty) {
                        return const Center(
                          child: Text("Tidak ada produk dengan gambar"),
                        );
                      }
                      return _buildEnhancedProductList(products);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
              MaterialPageRoute(
                builder: (context) => const shop.MarketplacePage(),
              ),
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
          } else {
            setState(() {
              currentIndex = index;
            });
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
              colorFilter:
                  const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
              child: Image.asset(
                'assets/image/promo.png',
                width: 24,
                height: 24,
              ),
            ),
            activeIcon: ColorFiltered(
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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

  // =======================
  // 🔹 WIDGET HELPERS
  // =======================

  // Status filter card for home
  Widget _buildHomeStatusGrid() {
    final statuses = [
      'pending',
      'confirm',
      'in_progress',
      'completed',
      'paid',
      'dikirim',
      'selesai'
    ];

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(
                  Icons.filter_list,
                  size: 16,
                  color: Color(0xFF0041c3),
                ),
                const SizedBox(width: 8),
                Text(
                  'Status Terbaru',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(4, 0, 16, 8),
              child: Row(
                children: statuses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final status = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < statuses.length - 1 ? 8 : 0,
                    ),
                    child: _buildHomeStatusChip(status),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeStatusChip(String status) {
    final color = _getStatusColor(status);
    // Get actual counts from database
    int count = 0;
    if (status == 'pending' ||
        status == 'confirm' ||
        status == 'in_progress' ||
        status == 'completed') {
      count = _getServiceCountByStatus(status);
    } else if (status == 'paid' || status == 'dikirim' || status == 'selesai') {
      count = _getPurchaseCountByStatus(status);
    }

    return GestureDetector(
      onTap: () {
        // Navigate to tracking page - get real queue code from order
        String? queueCode = 'SAMPLE123'; // Default for demo, should get from actual order
        
        // Try to get actual order code from recent orders if available
        // This would typically come from the order that was just placed
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackingPage(queueCode: queueCode),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getStatusIcon(status), size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  _getStatusLabel(status),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Badge
          if (count > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Ganti bagian _buildMemberCard di home.dart Anda dengan code ini:

  Widget _buildMemberCard(String nama, String id) {
    final foto = userData.value?['cos_gambar'];

    return ValueListenableBuilder<int>(
      valueListenable: UserPointData.userPoints,
      builder: (context, points, _) {
        final tierInfo = getTierInfo(points);

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
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
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
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: (foto != null && foto.toString().isNotEmpty)
                          ? (() {
                              String rawPath = foto.toString();
                              // Remove leading slash if present to avoid double slashes
                              String cleanPath = rawPath.startsWith('/')
                                  ? rawPath.substring(1)
                                  : rawPath;

                              // Try multiple URLs in case storage link is not working
                              final possibleUrls = [
                                "${ApiConfig.storageBaseUrl}$cleanPath", // Laravel storage link
                                "${ApiConfig.serverIp}/storage/$cleanPath", // Direct storage access
                                "${ApiConfig.serverIp}/$cleanPath", // Direct public access
                              ];

                              return _ProfileImageWithFallback(
                                  urls: possibleUrls, radius: 32);
                            })()
                          : Icon(
                              Icons.person,
                              size: 36,
                              color: Colors.white.withValues(alpha: 0.7),
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
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            id,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.9),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/logo/point.png',
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

  Widget _buildShimmerMemberCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[700] : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 16,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 4),
                Container(
                  width: 50,
                  height: 14,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductShimmer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        width: 180,
        height: 240, // Add explicit height to match product card height
        margin: const EdgeInsets.only(right: 12),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced Product Card - Tanpa diskon
  Widget _buildImageWithFallback(
    dynamic gambarField,
    double height,
    BoxFit fit,
    BorderRadius borderRadius, {
    int currentIndex = 0,
  }) {

    // Cek apakah gambarField null atau empty
    if (gambarField == null || (gambarField is String && gambarField.isEmpty)) {
      return _buildFallbackImageContainer(height, borderRadius);
    }

    String imageUrl = '';

    // Prioritas: gunakan gambar_url jika tersedia (dari accessor backend)
    if (gambarField is Map && gambarField.containsKey('gambar_url')) {
      final gambarUrlField = gambarField['gambar_url'];

      if (gambarUrlField is List && gambarUrlField.isNotEmpty) {
        // Jika array URL dari backend
        if (currentIndex < gambarUrlField.length) {
          imageUrl = gambarUrlField[currentIndex].toString();
        } else {
          imageUrl = gambarUrlField[0].toString();
        }
      } else if (gambarUrlField is String && gambarUrlField.isNotEmpty) {
        // Jika single URL string
        imageUrl = gambarUrlField;
      } else {
        // Fallback ke field gambar biasa
        final gambarBiasa = gambarField['gambar'];
        if (gambarBiasa != null) {
          return _buildImageWithFallback(
            gambarBiasa,
            height,
            fit,
            borderRadius,
            currentIndex: currentIndex,
          );
        }
        return _buildFallbackImageContainer(height, borderRadius);
      }
    }
    // Jika gambarField adalah array (dari gambar_url accessor)
    else if (gambarField is List && gambarField.isNotEmpty) {
      // Jika array, ambil index yang diminta
      if (currentIndex < gambarField.length) {
        imageUrl = gambarField[currentIndex].toString();
      } else {
        imageUrl = gambarField[0].toString();
      }
    }
    // Jika gambarField adalah string (URL lengkap atau path)
    else if (gambarField is String && gambarField.isNotEmpty) {

      // Check if string contains multiple URLs separated by commas
      if (gambarField.contains(',')) {
        final urlList = gambarField
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (urlList.isNotEmpty) {
          if (currentIndex < urlList.length) {
            imageUrl = urlList[currentIndex];
          } else {
            imageUrl = urlList[0];
          }
        } else {
          return _buildFallbackImageContainer(height, borderRadius);
        }
      } else {
        imageUrl = gambarField;
      }

      // Jika belum lengkap, tambahkan base URL
      if (!imageUrl.startsWith('http')) {
        if (imageUrl.contains('assets/image/')) {
          imageUrl = ApiConfig.storageBaseUrl + imageUrl;
        } else {
          imageUrl = '${ApiConfig.storageBaseUrl}assets/image/$imageUrl';
        }
      }
    } else {
      return _buildFallbackImageContainer(height, borderRadius);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        height: height,
        width: double.infinity,
        placeholder: (context, url) => Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey.shade100, Colors.grey.shade200],
            ),
          ),
          child: Center(
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade50,
              child: Container(
                height: height,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: borderRadius,
                ),
              ),
            ),
          ),
        ),
        errorWidget: (context, error, stackTrace) {

          // Jika gambarField adalah array dan masih ada gambar lain, coba gambar berikutnya
          if (gambarField is List && currentIndex + 1 < gambarField.length) {
            return _buildImageWithFallback(
              gambarField,
              height,
              fit,
              borderRadius,
              currentIndex: currentIndex + 1,
            );
          }

          return _buildFallbackImageContainer(height, borderRadius);
        },
      ),
    );
  }

  Widget _buildFallbackImageContainer(
    double height,
    BorderRadius borderRadius,
  ) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade200, Colors.grey.shade300],
        ),
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey.shade400,
            size: 40,
          ),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProductCard({
    required Map<String, dynamic> produk,
    required int index,
    bool isGrid = false,
  }) {
    final badge = _getProductBadge(index);
    final rating = _getRatingAsDouble(produk['rating']);

    return GestureDetector(
      onTapDown: (_) => _scaleAnimationController.forward(),
      onTapUp: (_) => _scaleAnimationController.reverse(),
      onTapCancel: () => _scaleAnimationController.reverse(),
      onTap: () {
        _scaleAnimationController.reverse();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailProdukPage(produk: produk),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: isGrid ? double.infinity : 190,
            height: 240,
            margin: EdgeInsets.only(right: isGrid ? 0 : 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF0041c3).withValues(alpha: 0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: isGrid ? 120 : 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.grey.shade50,
                            Colors.grey.shade100,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: _buildImageWithFallback(
                          produk['gambar'],
                          isGrid ? 120 : 120,
                          BoxFit.contain,
                          BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (badge != null)
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
                                _getBadgeColor(badge),
                                _getBadgeColor(badge).withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: _getBadgeColor(
                                  badge,
                                ).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            badge,
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          produk['nama_produk'] ?? 'Produk Tanpa Nama',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: isGrid ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.grey.shade800,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatRupiah(produk['harga']),
                          style: GoogleFonts.poppins(
                            fontSize: isGrid ? 14 : 15,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.blue.shade700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Colors.amber.shade600,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey.shade700,
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
        ),
      ),
    );
  }

  // Enhanced Product List
  Widget _buildEnhancedProductList(List<dynamic> products) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: products.length,
      itemBuilder: (context, index) {
        final produk = Map<String, dynamic>.from(products[index]);
        return _buildEnhancedProductCard(produk: produk, index: index);
      },
    );
  }
}
