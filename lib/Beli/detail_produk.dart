import 'dart:math';
import 'package:azza_service/Others/checkout.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/config/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class DetailProdukPage extends StatefulWidget {
  final Map<String, dynamic> produk;

  const DetailProdukPage({super.key, required this.produk});

  @override
  State<DetailProdukPage> createState() => _DetailProdukPageState();
}

class _DetailProdukPageState extends State<DetailProdukPage>
    with TickerProviderStateMixin {
  int currentIndex = 1;
  String? selectedShipping;
  List<String> imageUrls = [];
  List<dynamic> produkList = [];
  bool isProductLoading = true;

  int quantity = 1;

  // Variable untuk menyimpan nilai random agar tidak berubah-ubah
  late double rating;
  late int sold;
  late int stock;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadImageUrls();
    _loadProducts();

    // Initialize nilai random sekali saja di initState
    rating = _getRandomRating();
    sold = _getRandomSold();
    stock = _getRandomStock();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Enhanced image URL parsing dengan error handling yang lebih baik
  void _loadImageUrls() {
    final gambarField = widget.produk['gambar'];

    if (gambarField != null && gambarField.toString().isNotEmpty) {
      String gambarString = gambarField.toString();

      // Clean up the string
      gambarString =
          gambarString
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .replaceAll('\\', '')
              .trim();

      // Split by comma to get individual paths
      List<String> paths =
          gambarString
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

      // Process each path
      for (String path in paths) {
        String processedPath = _processImagePath(path);
        if (processedPath.isNotEmpty) {
          imageUrls.add(processedPath);
        }
      }
    }

    // Add placeholder if no images found
    if (imageUrls.isEmpty) {
      imageUrls = [''];
    }
  }

  // Helper function to process image paths - handles both assets and network URLs
  String _processImagePath(String path) {
    path = path.trim();

    // If path starts with 'assets/', treat as local asset
    if (path.startsWith('assets/')) {
      return path;
    }

    // For network paths, clean and add base URL
    path =
        path
            .replaceAll('assets/image/', '')
            .replaceAll('assets/', '')
            .replaceAll('image/', '')
            .replaceAll(ApiConfig.storageBaseUrl, '')
            .trim();

    // Ensure the path doesn't start with a slash
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    // Return network URL
    return '${ApiConfig.storageBaseUrl}$path';
  }

  Future<void> _loadProducts() async {
    try {
      final data = await ApiService.getProduk();
      final filtered =
          data.where((p) {
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
    final double correctedNumber = number * 10;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(correctedNumber);
  }

  Widget _buildProductImage(dynamic gambarField, {int currentIndex = 0}) {
    // Extract all available image URLs from the product
    List<String> allImageUrls = _extractAllImageUrls(gambarField);

    // If no URLs found, show fallback
    if (allImageUrls.isEmpty) {
      return Container(
        height: 350,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey.shade300, Colors.grey.shade400],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.white70, size: 36),
        ),
      );
    }

    // Ensure currentIndex is within bounds
    if (currentIndex >= allImageUrls.length) {
      currentIndex = 0;
    }

    String imageUrl = allImageUrls[currentIndex];

    // Process the URL (add base URL if needed)
    imageUrl = _processImageUrl(imageUrl);

    return Container(
      height: 350,
      alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade400,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Try next image URL if available
            if (currentIndex + 1 < allImageUrls.length) {
              return _buildProductImage(
                gambarField,
                currentIndex: currentIndex + 1,
              );
            }

            // All image URLs failed, show fallback
            return Container(
              height: 350,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white70,
                  size: 36,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Extract all image URLs from various formats
  List<String> _extractAllImageUrls(dynamic gambarField) {
    List<String> urls = [];

    if (gambarField is Map && gambarField.containsKey('gambar_url')) {
      final gambarUrlField = gambarField['gambar_url'];

      if (gambarUrlField is List && gambarUrlField.isNotEmpty) {
        urls.addAll(gambarUrlField.map((url) => url.toString().trim()));
      } else if (gambarUrlField is String && gambarUrlField.isNotEmpty) {
        urls.add(gambarUrlField.trim());
      } else {
        // Fallback to regular gambar field
        final gambarBiasa = gambarField['gambar'];
        if (gambarBiasa != null) {
          urls.addAll(_extractAllImageUrls(gambarBiasa));
        }
      }
    } else if (gambarField is List && gambarField.isNotEmpty) {
      urls.addAll(gambarField.map((url) => url.toString().trim()));
    } else if (gambarField is String && gambarField.isNotEmpty) {
      // Split by comma to get multiple URLs
      final urlList =
          gambarField
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
      urls.addAll(urlList);
    }

    return urls.where((url) => url.isNotEmpty).toList();
  }

  // Process image URL to add base URL if needed
  String _processImageUrl(String imageUrl) {
    imageUrl = imageUrl.trim();

    // If already a full URL, return as is
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }

    String baseUrl = ApiConfig.storageBaseUrl;

    // If path already contains assets/image/, just prepend base URL
    if (imageUrl.contains('assets/image/')) {
      return baseUrl + imageUrl;
    } else {
      // Add assets/image/ path
      return '${baseUrl}assets/image/$imageUrl';
    }
  }

  // Generate random rating
  double _getRandomRating() {
    return 3.5 + Random().nextDouble() * 1.5;
  }

  // Generate random sold count
  int _getRandomSold() {
    return 50 + Random().nextInt(450);
  }

  // Generate random stock
  int _getRandomStock() {
    return 10 + Random().nextInt(90);
  }

  String? _getProductBadge(int index) {
    if (index == 0) return 'HOT';
    if (index < 3) return 'BEST SELLER';
    if (index < 5) return 'NEW';
    return null;
  }

  double _getRatingAsDouble(dynamic rating) {
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) return double.tryParse(rating) ?? 4.5;
    return 4.5;
  }


  Color _getBadgeColor(String? badge) {
    switch (badge) {
      case 'HOT':
        return const Color(0xFFFF6B6B);
      case 'BEST SELLER':
        return const Color(0xFFFFB84D);
      case 'NEW':
        return const Color(0xFF51CF66);
      default:
        return const Color(0xFF0041c3);
    }
  }

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

    // Extract all available image URLs from the product
    List<String> allImageUrls = _extractAllImageUrls(gambarField);

    // If no URLs found, show fallback
    if (allImageUrls.isEmpty) {
      return _buildFallbackImageContainer(height, borderRadius);
    }

    // Ensure currentIndex is within bounds
    if (currentIndex >= allImageUrls.length) {
      currentIndex = 0;
    }

    String imageUrl = allImageUrls[currentIndex];

    // Process the URL (add base URL if needed)
    imageUrl = _processImageUrl(imageUrl);

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        height: height,
        width: double.infinity,
        placeholder:
            (context, url) => Container(
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
          // Try next image URL if available
          if (currentIndex + 1 < allImageUrls.length) {
            return _buildImageWithFallback(
              gambarField,
              height,
              fit,
              borderRadius,
              currentIndex: currentIndex + 1,
            );
          }

          // All image URLs failed, show fallback
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color.fromARGB(255, 74, 72, 72),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.grey.shade100, Colors.white],
                      ),
                    ),
                  ),

                  // Main Product Image
                  _buildProductImage(widget.produk['gambar']),
                ],
              ),
            ),
          ),

          // Product Details
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name & Brand
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.produk['nama_produk'] ??
                              'Produk Tidak Dikenal',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.grey[800],
                          ),
                        ),
                        if (widget.produk['brand'] != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.produk['brand'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tampilkan total harga sesuai quantity
                            Text(
                              formatRupiah(
                                (double.tryParse(
                                          widget.produk['harga'].toString(),
                                        ) ??
                                        0) *
                                    quantity,
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.blue[700],
                              ),
                            ),
                            // Tampilkan harga per item jika quantity > 1
                            if (quantity > 1)
                              Text(
                                '${formatRupiah(widget.produk['harga'])} x $quantity',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            Text(
                              formatRupiah(
                                (double.tryParse(
                                          widget.produk['harga'].toString(),
                                        ) ??
                                        0) *
                                    1.2 *
                                    quantity,
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Rating, Sold & Stock
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem(
                            icon: Icons.star,
                            iconColor: Colors.amber,
                            value: rating.toStringAsFixed(1),
                            label: 'Rating',
                          ),
                          _buildDivider(),
                          _buildInfoItem(
                            icon: Icons.shopping_bag_outlined,
                            iconColor: Colors.green,
                            value: '$sold',
                            label: 'Terjual',
                          ),
                          _buildDivider(),
                          _buildInfoItem(
                            icon: Icons.inventory_2_outlined,
                            iconColor: const Color(0xFF0041c3),
                            value: '$stock',
                            label: 'Stok',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Description
                    Text(
                      'Deskripsi Produk',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.produk['deskripsi'] ??
                          'Produk berkualitas tinggi dengan desain modern dan fitur terkini. '
                              'Cocok untuk kebutuhan sehari-hari maupun profesional. '
                              'Dilengkapi dengan teknologi terbaru untuk performa optimal.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.grey[600],
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Recommended Products
                    _buildRecommendedSection('Produk Serupa'),
                    const SizedBox(height: 12),
                    isProductLoading
                        ? _buildProductShimmer()
                        : _buildEnhancedProductList(),

                    const SizedBox(height: 20),

                    _buildRecommendedSection('Rekomendasi Untukmu'),
                    const SizedBox(height: 12),
                    isProductLoading
                        ? _buildProductShimmer()
                        : _buildEnhancedProductList(),

                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Purchase Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity Selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed:
                          quantity > 1
                              ? () {
                                setState(() {
                                  quantity--;
                                });
                              }
                              : null,
                      icon: Icon(
                        Icons.remove,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? (quantity > 1 ? Colors.white : Colors.grey)
                                : (quantity > 1
                                    ? const Color(0xFF0041c3)
                                    : Colors.grey),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$quantity',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          quantity < stock
                              ? () {
                                setState(() {
                                  quantity++;
                                });
                              }
                              : null,
                      icon: Icon(
                        Icons.add,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? (quantity < stock
                                    ? Colors.white
                                    : Colors.grey)
                                : (quantity < stock
                                    ? const Color(0xFF0041c3)
                                    : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Buy Button
              Expanded(
                child: GestureDetector(
                  onTapDown: (_) => _scaleController.forward(),
                  onTapUp: (_) => _scaleController.reverse(),
                  onTapCancel: () => _scaleController.reverse(),
                  onTap: () {
                    _scaleController.reverse();

                    // Buat copy produk dengan quantity dan total harga
                    final produkWithQty = Map<String, dynamic>.from(
                      widget.produk,
                    );
                    produkWithQty['quantity'] = quantity;
                    produkWithQty['total_harga'] =
                        (double.tryParse(widget.produk['harga'].toString()) ??
                            0) *
                        quantity;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CheckoutPage(produk: produkWithQty),
                      ),
                    );
                  },
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[600]!, Colors.blue[700]!],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0041c3).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Beli - ${formatRupiah((double.tryParse(widget.produk['harga'].toString()) ?? 0) * quantity)}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.white30
              : Colors.grey[300],
    );
  }

  Widget _buildRecommendedSection(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.grey[800],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.grey[500],
        ),
      ],
    );
  }

  Widget _buildProductShimmer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder:
            (context, index) => Container(
              width: 160,
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
      ),
    );
  }

  Widget _buildEnhancedProductList() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: produkList.length,
        itemBuilder: (context, index) {
          final produk = produkList[index];
          return _buildEnhancedProductCard(produk: produk, index: index);
        },
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
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        _animationController.reverse();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailProdukPage(produk: produk),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder:
            (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: isGrid ? double.infinity : 190,
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
                          height: isGrid ? 120 : 135,
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
                              isGrid ? 120 : 135,
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
                                    Theme.of(context).brightness ==
                                            Brightness.dark
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
                                    Theme.of(context).brightness ==
                                            Brightness.dark
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
                                    color:
                                        Theme.of(context).brightness ==
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

  // Enhanced getFirstImageUrl with better path cleaning and fallback support
  String getFirstImageUrl(dynamic gambarField) {
    List<String> allUrls = _extractAllImageUrls(gambarField);

    if (allUrls.isEmpty) return '';

    // Return the first valid URL (already processed)
    return _processImageUrl(allUrls.first);
  }
}
