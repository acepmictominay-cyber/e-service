import 'package:cached_network_image/cached_network_image.dart';
import 'package:azza_service/Beli/detail_produk.dart';
import 'package:azza_service/Chat/chat_page.dart';
import 'package:azza_service/Home/home.dart';
import 'package:azza_service/Others/notifikasi.dart';
import 'package:azza_service/Profile/profile.dart';
import 'package:azza_service/Promo/promo.dart';
import 'package:azza_service/Service/service.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class ProductCache {
  static List<dynamic> _cachedProdukList = [];
  static int _cachedOffset = 0;
  static bool _hasMoreCached = true;

  static List<dynamic> get cachedProdukList => _cachedProdukList;
  static int get cachedOffset => _cachedOffset;
  static bool get hasMoreCached => _hasMoreCached;

  static void setProducts(List<dynamic> products, int offset, bool hasMore) {
    _cachedProdukList = products;
    _cachedOffset = offset;
    _hasMoreCached = hasMore;
  }

  static void addProducts(
    List<dynamic> newProducts,
    int newOffset,
    bool hasMore,
  ) {
    _cachedProdukList.addAll(newProducts);
    _cachedOffset = newOffset;
    _hasMoreCached = hasMore;
  }

  static void clearCache() {
    _cachedProdukList = [];
    _cachedOffset = 0;
    _hasMoreCached = true;
  }
}

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage>
    with TickerProviderStateMixin {
  int currentIndex = 1;
  String? selectedBrand;
  List<dynamic> _produkList = [];
  List<dynamic> _fullProductList =
      []; // Always contains all loaded products for section filtering
  List<dynamic> _filteredProduk = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final int _displayBatchSize = 20; // Show 20 products at a time in UI
  final int _maxDisplayProducts =
      100; // Maximum products to display to prevent force close

  final List<Map<String, dynamic>> brandsData = [
    {'name': 'Asus', 'logo': 'asus_logo.png', 'needsWhite': true},
    {'name': 'Advan', 'logo': 'advan_logo.png', 'needsWhite': true},
    {'name': 'MSI', 'logo': 'msi_logo.png', 'needsWhite': true},
    {'name': 'HP', 'logo': 'hp_logo.png', 'needsWhite': true},
    {'name': 'Canon', 'logo': 'canon_logo.png', 'needsWhite': true},
    {'name': 'Epson', 'logo': 'epson_logo.png', 'needsWhite': true},
    {'name': 'Legion', 'logo': 'lenovo_logo.png', 'needsWhite': true},
    {'name': 'Infinix', 'logo': 'infinix_logo.png', 'needsWhite': true},
    {'name': 'Zyrex', 'logo': 'zyrex_logo.png', 'needsWhite': true},
    {'name': 'Axio', 'logo': 'axioo_logo.png', 'needsWhite': true},
  ];

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Preload logos setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadLogos();
      // Load cached products or initial products only when needed
      _loadInitialProducts();
    });
  }

  // Preload semua logo untuk performa lebih baik
  void _preloadLogos() {
    for (var brand in brandsData) {
      if (brand['logo'] != null) {
        final logo = AssetImage('assets/image/${brand['logo']}');
        precacheImage(logo, context).catchError((error) {
          // Error preloading logo, ignore
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Load initial products - load ALL products but display only first 20
  Future<void> _loadInitialProducts() async {
    // Always start fresh by loading ALL products from database
    await _loadProduk();
  }

  // Load all products for a specific brand (no pagination)
  Future<void> _loadProdukForBrand(String brand) async {
    try {
      setState(() => _isLoading = true);

      // Ensure we have all products loaded
      if (_fullProductList.isEmpty) {
        await _loadProduk(); // Load all products first
      }

      // Filter products by brand for display
      final brandProducts = _fullProductList.where((p) {
        final apiBrand = (p['brand'] ?? '').toString().toUpperCase();
        final namaProduk = (p['nama_produk'] ?? '').toString().toUpperCase();
        return apiBrand == brand.toUpperCase() ||
            namaProduk.contains(brand.toUpperCase());
      }).toList();

      if (mounted) {
        setState(() {
          _produkList = brandProducts; // Display only brand products
          _filteredProduk = _getFilteredList();
          _hasMoreProducts = false; // No pagination for brand categories
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _loadProduk({bool loadMore = false}) async {
    if (_isLoadingMore && loadMore) {
      return; // Prevent multiple simultaneous loads
    }

    try {
      if (loadMore) {
        setState(() => _isLoadingMore = true);

        // If we have more cached products, load from cache first
        if (ProductCache.cachedProdukList.length > _produkList.length) {
          final nextBatch = ProductCache.cachedProdukList
              .skip(_produkList.length)
              .take(20)
              .toList();
          await Future.delayed(
            const Duration(milliseconds: 300),
          ); // Small delay for UX

          if (mounted) {
            setState(() {
              _produkList.addAll(nextBatch);
              _filteredProduk = _getFilteredList();
              _hasMoreProducts =
                  (ProductCache.cachedProdukList.length > _produkList.length ||
                          ProductCache.hasMoreCached) &&
                      _produkList.length < _maxDisplayProducts;
              _isLoadingMore = false;
            });
          }
          return;
        }

        // Load more from already cached full product list (no API call needed)
        if (_fullProductList.length > _produkList.length) {
          final nextBatch = _fullProductList
              .skip(_produkList.length)
              .take(_displayBatchSize)
              .toList();
          await Future.delayed(
            const Duration(milliseconds: 300),
          ); // Small delay for UX

          if (mounted) {
            setState(() {
              _produkList.addAll(nextBatch);
              _filteredProduk = _getFilteredList();
              _hasMoreProducts = _fullProductList.length > _produkList.length &&
                  _produkList.length < _maxDisplayProducts;
              _isLoadingMore = false;
            });
          }
          return;
        }
      } else {
        setState(() => _isLoading = true);
        _produkList.clear();
      }

      // For initial load, we now load ALL products but display only in batches
      final allProducts = await ApiService.getProduk();

      // Ensure shimmer shows for at least 1 second for better UX
      if (!loadMore) {
        await Future.delayed(const Duration(milliseconds: 800));
      }

      if (mounted) {
        setState(() {
          if (loadMore) {
            // Load more from already cached full product list
            final nextBatch = _fullProductList
                .skip(_produkList.length)
                .take(_displayBatchSize)
                .toList();
            _produkList.addAll(nextBatch);
          } else {
            // Initial load: store all products but display only first batch
            _produkList = allProducts.take(_displayBatchSize).toList();
            _fullProductList = allProducts;
            ProductCache.setProducts(allProducts, allProducts.length, false);
          }

          _filteredProduk = _getFilteredList();
          _hasMoreProducts = _fullProductList.length > _produkList.length &&
              _produkList.length < _maxDisplayProducts;
          _isLoading = false;
          _isLoadingMore = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _hasError = true;
        });
      }
    }
  }

  // PERBAIKAN: Pisahkan logic filter dari setState
  List<dynamic> _getFilteredList() {
    List<dynamic> filtered = List.from(_produkList);

    // Filter berdasarkan brand
    if (selectedBrand != null) {
      final brandUpper = selectedBrand!.toUpperCase();
      filtered = filtered.where((p) {
        final apiBrand = (p['brand'] ?? '').toString().toUpperCase();
        final namaProduk = (p['nama_produk'] ?? '').toString().toUpperCase();
        return apiBrand == brandUpper || namaProduk.contains(brandUpper);
      }).toList();
    }

    // Filter berdasarkan search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (p) =>
                (p['nama_produk'] ?? '').toString().toLowerCase().contains(q),
          )
          .toList();
    }

    // Sort list
    _sortProdukList(filtered);

    return filtered;
  }

  // PERBAIKAN: Method ini hanya untuk update state
  void _applyFilters() {
    setState(() {
      _filteredProduk = _getFilteredList();
    });
  }

  void _sortProdukList(List<dynamic> list) {
    list.sort((a, b) {
      final aHasImage =
          a['gambar_url'] != null && a['gambar_url'].toString().isNotEmpty;
      final bHasImage =
          b['gambar_url'] != null && b['gambar_url'].toString().isNotEmpty;
      if (aHasImage && !bHasImage) return -1;
      if (!aHasImage && bHasImage) return 1;
      final hargaA = double.tryParse(a['harga'].toString()) ?? 0.0;
      final hargaB = double.tryParse(b['harga'].toString()) ?? 0.0;
      return hargaB.compareTo(hargaA);
    });
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

  double _getRatingAsDouble(dynamic rating) {
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) return double.tryParse(rating) ?? 4.5;
    return 4.5;
  }

  String? _getProductBadge(int index) {
    if (index == 0) return 'HOT';
    if (index < 3) return 'BEST SELLER';
    if (index < 5) return 'NEW';
    return null;
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
      final urlList = gambarField
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade500
                  : Colors.black,
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Colors.grey.shade200,
        elevation: 0,
        title: Image.asset('assets/image/logo.png', width: 95, height: 30),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 24,
              ),
              tooltip: 'AI Assistant',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatPage()),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _hasError
              ? _buildErrorWidget()
              : _produkList.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () async {
                        // Clear cache and load ALL products from database, but display only 20 initially
                        ProductCache.clearCache();
                        setState(() {
                          _produkList.clear();
                          _fullProductList.clear();
                          _hasMoreProducts = true;
                          _isLoading = true;
                        });

                        // Load ALL products from database (no pagination limits)
                        try {
                          final result =
                              await ApiService.getProduk(); // Get all products

                          final allProducts = result;

                          if (mounted) {
                            setState(() {
                              _produkList = allProducts
                                  .take(_displayBatchSize)
                                  .toList(); // Show only first 20
                              _fullProductList =
                                  allProducts; // Store all products for Load More
                              ProductCache.setProducts(
                                allProducts,
                                allProducts.length,
                                false,
                              ); // Cache all products
                              _filteredProduk = _getFilteredList();
                              _hasMoreProducts = allProducts.length >
                                      _displayBatchSize &&
                                  _produkList.length <
                                      _maxDisplayProducts; // Show Load More if more than 20 products
                              _isLoading = false;
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                              _hasError = true;
                            });
                          }
                        }
                      },
                      color: const Color(0xFF0041c3),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildSearchBar(),
                            ),
                            const SizedBox(height: 16),
                            _buildBrandList(),
                            const SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildContentBody(),
                            ),
                            // Load More button only for "All Items" category with safety limit
                            if (_hasMoreProducts &&
                                !_isLoading &&
                                selectedBrand == null &&
                                _searchQuery.isEmpty &&
                                _produkList.length < _maxDisplayProducts)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: _isLoadingMore
                                      ? const CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Color(0xFF0041c3),
                                          ),
                                        )
                                      : ElevatedButton(
                                          onPressed: () =>
                                              _loadProduk(loadMore: true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(
                                              context,
                                            ).appBarTheme.backgroundColor,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 32,
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                12,
                                              ),
                                            ),
                                            elevation: 4,
                                          ),
                                          child: Text(
                                            'Muat Lebih Banyak',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBrandList() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: brandsData.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final brand = brandsData[index];
          return _buildBrandChip(
            name: brand['name'],
            logoAsset: brand['logo'],
            needsWhite: brand['needsWhite'] ?? true,
          );
        },
      ),
    );
  }

  Widget _buildBrandChip({
    required String name,
    String? logoAsset,
    required bool needsWhite,
  }) {
    final bool isSelected = (selectedBrand == name);
    final bool hasLogo = logoAsset != null;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBrand = isSelected ? null : name;
        });
        if (selectedBrand != null) {
          // When selecting a brand, load all products for that brand
          _loadProdukForBrand(selectedBrand!);
        } else {
          // When deselecting brand, go back to paginated view with sections
          _loadInitialProducts();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.blue.shade500, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0041c3).withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Center(
          child: hasLogo
              ? SizedBox(
                  height: 26,
                  width: 60,
                  child: _buildBrandLogo(
                    logoAsset: logoAsset,
                    isSelected: isSelected,
                    needsWhite: needsWhite,
                    brandName: name,
                  ),
                )
              : Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBrandLogo({
    required String logoAsset,
    required bool isSelected,
    required bool needsWhite,
    required String brandName,
  }) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        isSelected && needsWhite ? Colors.white : Colors.transparent,
        isSelected && needsWhite ? BlendMode.srcIn : BlendMode.dst,
      ),
      child: Image.asset(
        'assets/image/$logoAsset',
        fit: BoxFit.contain,
        cacheWidth: 120,
        errorBuilder: (context, error, stack) {
          return Text(
            brandName,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
              size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Cari produk impianmu...',
                hintStyle: GoogleFonts.poppins(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_rounded,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600),
              onPressed: () {
                _searchController.clear();
                _searchQuery = '';
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildContentBody() {
    if (_searchQuery.isNotEmpty) return _buildSearchResultsList();
    if (selectedBrand != null) {
      return _buildEnhancedProductGrid(
        list: _filteredProduk,
        title: 'Produk ${selectedBrand!}',
      );
    }
    // Always show sections when no brand is selected, even with limited products
    return Column(
      children: [
        _buildEnhancedProductList(title: '🔥 Produk Terlaris'),
        const SizedBox(height: 28),
        _buildEnhancedProductList(
          title: '🖱️ Koleksi Mouse',
          filterKeyword: 'Mouse',
        ),
        const SizedBox(height: 28),
        _buildEnhancedProductGrid(
          list: _filteredProduk,
          title: '✨ Semua Produk',
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
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
    );
  }

  Widget _buildEnhancedProductList({
    required String title,
    String? filterKeyword,
  }) {
    List<dynamic> produkList = List.from(
      _fullProductList,
    ); // Use full product list for sections
    if (filterKeyword != null) {
      produkList = produkList
          .where(
            (p) => (p['nama_produk'] ?? '')
                .toString()
                .toLowerCase()
                .contains(filterKeyword.toLowerCase()),
          )
          .toList();
    }
    if (produkList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 14),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: produkList.length > 5 ? 5 : produkList.length,
            itemBuilder: (context, index) => _buildEnhancedProductCard(
              produk: produkList[index],
              index: index,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedProductGrid({
    required List<dynamic> list,
    required String title,
  }) {
    if (list.isEmpty && selectedBrand == null && _searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 14),
        if (list.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 50),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 70,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    selectedBrand != null
                        ? 'Tidak ada produk untuk brand ini'
                        : 'Tidak ada produk ditemukan',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade500
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.7,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) => _buildEnhancedProductCard(
              produk: list[index],
              index: index,
              isGrid: true,
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResultsList() {
    if (_filteredProduk.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 70,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ditemukan untuk "$_searchQuery"',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade500
                      : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return _buildEnhancedProductGrid(
      list: _filteredProduk,
      title: 'Hasil Pencarian',
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
        builder: (context, child) => Transform.scale(
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
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
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
                                    : Colors.black,
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

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade50,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              itemBuilder: (context, index) => Shimmer.fromColors(
                baseColor: Colors.grey.shade200,
                highlightColor: Colors.grey.shade50,
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(
            2,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade50,
                      child: Container(
                        width: 160,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      itemBuilder: (_, __) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade200,
                        highlightColor: Colors.grey.shade50,
                        child: Container(
                          width: 190,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 70,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Produk Dimuat',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade500
                    : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Klik tombol di bawah untuk memuat produk terbaru.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProduk,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0041c3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                'Muat Produk',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Koneksi Internet Bermasalah',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade500
                    : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Periksa koneksi Anda dan coba lagi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProduk,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0041c3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Coba Lagi',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return;
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ServicePage()),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
            break;
          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TukarPoinPage()),
            );
            break;
          case 4:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
            break;
          default:
            setState(() => currentIndex = index);
        }
      },
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      selectedItemColor: Colors.white,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 11,
        letterSpacing: 0.2,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.build_circle_outlined),
          activeIcon: Icon(Icons.build_circle),
          label: 'Service',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart),
          label: 'Beli',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.white70, BlendMode.srcIn),
            child: Image(
                image: AssetImage('assets/image/promo.png'),
                width: 24,
                height: 24),
          ),
          activeIcon: ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
            child: Image(
                image: AssetImage('assets/image/promo.png'),
                width: 24,
                height: 24),
          ),
          label: 'Promo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
