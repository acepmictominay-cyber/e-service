import 'dart:convert';
import 'package:e_service/Beli/shop.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/checkout.dart';
import 'package:e_service/Profile/profile.dart';
import 'package:e_service/Promo/promo.dart';
import 'package:e_service/Service/Service.dart';
import 'package:e_service/api_services/api_service.dart';
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

class _DetailProdukPageState extends State<DetailProdukPage> {
  int currentIndex = 1;
  String? selectedShipping;
  List<String> imageUrls = []; // List untuk menyimpan semua URL gambar
  int _currentImageIndex = 0; // Index gambar saat ini untuk indicator
  List<dynamic> produkList = []; // Untuk rekomendasi produk
  bool isProductLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImageUrls();
    _loadProducts(); // Load produk untuk rekomendasi
  }

  // Fungsi untuk mendapatkan semua URL gambar dari produk
  void _loadImageUrls() {
    final gambarField = widget.produk['gambar'];
    if (gambarField != null) {
      if (gambarField is List && gambarField.isNotEmpty) {
        imageUrls = gambarField.map<String>((img) => 'http://192.168.1.6:8000/storage/$img').toList();
      } else if (gambarField is String && gambarField.isNotEmpty) {
        try {
          if (gambarField.contains('[')) {
            // JSON array
            final List list = List<String>.from(jsonDecode(gambarField));
            imageUrls = list.map<String>((img) => 'http://192.168.1.6:8000/storage/$img').toList();
          } else {
            // Split by comma (untuk string dengan koma sebagai pemisah)
            final List<String> list = gambarField.split(',').map((s) => s.trim()).toList();
            imageUrls = list.map<String>((img) => 'http://192.168.1.6:8000/storage/$img').toList();
          }
        } catch (_) {
          // Fallback jika parsing gagal
          imageUrls = ['http://192.168.1.6:8000/storage/$gambarField'];
        }
      }
    }
    if (imageUrls.isEmpty) {
      imageUrls = ['']; // Placeholder jika tidak ada gambar
    }
  }

  // Load produk untuk rekomendasi (mirip HomePage)
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

  // Fungsi untuk format Rupiah (mirip HomePage)
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

  // Fungsi untuk mendapatkan ImageProvider (mirip HomePage)
  ImageProvider? getImageProvider(String url) {
    if (url.isEmpty) return null;
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/image/logo.png', height: 30),
            Image.asset('assets/image/asus_logo.png', height: 20),
            const Spacer(),
            const Icon(Icons.notifications_none, color: Colors.white),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==== GAMBAR PRODUK (SLIDER) ====
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF90CAF9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: imageUrls.isNotEmpty && imageUrls.first.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: imageUrls.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final imageUrl = imageUrls[index];
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                        // Indicator Dots
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              imageUrls.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentImageIndex == index ? 10 : 6,
                                height: _currentImageIndex == index ? 10 : 6,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index
                                      ? Colors.blue
                                      : Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Icon(Icons.image_outlined,
                          color: Colors.white70, size: 64),
                    ),
            ),
            const SizedBox(height: 12),

            // ==== NAMA PRODUK ====
            Text(
              widget.produk['nama_produk'] ?? 'Produk Tidak Dikenal',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // ==== BRAND PRODUK ====
            if (widget.produk['brand'] != null)
              Text(
                widget.produk['brand'],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

            const SizedBox(height: 10),

            // ==== DESKRIPSI ====
            Text(
              widget.produk['deskripsi'] ??
                  'Deskripsi produk belum tersedia untuk item ini.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 10),

            // ==== HARGA ====
            Text(
              formatRupiah(widget.produk['harga']),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0B4D3B),
              ),
            ),
            const SizedBox(height: 8),

            // ==== TOMBOL BELI ====
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutPage(
                      produk: widget.produk,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              label: Text(
                'Beli',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
            ),

            const SizedBox(height: 16),

            // ==== LAINNYA (REKOMENDASI) ====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lainnya',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.black54),
              ],
            ),
            const SizedBox(height: 8),
            isProductLoading ? _buildProductShimmer() : _buildProductList(),

            const SizedBox(height: 16),

            // ==== SERUPA (REKOMENDASI LAIN) ====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Serupa',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.black54),
              ],
            ),
            const SizedBox(height: 8),
            isProductLoading ? _buildProductShimmer() : _buildProductList(),
          ],
        ),
      ),

      // ===== Bottom Navigation Bar =====
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
          } else {
            setState(() {
              currentIndex = index;
            });
          }
        },
        backgroundColor: const Color(0xFF1976D2),
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
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: currentIndex == 3
                ? Image.asset(
                    'assets/image/promo.png',
                    width: 24,
                    height: 24,
                    color: Colors.white,
                  )
                : Opacity(
                    opacity: 0.6,
                    child: Image.asset(
                      'assets/image/promo.png',
                      width: 24,
                      height: 24,
                      color: Colors.white,
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

  // Widget untuk shimmer loading produk
  Widget _buildProductShimmer() => SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (context, index) => Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      );

  // Widget untuk list produk rekomendasi (mirip HomePage)
  Widget _buildProductList() => SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: produkList.length,
          itemBuilder: (context, index) {
            final produk = produkList[index];
            final nama = produk['nama_produk'] ?? 'Produk';
            final harga = produk['harga'] ?? 0;
            final imageProvider = getImageProvider(getFirstImageUrl(produk['gambar']));

            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DetailProdukPage(produk: produk)));
              },
              child: Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        color: Colors.grey[300],
                        image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
                      ),
                      child: imageProvider == null ? const Center(child: Icon(Icons.image_outlined, color: Colors.white70, size: 36)) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          Text(
                            formatRupiah(harga),
                            style: GoogleFonts.poppins(color: Colors.red.shade700, fontWeight: FontWeight.w500, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  // Fungsi untuk mendapatkan URL gambar pertama (mirip HomePage)
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
        } else {
          // Split by comma
          final List<String> list = gambarField.split(',').map((s) => s.trim()).toList();
          if (list.isNotEmpty) {
            return 'http://192.168.1.6:8000/storage/${list.first}';
          }
        }
      } catch (_) {}
      return 'http://192.168.1.6:8000/storage/$gambarField';
    }

    return '';
  }

  void _showShippingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih Ekspedisi",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              _shippingItem(Icons.local_shipping, "J&T"),
              _shippingItem(Icons.delivery_dining, "SiCepat"),
              _shippingItem(Icons.local_shipping_outlined, "JNE"),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _shippingItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: () {
        setState(() {
          selectedShipping = label;
        });
        Navigator.pop(context);
      },
    );
  }

  IconData _getShippingIcon(String shipping) {
    switch (shipping) {
      case "J&T":
        return Icons.local_shipping;
      case "SiCepat":
        return Icons.delivery_dining;
      case "JNE":
        return Icons.local_shipping_outlined;
      default:
        return Icons.local_shipping;
    }
  }
}