import 'package:azza_service/Service/detail_alamat.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../api_services/payment_service.dart';
import '../api_services/api_service.dart';
import '../Others/session_manager.dart';
import '../models/promo_model.dart';
import '../models/voucher_model.dart';
import '../config/api_config.dart';
import 'custom_dialog.dart';
import '../main.dart';
import 'riwayat.dart';
import 'xendit_payment_page.dart';
import '../utils/error_handler.dart' as error_handler;

class PaymentModal extends StatefulWidget {
  final String? initialPaymentMethod;
  final String? initialSelectedBank;
  final double totalPrice;
  final Function(String, String?) onPaymentConfirmed;
  final Function(void Function())? setModalState;

  const PaymentModal({
    super.key,
    this.initialPaymentMethod,
    this.initialSelectedBank,
    required this.totalPrice,
    required this.onPaymentConfirmed,
    this.setModalState,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  String? selectedPaymentMethod;
  String? selectedBank;

  @override
  void initState() {
    super.initState();
    selectedPaymentMethod = widget.initialPaymentMethod;
    selectedBank = widget.initialSelectedBank;
  }

  @override
  Widget build(BuildContext context) {
    // Use provided setState or default setState
    final stateSetter = widget.setModalState ?? setState;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Konfirmasi Pembayaran',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          // DEBUG: Log theme-adaptive color usage
          Builder(
            builder: (context) {
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),

          // Metode Pembayaran
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Metode Pembayaran",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                // DEBUG: Log theme-adaptive color usage for payment method title
                Builder(
                  builder: (context) {
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodOption(
                  "QRIS",
                  "Scan QR code untuk pembayaran",
                  Icons.qr_code_2,
                  selectedPaymentMethod == "QRIS",
                  () => stateSetter(() {
                    selectedPaymentMethod = "QRIS";
                    selectedBank = null;
                  }),
                  available: false,
                ),
                const SizedBox(height: 8),
                _buildPaymentMethodOption(
                  "Transfer Bank",
                  "Transfer ke rekening bank",
                  Icons.account_balance,
                  selectedPaymentMethod == "Transfer Bank",
                  () => stateSetter(() {
                    selectedPaymentMethod = "Transfer Bank";
                    selectedBank = null;
                  }),
                  available: false,
                ),
                const SizedBox(height: 8),
                _buildPaymentMethodOption(
                  "E-wallet",
                  "GoPay, OVO, Dana, LinkAja",
                  Icons.account_balance_wallet,
                  selectedPaymentMethod == "E-wallet",
                  () => stateSetter(() {
                    selectedPaymentMethod = "E-wallet";
                    selectedBank = null;
                  }),
                  available: false,
                ),
                const SizedBox(height: 8),
                _buildPaymentMethodOption(
                  "Transfer Bank Online",
                  "Transfer langsung via internet banking",
                  Icons.account_balance,
                  selectedPaymentMethod == "Transfer Bank Online",
                  () => stateSetter(() {
                    selectedPaymentMethod = "Transfer Bank Online";
                    selectedBank = null;
                  }),
                  available: false,
                ),
              ],
            ),
          ),

          // Bank Selection (only show when Transfer Bank is selected)
          if (selectedPaymentMethod == "Transfer Bank") ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pilih Bank",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBank,
                    hint: const Text("Pilih bank untuk transfer"),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF0041c3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "BCA", child: Text("BCA")),
                      DropdownMenuItem(value: "BRI", child: Text("BRI")),
                      DropdownMenuItem(
                        value: "Mandiri",
                        child: Text("Mandiri"),
                      ),
                      DropdownMenuItem(value: "BNI", child: Text("BNI")),
                      DropdownMenuItem(
                        value: "CIMB Niaga",
                        child: Text("CIMB Niaga"),
                      ),
                    ],
                    onChanged: (value) =>
                        stateSetter(() => selectedBank = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Mohon pilih bank';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],

          // E-wallet Selection (only show when E-wallet is selected)
          if (selectedPaymentMethod == "E-wallet") ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pilih E-wallet",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue:
                        selectedBank, // Reuse selectedBank for e-wallet selection
                    hint: const Text("Pilih e-wallet untuk pembayaran"),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF0041c3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: "GoPay", child: Text("GoPay (Coming Soon)")),
                      DropdownMenuItem(value: "OVO", child: Text("OVO")),
                      DropdownMenuItem(
                          value: "DANA", child: Text("DANA (Coming Soon)")),
                    ],
                    onChanged: (value) =>
                        stateSetter(() => selectedBank = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Mohon pilih e-wallet';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Total Pembayaran
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue[900]!.withValues(alpha: 0.3)
                  : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue[700]!
                    : Colors.blue[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Pembayaran',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // DEBUG: Log theme-adaptive color usage for total payment label
                Builder(
                  builder: (context) {
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(widget.totalPrice),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Button Bayar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Validate bank selection for Transfer Bank
                if (selectedPaymentMethod == "Transfer Bank" &&
                    selectedBank == null) {
                  CustomDialog.show(
                    context: context,
                    icon: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    title: 'Peringatan',
                    content: const Text('Mohon pilih bank untuk transfer'),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  );
                  return;
                }

                // Validate e-wallet selection for E-wallet
                if (selectedPaymentMethod == "E-wallet" &&
                    selectedBank == null) {
                  CustomDialog.show(
                    context: context,
                    icon: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    title: 'Peringatan',
                    content: const Text(
                      'Mohon pilih e-wallet untuk pembayaran',
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  );
                  return;
                }

                widget.onPaymentConfirmed(selectedPaymentMethod!, selectedBank);
              },
              icon: const Icon(Icons.payment, size: 20),
              label: const Text(
                'Bayar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0041c3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    VoidCallback onTap, {
    bool available = true,
  }) {
    return InkWell(
      onTap: available ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF0041c3) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? const Color(0xFF0041c3).withOpacity(0.1)
              : (available ? Colors.white : Colors.grey.shade50),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF0041c3)
                  : (available ? Colors.grey : Colors.grey.shade400),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF0041c3)
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87),
                        ),
                      ),
                      if (!available) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Coming Soon',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // DEBUG: Log theme-adaptive color usage in payment option
                  if (!isSelected)
                    Builder(
                      builder: (context) {
                        return const SizedBox.shrink();
                      },
                    ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF0041c3),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> produk;
  final bool usePointsFromPromo;
  const CheckoutPage({
    super.key,
    required this.produk,
    this.usePointsFromPromo = false,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  late BuildContext pageContext;
  String? selectedPaymentMethod;
  String? selectedShipping;
  String? selectedBank;
  Map<String, dynamic>? selectedAddress;
  Map<String, dynamic>? userData;
  bool useVoucher = false;
  String? selectedVoucher;
  String? selectedEwallet;
  late String namaProduk;
  late String deskripsi;
  String gambarUrl = '';
  List<Promo> promoList = [];
  bool isPromoLoaded = false;
  List<UserVoucher> userVouchers = [];
  bool isUserVouchersLoaded = false;
  double? hargaAsli;
  double totalHarga = 0.0;

  // Inisialisasi quantity
  late int quantity;

  // Shipping data
  double? customerLat;
  double? customerLng;
  double shippingCost = 0.0;
  double distanceKm = 0.0;
  bool isLoadingShipping = false;
  bool isCalculatingShipping = false;

  // List voucher
  final List<Map<String, dynamic>> availableVouchers = [
    {
      'code': 'DISKON10',
      'name': 'Diskon 10%',
      'description': 'Potongan 10% untuk semua produk',
      'discount': 0.10,
      'minPurchase': 50000,
    },
    {
      'code': 'DISKON20',
      'name': 'Diskon 20%',
      'description': 'Potongan 20% untuk pembelian min Rp 100.000',
      'discount': 0.20,
      'minPurchase': 100000,
    },
    {
      'code': 'GRATISONGKIR',
      'name': 'Gratis Ongkir',
      'description': 'Gratis ongkos kirim untuk semua ekspedisi',
      'discount': 0.0,
      'minPurchase': 0,
      'freeShipping': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    namaProduk =
        widget.produk['nama_produk']?.toString() ?? 'Produk Tidak Dikenal';
    deskripsi =
        widget.produk['deskripsi']?.toString() ?? 'Deskripsi tidak tersedia';
    gambarUrl = getFirstImageUrl(widget.produk['gambar']);

    // Initialize quantity dari produk, default 1 jika tidak ada
    quantity = widget.produk['quantity'] ?? 1;

    _fetchPromo();
    _fetchUserVouchers();
    if (!widget.usePointsFromPromo) {
      _fetchHargaAsli();
    } else {
      // For point redemption, use poin as hargaAsli
      hargaAsli =
          (double.tryParse(widget.produk['poin']?.toString() ?? '0') ?? 0.0);
    }
    _getCurrentLocation();
    _loadUserData();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          customerLat = position.latitude;
          customerLng = position.longitude;
        });
      }
    } catch (e) {
      // Location error handled silently
    }
  }

  // Calculate shipping cost
  Future<void> _calculateShippingCost() async {
    if (customerLat == null || customerLng == null) {
      CustomDialog.show(
        context: context,
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_off, color: Colors.orange, size: 24),
        ),
        title: 'Lokasi Tidak Ditemukan',
        content: const Text('Lokasi belum terdeteksi. Mohon aktifkan GPS.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
      return;
    }

    setState(() {
      isCalculatingShipping = true;
    });

    try {
      final response = await ApiService.estimateShipping(
        customerLat: customerLat!,
        customerLng: customerLng!,
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (mounted) {
          setState(() {
            shippingCost =
                double.tryParse(data['shipping_cost']?.toString() ?? '0') ??
                    0.0;
            distanceKm =
                double.tryParse(data['distance_km']?.toString() ?? '0') ?? 0.0;
            isCalculatingShipping = false;
          });
        }

        // Show success message
        CustomDialog.show(
          context: context,
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ),
          title: 'Berhasil',
          content: Text(
            'Ongkir berhasil dihitung: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(shippingCost)}',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      } else {
        throw Exception('Gagal menghitung ongkir');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCalculatingShipping = false;
        });
      }
      CustomDialog.show(
        context: context,
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error, color: Colors.red, size: 24),
        ),
        title: 'Error',
        content: Text('Gagal menghitung ongkir: $e'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }
  }

  Future<void> _fetchHargaAsli() async {
    String kodeBarang = widget.produk['kode_barang']?.toString() ?? '';
    if (kodeBarang.isNotEmpty) {
      try {
        final produkList = await ApiService.getProduk();
        final produk = produkList.firstWhere(
          (p) => p['kode_barang']?.toString() == kodeBarang,
          orElse: () => null,
        );
        if (produk != null) {
          if (mounted) {
            setState(() {
              hargaAsli =
                  (double.tryParse(produk['harga']?.toString() ?? '0') ?? 0.0) *
                      10;
            });
          }
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _loadUserData() async {
    final session = await SessionManager.getUserSession();
    final userId = session['id'] as String?;
    if (userId != null) {
      try {
        final data = await ApiService.getCostomerById(userId);
        if (mounted) {
          setState(() {
            userData = data;
            // Auto-fill address if cos_alamat exists and no address selected
            if (selectedAddress == null &&
                data['cos_alamat'] != null &&
                data['cos_alamat'].isNotEmpty) {
              selectedAddress = {
                'alamat': data['cos_alamat'],
                'detailAlamat': data['cos_alamat'], // Use same for detail
                'nama': data['cos_nama'] ?? '',
                'hp': data['cos_hp'] ?? '',
                'latitude': 0.0,
                'longitude': 0.0,
              };
            }
          });
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _fetchPromo() async {
    try {
      final response = await ApiService.getPromo();
      if (mounted) {
        setState(() {
          promoList =
              response.map<Promo>((json) => Promo.fromJson(json)).toList();
          isPromoLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isPromoLoaded = true;
        });
      }
    }
  }

  Future<void> _fetchUserVouchers() async {
    try {
      final session = await SessionManager.getUserSession();
      final customerId = session['id']?.toString();
      if (customerId != null) {
        final response = await ApiService.getUserVouchers(customerId);
        if (mounted) {
          setState(() {
            userVouchers = response
                .map<UserVoucher>((json) => UserVoucher.fromJson(json))
                .toList();
            isUserVouchersLoaded = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isUserVouchersLoaded = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isUserVouchersLoaded = true;
        });
      }
    }
  }

  String getFirstImageUrl(dynamic gambarField) {
    if (gambarField == null) return '';

    String gambarString = gambarField.toString().trim();

    // If it's already a full URL, return as is
    if (gambarString.startsWith('http')) {
      return gambarString;
    }

    // Check if string contains multiple URLs separated by commas
    List<String> paths;
    if (gambarString.contains(',')) {
      paths = gambarString
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      paths = [gambarString];
    }

    if (paths.isEmpty) return '';

    String cleanPath = _cleanImagePath(paths.first);
    if (cleanPath.isEmpty) return '';

    String baseUrl = ApiConfig.storageBaseUrl;

    // Add assets/image/ path if not already a full URL
    if (!cleanPath.startsWith('http')) {
      cleanPath = 'assets/image/$cleanPath';
    }

    String imageUrl =
        cleanPath.startsWith('http') ? cleanPath : '$baseUrl$cleanPath';

    return imageUrl;
  }

  // Helper function to clean image path for getFirstImageUrl
  String _cleanImagePath(String path) {
    path = path.trim();

    // Remove any leading slash
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    // Remove base URL if present
    path = path.replaceAll(ApiConfig.storageBaseUrl, '');

    return path;
  }

  // Helper untuk mendapatkan total harga
  double _getTotalHarga() {
    double hargaPerItem =
        (double.tryParse(widget.produk['harga']?.toString() ?? '0') ?? 0.0) *
            10;
    return hargaPerItem * quantity;
  }

  // Helper untuk mendapatkan diskon voucher
  double _getVoucherDiscount() {
    if (!useVoucher || selectedVoucher == null || !isUserVouchersLoaded) {
      return 0.0;
    }

    final userVoucher = userVouchers.firstWhere(
      (uv) => uv.voucher?.voucherCode == selectedVoucher && uv.isAvailable,
      orElse: () => UserVoucher(
        id: 0,
        idCostomer: '',
        voucherId: 0,
        claimedDate: DateTime.now(),
        used: 'yes',
      ),
    );

    if (userVoucher.voucher == null) return 0.0;

    double totalHarga = _getTotalHarga();

    // Apply discount based on voucher type
    return totalHarga * (userVoucher.voucher!.discountPercent / 100);
  }

  // Helper untuk check gratis ongkir dari voucher
  bool _hasVoucherFreeShipping() {
    // For now, no free shipping vouchers implemented
    return false;
  }

  // Get final shipping cost (consider voucher)
  double _getFinalShippingCost() {
    if (_hasVoucherFreeShipping()) {
      return 0.0;
    }
    return shippingCost;
  }

  // Helper untuk mendapatkan estimasi pengiriman berdasarkan jarak
  String _getEstimasiPengiriman() {
    if (distanceKm == 0 || selectedShipping == null) {
      return "Pilih lokasi & ekspedisi";
    }

    if (distanceKm <= 5) {
      return "Pengiriman 1 Hari";
    } else if (distanceKm <= 15) {
      return "Pengiriman 1-2 Hari";
    } else if (distanceKm <= 30) {
      return "Pengiriman 2-3 Hari";
    } else {
      return "Pengiriman 3-5 Hari";
    }
  }

  // Helper untuk mendapatkan deskripsi zona
  String _getZonaDescription() {
    if (distanceKm == 0) return '';

    if (distanceKm <= 5) {
      return "Zona Dekat - Rp 5.000 flat";
    } else if (distanceKm <= 20) {
      return "Zona Menengah - Rp 2.000/km";
    } else {
      return "Zona Jauh - Rp 1.500/km";
    }
  }

  // Helper untuk mendapatkan estimasi sampai yang lebih detail
  String _getEstimasiSampai() {
    if (distanceKm == 0 || selectedShipping == null) {
      return "Estimasi akan muncul setelah memilih lokasi";
    }

    DateTime now = DateTime.now();
    DateTime estimatedDate;

    if (distanceKm <= 5) {
      // Zona dekat: 1 hari
      estimatedDate = now.add(const Duration(days: 1));
      return "Estimasi sampai: ${_formatDate(estimatedDate)} (Besok)";
    } else if (distanceKm <= 15) {
      // Zona menengah dekat: 1-2 hari
      estimatedDate = now.add(const Duration(days: 2));
      return "Estimasi sampai: ${_formatDate(estimatedDate)} (Maks. 2 hari)";
    } else if (distanceKm <= 30) {
      // Zona menengah jauh: 2-3 hari
      estimatedDate = now.add(const Duration(days: 3));
      return "Estimasi sampai: ${_formatDate(estimatedDate)} (Maks. 3 hari)";
    } else {
      // Zona jauh: 3-5 hari
      estimatedDate = now.add(const Duration(days: 5));
      return "Estimasi sampai: ${_formatDate(estimatedDate)} (Maks. 5 hari)";
    }
  }

  // Helper untuk mendapatkan jam operasional berdasarkan zona
  String _getJamOperasional() {
    if (distanceKm == 0) {
      return "Pilih lokasi untuk melihat jam operasional";
    }

    if (distanceKm <= 5) {
      // Zona dekat: pengiriman bisa sore/malam
      return "Jam pengiriman: 07:00 – 21:00";
    } else if (distanceKm <= 20) {
      // Zona menengah: pengiriman jam kerja saja
      return "Jam pengiriman: 08:00 – 18:00";
    } else {
      // Zona jauh: pengiriman terbatas
      return "Jam pengiriman: 09:00 – 17:00";
    }
  }

  // Helper untuk format tanggal Indonesia
  String _formatDate(DateTime date) {
    final List<String> days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    String dayName = days[date.weekday % 7];
    String monthName = months[date.month - 1];

    return '$dayName, ${date.day} $monthName';
  }

  // Helper untuk mendapatkan detail estimasi untuk summary
  String _getDetailEstimasi() {
    if (distanceKm == 0) return "Belum ada estimasi";

    String hari = "";
    if (distanceKm <= 5) {
      hari = "1 hari kerja";
    } else if (distanceKm <= 15) {
      hari = "1-2 hari kerja";
    } else if (distanceKm <= 30) {
      hari = "2-3 hari kerja";
    } else {
      hari = "3-5 hari kerja";
    }

    return "$hari (${distanceKm.toStringAsFixed(1)} km)";
  }

  // Helper untuk warna badge zona
  Color _getZonaBadgeColor() {
    if (distanceKm <= 5) {
      return Colors.green;
    } else if (distanceKm <= 20) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Helper untuk text badge zona
  String _getZonaBadgeText() {
    if (distanceKm <= 5) {
      return "DEKAT";
    } else if (distanceKm <= 20) {
      return "SEDANG";
    } else {
      return "JAUH";
    }
  }

  @override
  Widget build(BuildContext context) {
    pageContext = context; // Store for async operations

    // Gunakan total harga berdasarkan quantity
    double totalHarga = _getTotalHarga();
    double voucherDiscount = _getVoucherDiscount();
    double finalShippingCost = _getFinalShippingCost();
    double effectivePrice = hargaAsli != null
        ? (hargaAsli! * quantity) - voucherDiscount + finalShippingCost
        : totalHarga - voucherDiscount + finalShippingCost;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text(
          "Ringkasan Pesanan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Pengiriman ---
            Container(
              width: double.infinity,
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$quantity Produk",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getEstimasiPengiriman(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedShipping ?? "Pilih ekspedisi terlebih dahulu",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                      fontSize: 12,
                    ),
                  ),

                  // Location & Distance Info
                  if (customerLat != null &&
                      customerLng != null &&
                      distanceKm > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue.shade900.withOpacity(0.3)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Jarak: ${distanceKm.toStringAsFixed(2)} km dari toko',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.blue.shade300
                                        : Colors.blue.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getZonaDescription(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.blue.shade400
                                        : Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.orange.shade900.withOpacity(0.3)
                          : const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delivery_dining,
                          color: Color(0xFF0041c3),
                          size: 30,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getEstimasiSampai(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF0041c3)
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                _getJamOperasional(),
                                style: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- Produk ---
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: gambarUrl.isNotEmpty
                        ? Image.network(
                            gambarUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/image/produk.jpg',
                              width: 70,
                              height: 70,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image.asset(
                            'assets/image/produk.jpg',
                            width: 70,
                            height: 70,
                            fit: BoxFit.contain,
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaProduk,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        // DEBUG: Log theme-adaptive color usage for product name
                        Builder(
                          builder: (context) {
                            return const SizedBox.shrink();
                          },
                        ),
                        Text(
                          deskripsi,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${quantity}x   ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format((totalHarga - voucherDiscount) / quantity)}",
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- Ringkasan Pesanan ---
            Container(
              width: double.infinity,
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ringkasan Pesanan",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  // DEBUG: Log theme-adaptive color usage for summary title
                  Builder(
                    builder: (context) {
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 10),
                  _summaryRow(
                    context,
                    "Subtotal ($quantity item)",
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(
                      hargaAsli != null ? (hargaAsli! * quantity) : totalHarga,
                    ),
                  ),

                  _summaryRow(context, "Diskon", "Rp 0"),
                  if (useVoucher && voucherDiscount > 0)
                    _summaryRow(
                      context,
                      "Voucher",
                      "- ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(voucherDiscount)}",
                      color: Colors.green,
                    )
                  else
                    _summaryRow(context, "Voucher", "Rp 0"),

                  // Ongkos kirim
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _summaryRow(
                        context,
                        "Ongkos kirim",
                        _hasVoucherFreeShipping()
                            ? "Gratis"
                            : (finalShippingCost > 0
                                ? NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  ).format(finalShippingCost)
                                : "Belum dihitung"),
                        color: _hasVoucherFreeShipping() ? Colors.green : null,
                      ),
                      if (distanceKm > 0 && finalShippingCost > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 2),
                          child: Text(
                            '• ${_getDetailEstimasi()}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const Divider(),
                  _summaryRow(
                    context,
                    "Total Belanja",
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(effectivePrice),
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            const SizedBox(height: 8),

            // --- Toggle Gunakan Voucher ---
            Container(
              width: double.infinity,
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Gunakan Voucher",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          if (useVoucher && selectedVoucher != null)
                            Text(
                              selectedVoucher!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          if (useVoucher)
                            TextButton(
                              onPressed: () => _showVoucherOptions(context),
                              child: const Text(
                                "Pilih",
                                style: TextStyle(
                                  color: Color(0xFF0041c3),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          Switch(
                            value: useVoucher,
                            onChanged: (value) {
                              if (value) {
                                // Check if vouchers are loaded and available
                                if (!isUserVouchersLoaded) {
                                  setState(() {
                                    useVoucher = false;
                                  });
                                  CustomDialog.show(
                                    context: context,
                                    icon: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.hourglass_empty,
                                        color: Colors.orange,
                                        size: 24,
                                      ),
                                    ),
                                    title: 'Memuat Voucher',
                                    content: const Text('Memuat voucher...'),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                  return;
                                }
                                if (userVouchers.isEmpty) {
                                  setState(() {
                                    useVoucher = false;
                                  });
                                  CustomDialog.show(
                                    context: context,
                                    icon: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 24,
                                      ),
                                    ),
                                    title: 'Tidak Ada Voucher',
                                    content: const Text(
                                      'Tidak ada voucher tersedia',
                                    ),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                  return;
                                }
                                // If vouchers available, activate and show options
                                setState(() {
                                  useVoucher = true;
                                });
                                _showVoucherOptions(context);
                              } else {
                                setState(() {
                                  useVoucher = false;
                                  selectedVoucher = null;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // --- Ekspedisi ---
            InkWell(
              onTap: () => _showShippingOptions(context),
              child: Container(
                width: double.infinity,
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Pilih Ekspedisi",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        Text(
                          "Pilih",
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (selectedShipping != null) ...[
                      Row(
                        children: [
                          Icon(
                            _getShippingIcon(selectedShipping!),
                            color: const Color(0xFF0041c3),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      selectedShipping!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    if (distanceKm > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getZonaBadgeColor(),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          _getZonaBadgeText(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (shippingCost > 0 &&
                                    !_hasVoucherFreeShipping())
                                  Text(
                                    "Ongkir: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(shippingCost)} • ${_getEstimasiPengiriman()}",
                                    style: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : const Color(0xFF0041c3),
                                      fontSize: 12,
                                    ),
                                  )
                                else if (_hasVoucherFreeShipping())
                                  Text(
                                    "Gratis Ongkir (Voucher) • ${_getEstimasiPengiriman()}",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                else
                                  Text(
                                    _getEstimasiPengiriman(),
                                    style: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF0041c3)
                                          : Colors.blue.shade900,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blueAccent,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          "Pilih ekspedisi pengiriman",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // --- Alamat ---
            InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DetailAlamatPage(),
                  ),
                );
                if (result != null) {
                  setState(() {
                    selectedAddress = result;
                    // Update koordinat jika ada di result
                    if (result['latitude'] != null) {
                      customerLat = double.tryParse(
                        result['latitude'].toString(),
                      );
                    }
                    if (result['longitude'] != null) {
                      customerLng = double.tryParse(
                        result['longitude'].toString(),
                      );
                    }
                  });

                  // Auto calculate shipping jika ada ekspedisi dan koordinat
                  if (selectedShipping == 'Ekspedisi Toko' &&
                      customerLat != null &&
                      customerLng != null) {
                    _calculateShippingCost();
                  }
                }
              },
              child: Container(
                width: double.infinity,
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Kirim ke Alamat",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        Text(
                          selectedAddress != null
                              ? "Ubah Alamat"
                              : "Tambahkan Alamat",
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: selectedAddress != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${selectedAddress!['nama']} - ${selectedAddress!['hp']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedAddress!['detailAlamat'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                if (selectedAddress!['catatan'] != null &&
                                    selectedAddress!['catatan'].isNotEmpty)
                                  Text(
                                    "Catatan: ${selectedAddress!['catatan']}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[400]
                                          : Colors.black54,
                                    ),
                                  ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Atur alamat anda di sini",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Masukan detail alamat agar memudahkan pengiriman barang",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Tambahkan catatan untuk memudahkan kurir menemukan lokasimu.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      customerLat != null && customerLng != null
                                          ? Icons.location_on
                                          : Icons.location_off,
                                      size: 16,
                                      color: customerLat != null &&
                                              customerLng != null
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        customerLat != null &&
                                                customerLng != null
                                            ? "GPS aktif"
                                            : "GPS belum aktif. Aktifkan dulu supaya alamatmu terbaca dengan tepat.",
                                        style: TextStyle(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      // --- Tombol Pembayaran ---
      bottomNavigationBar: Container(
        color: Theme.of(context).cardColor,
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0041c3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            // Validate expedition and address before proceeding
            if (selectedShipping == null) {
              CustomDialog.show(
                context: context,
                icon: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                title: 'Ekspedisi Diperlukan',
                content: const Text(
                  'Mohon pilih ekspedisi pengiriman terlebih dahulu',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
              return;
            }

            if (selectedAddress == null) {
              CustomDialog.show(
                context: context,
                icon: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_off,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                title: 'Alamat Diperlukan',
                content: const Text(
                  'Mohon pilih alamat pengiriman terlebih dahulu',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
              return;
            }

            // Proceed with payment - navigate directly to Xendit
            _navigateToXenditPayment('QRIS', 0);
          },
          child: const Text(
            "Lakukan Pembayaran",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          // DEBUG: Log theme-adaptive color usage in summary row label
          Builder(
            builder: (context) {
              return const SizedBox.shrink();
            },
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _showVoucherOptions(BuildContext context) {
    CustomModalBottomSheet.show(
      context: context,
      title: "Pilih Voucher",
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFFF9800)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.local_offer, color: Colors.white, size: 28),
      ),
      content: Column(
        children: [
          if (!isUserVouchersLoaded)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0041c3)),
            )
          else if (userVouchers.isEmpty)
            const Text("Tidak ada voucher tersedia")
          else
            ...userVouchers.where((uv) => uv.isAvailable).map((userVoucher) {
              final voucher = userVoucher.voucher;
              if (voucher == null) return const SizedBox.shrink();

              double totalHarga = _getTotalHarga();
              bool canUse =
                  totalHarga >= 0; // Assuming no min purchase for user vouchers

              return _voucherItem(
                voucher.voucherCode,
                voucher.description ?? 'Diskon ${voucher.discountPercent}%',
                voucher.description ?? 'Diskon ${voucher.discountPercent}%',
                canUse,
              );
            }),
        ],
      ),
    );
  }

  Widget _voucherItem(
    String code,
    String name,
    String description,
    bool canUse,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: canUse ? const Color(0xFF0041c3) : Colors.white24,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: canUse
            ? Theme.of(context).cardColor
            : Theme.of(context).cardColor.withOpacity(0.5),
      ),
      child: ListTile(
        leading: Icon(
          Icons.local_offer,
          color: canUse ? const Color(0xFF0041c3) : Colors.white24,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: canUse ? Colors.white : Colors.white54,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: canUse ? Colors.white70 : Colors.white54,
          ),
        ),
        trailing: canUse
            ? const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF0041c3),
              )
            : const Icon(Icons.lock_outline, color: Colors.white24),
        enabled: canUse,
        onTap: canUse
            ? () {
                setState(() {
                  selectedVoucher = code;
                  useVoucher = true;
                });
                Navigator.pop(context);
              }
            : null,
      ),
    );
  }

  void _showShippingOptions(BuildContext context) {
    CustomModalBottomSheet.show(
      context: context,
      title: "Pilih Ekspedisi",
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFFF9800)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.local_shipping, color: Colors.white, size: 28),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // Ekspedisi aktif (hanya Ekspedisi Toko)
            _shippingItem(Icons.store, "Ekspedisi Toko", enabled: true),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Label untuk ekspedisi yang tidak tersedia
            const Text(
              "Segera Hadir",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Ekspedisi disabled
            _shippingItem(Icons.local_shipping, "J&T", enabled: false),
            _shippingItem(Icons.delivery_dining, "SiCepat", enabled: false),
            _shippingItem(Icons.local_shipping_outlined, "JNE", enabled: false),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _shippingItem(IconData icon, String label, {bool enabled = true}) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? Colors.blue.shade200 : Colors.grey.shade300,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: enabled ? Colors.white : Colors.grey.shade50,
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: enabled ? const Color(0xFF0041c3) : Colors.grey,
          ),
          title: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: enabled
                      ? (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87)
                      : Colors.grey,
                  decoration: enabled
                      ? TextDecoration.none
                      : TextDecoration.lineThrough,
                ),
              ),
              if (!enabled) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Segera",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            enabled ? "Estimasi berdasarkan jarak" : "Belum tersedia",
            style: TextStyle(
              fontSize: 12,
              color: enabled ? Colors.blue.shade900 : Colors.grey,
            ),
          ),
          trailing: enabled
              ? const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF0041c3),
                )
              : const Icon(Icons.lock_outline, color: Colors.grey),
          enabled: enabled,
          onTap: enabled
              ? () async {
                  setState(() {
                    selectedShipping = label;
                  });
                  Navigator.pop(context);

                  // Auto calculate shipping jika sudah ada alamat
                  if (customerLat != null && customerLng != null) {
                    await _calculateShippingCost();
                  } else {
                    CustomDialog.show(
                      context: context,
                      icon: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_off,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      title: 'Alamat Diperlukan',
                      content: const Text(
                        'Mohon pilih alamat terlebih dahulu untuk menghitung ongkir',
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0041c3),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  }
                }
              : null,
        ),
      ),
    );
  }

  IconData _getShippingIcon(String shipping) {
    switch (shipping) {
      case "Ekspedisi Toko":
        return Icons.store;
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

  Widget _buildModernPaymentOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback? onTap, {
    required bool available,
  }) {
    return InkWell(
      onTap: available ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: available
              ? (isSelected ? color.withOpacity(0.1) : Colors.white)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: available
                ? (isSelected ? color : Colors.grey[200]!)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: available && isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: available
                  ? (isSelected ? color : Colors.grey)
                  : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: available
                              ? (isSelected ? color : Colors.black87)
                              : Colors.grey.shade500,
                        ),
                      ),
                      if (!available) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Coming Soon',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color:
                          available ? Colors.grey[600] : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (available && isSelected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  // Show payment modal before processing
  void _showPaymentModal() {
    // Hitung total biaya yang harus dibayar
    final double totalHarga = hargaAsli != null
        ? (hargaAsli! * quantity) -
            _getVoucherDiscount() +
            _getFinalShippingCost()
        : _getTotalHarga() - _getVoucherDiscount() + _getFinalShippingCost();

    String? selectedPaymentMethod =
        this.selectedPaymentMethod; // Initialize with current value
    String? selectedBank; // For bank transfer and e-wallet selection

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF667eea).withOpacity(0.95),
                  const Color(0xFF764ba2).withOpacity(0.95),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 25,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              children: [
                // Enhanced handle bar with animation
                Container(
                  margin: const EdgeInsets.only(top: 15),
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 25),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                        left: 24,
                        right: 24,
                        top: 30,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Enhanced Header with modern design
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.purple.shade50,
                                    Colors.blue.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue.shade100,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF667eea),
                                          Color(0xFF764ba2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        18,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF667eea,
                                          ).withOpacity(0.4),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.payment_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pembayaran Checkout',
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Secure Payment',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Enhanced Total Amount Card with premium design
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.shade50,
                                    Colors.purple.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.shade100.withOpacity(
                                      0.5,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(
                                        20,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet,
                                          size: 16,
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Total Pembayaran',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    totalHarga > 0
                                        ? 'Rp ${NumberFormat('#,###', 'id_ID').format(totalHarga)}'
                                        : 'Rp 0',
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.blue.shade900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(
                                        16,
                                      ),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.verified,
                                          size: 16,
                                          color: Colors.green.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Pembayaran Aman & Terjamin',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Enhanced Payment Methods Section
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.credit_card,
                                    color: Colors.orange.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Pilih Metode Pembayaran',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // QRIS - Coming Soon
                            _buildModernPaymentOption(
                              "QRIS",
                              "Scan QR code untuk pembayaran cepat & instan",
                              Icons.qr_code_scanner,
                              Colors.green,
                              selectedPaymentMethod == "QRIS",
                              () => setModalState(
                                () => selectedPaymentMethod = "QRIS",
                              ),
                              available: false,
                            ),

                            const SizedBox(height: 16),

                            // Transfer Bank - Coming Soon
                            _buildModernPaymentOption(
                              "Transfer Bank",
                              "Transfer ke rekening bank",
                              Icons.account_balance,
                              Colors.blue,
                              selectedPaymentMethod == "Transfer Bank",
                              () => setModalState(
                                () => selectedPaymentMethod = "Transfer Bank",
                              ),
                              available: false,
                            ),

                            const SizedBox(height: 16),

                            // E-wallet - Coming Soon (OVO only available internally)
                            _buildModernPaymentOption(
                              "E-wallet",
                              "GoPay, OVO, Dana, LinkAja via Xendit",
                              Icons.account_balance_wallet,
                              Colors.purple,
                              selectedPaymentMethod == "E-wallet",
                              () => setModalState(
                                () => selectedPaymentMethod = "E-wallet",
                              ),
                              available: false,
                            ),

                            const SizedBox(height: 32),

                            // Enhanced Pay Button with premium design
                            Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF667eea),
                                    Color(0xFF764ba2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF667eea,
                                    ).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (mounted) {
                                    setState(
                                      () => this.selectedPaymentMethod =
                                          selectedPaymentMethod,
                                    );
                                  }

                                  if (selectedPaymentMethod == null) {
                                    CustomDialog.show(
                                      context: context,
                                      icon: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(
                                            0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.warning,
                                          color: Colors.red,
                                          size: 24,
                                        ),
                                      ),
                                      title: 'Pilih Metode Pembayaran',
                                      content: const Text(
                                        'Mohon pilih metode pembayaran terlebih dahulu',
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    );
                                    return;
                                  }

                                  Navigator.pop(context);

                                  // Navigate to Xendit Payment Page for all payment methods
                                  _navigateToXenditPayment(
                                    selectedPaymentMethod!,
                                    totalHarga,
                                  );
                                },
                                icon: const Icon(
                                  Icons.rocket_launch,
                                  size: 24,
                                ),
                                label: Text(
                                  'Bayar Sekarang',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Enhanced Security note with better design
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.green.shade50,
                                    Colors.teal.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.green.shade100.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(
                                        10,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.security,
                                      color: Colors.green.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pembayaran 100% Aman',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Dijamin aman dengan enkripsi tingkat bank',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.green.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Process checkout and create order
  Future<void> _processCheckout(BuildContext context) async {
    // Validasi
    if (selectedAddress == null) {
      CustomDialog.show(
        context: context,
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_off, color: Colors.red, size: 24),
        ),
        title: 'Alamat Diperlukan',
        content: const Text('Mohon pilih alamat pengiriman'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0041c3),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      );
      return;
    }

    if (selectedShipping == null) {
      CustomDialog.show(
        context: context,
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.local_shipping, color: Colors.red, size: 24),
        ),
        title: 'Ekspedisi Diperlukan',
        content: const Text('Mohon pilih ekspedisi'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0041c3),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      );
      return;
    }

    if (selectedPaymentMethod == null) {
      CustomDialog.show(
        context: context,
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.payment, color: Colors.red, size: 24),
        ),
        title: 'Metode Pembayaran Diperlukan',
        content: const Text('Mohon pilih metode pembayaran'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0041c3),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      );
      return;
    }

    if (customerLat == null || customerLng == null) {
      CustomDialog.show(
        context: context,
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_off, color: Colors.red, size: 24),
        ),
        title: 'Lokasi Tidak Ditemukan',
        content: const Text('Lokasi belum terdeteksi. Mohon aktifkan GPS.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0041c3),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      );
      return;
    }

    if (shippingCost == 0) {
      CustomDialog.show(
        context: context,
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.schedule, color: Colors.orange, size: 24),
        ),
        title: 'Menghitung Ongkir',
        content: const Text('Ongkir belum dihitung. Mohon tunggu sebentar.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
      return;
    }

    // Calculate final price
    double totalHarga = _getTotalHarga();
    double voucherDiscount = _getVoucherDiscount();
    double finalShippingCost = _getFinalShippingCost();
    double finalPrice = totalHarga - voucherDiscount + finalShippingCost;

    // Handle manual payment methods
    if (selectedPaymentMethod == "QRIS") {
      _showQrisPayment(context, finalPrice);
      return;
    } else if (selectedPaymentMethod == "Transfer Bank") {
      _showBankTransferPayment(context, finalPrice, selectedBank);
      return;
    } else if (selectedPaymentMethod == "Transfer Bank Online") {
      _showOnlineBankTransferPayment(context, finalPrice);
      return;
    } else if (selectedPaymentMethod == "E-wallet") {
      _showEwalletPayment(context, finalPrice);
      return;
    }

    // Show loading
    CustomLoadingDialog.show(context: context);

    try {
      String? customerId = await SessionManager.getCustomerId();
      if (customerId == null) {
        throw Exception('Customer ID tidak ditemukan');
      }

      // Calculate prices
      double totalHarga = _getTotalHarga();
      double voucherDiscount = _getVoucherDiscount();
      double finalShippingCost = _getFinalShippingCost();

      // Calculate final price
      double finalPrice = totalHarga - voucherDiscount + finalShippingCost;

      // Prepare items untuk API
      List<Map<String, dynamic>> items = [
        {
          'kode_barang': widget.produk['kode_barang'] ??
              widget.produk['id_produk'] ??
              'PROD001',
          'nama_produk': namaProduk,
          'quantity': quantity,
          'price': (totalHarga / quantity).toInt(),
        },
      ];

      // Calculate voucher discount percent
      double voucherDiscountPercent = 0.0;
      if (selectedVoucher != null && voucherDiscount > 0) {
        final userVoucher = userVouchers.firstWhere(
          (uv) => uv.voucher?.voucherCode == selectedVoucher && uv.isAvailable,
          orElse: () => UserVoucher(
            id: 0,
            idCostomer: '',
            voucherId: 0,
            claimedDate: DateTime.now(),
            used: 'yes',
          ),
        );
        if (userVoucher.voucher != null) {
          voucherDiscountPercent = userVoucher.voucher!.discountPercent;
        }
      }

      // For development/testing, use simulate payment directly
      if (!PaymentService.isProduction) {
        // Close loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        // Create fake order code for simulation
        final fakeOrderCode = 'sim_${DateTime.now().millisecondsSinceEpoch}';

        // Start simulated payment
        await _startMidtransPayment(context, fakeOrderCode);
      } else {
        // Production: Create order via API first
        final orderResponse = await ApiService.createCheckoutOrder(
          customerId: customerId,
          items: items,
          totalPrice: finalPrice, // Use final price (shipping only for promo)
          paymentMethod: 'midtrans',
          deliveryAddress: selectedAddress!['detailAlamat'],
          customerLat: customerLat!,
          customerLng: customerLng!,
          voucherCode: selectedVoucher,
          voucherDiscount: voucherDiscountPercent,
        );

        if (orderResponse['success'] == true) {
          final orderData = orderResponse['data'];
          final orderCode = orderData['order_code'];

          // Close loading dialog
          Navigator.of(context, rootNavigator: true).pop();

          // Start Midtrans payment
          await _startMidtransPayment(context, orderCode);
        } else {
          throw Exception(orderResponse['message'] ?? 'Gagal membuat order');
        }
      }
    } catch (e) {
      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      CustomDialog.show(
        context: context,
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error, color: Colors.red, size: 24),
        ),
        title: 'Error',
        content: Text('Error: $e'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }
  }

  Future<void> _startMidtransPayment(
    BuildContext context,
    String orderCode,
  ) async {
    try {
      String? customerId = await SessionManager.getCustomerId();
      if (customerId == null) {
        throw Exception('Customer ID tidak ditemukan');
      }

      double totalHarga = _getTotalHarga();
      double voucherDiscount = _getVoucherDiscount();
      double finalShippingCost = _getFinalShippingCost();
      double finalPrice = totalHarga - voucherDiscount + finalShippingCost;

      await PaymentService.startMidtransPayment(
        context: context,
        orderId: orderCode,
        amount: finalPrice.toInt() > 0 ? finalPrice.toInt() : 1000,
        customerId: customerId,
        customerName: selectedAddress?['nama'] ?? 'Customer',
        customerEmail: 'customer@example.com',
        customerPhone: selectedAddress?['hp'] ?? '08123456789',
        itemDetails: [
          {
            'id': widget.produk['kode_barang']?.toString() ??
                widget.produk['id_produk']?.toString() ??
                'PROD001',
            'price': ((totalHarga - voucherDiscount) / quantity).toInt(),
            'quantity': quantity,
            'name': namaProduk,
          },
          if (finalShippingCost > 0)
            {
              'id': 'SHIPPING',
              'price': finalShippingCost.toInt(),
              'quantity': 1,
              'name': 'Ongkos Kirim',
            },
        ],
        onTransactionFinished: (result) async {
          if (PaymentService.isTransactionSuccess(result)) {
            // Skip backend updates for simulated payments
            if (!PaymentService.isProduction && orderCode.startsWith('sim_')) {
              // For simulated payments, directly proceed to success
              _onPaymentSuccess(context, orderCode);
            } else {
              // Production: Update payment status
              await ApiService.updatePaymentStatus(
                orderCode: orderCode,
                paymentStatus: 'paid',
              );

              _onPaymentSuccess(context, orderCode);
            }
          } else {
            CustomDialog.show(
              context: context,
              icon: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              title: 'Pembayaran Gagal',
              content: Text(PaymentService.getStatusMessage(result)),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          }
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToPaymentSuccess() {
    // Use global navigator key to navigate regardless of context state
    navigatorKey.currentState!
        .pushReplacement(
          MaterialPageRoute(
            builder: (context) => const RiwayatPage(shouldRefresh: true),
          ),
        )
        .then((_) {})
        .catchError((e) {});
  }

  void _onPaymentSuccess(BuildContext ctx, String orderCode) {
    // Use global navigator key to navigate regardless of context state
    navigatorKey.currentState!
        .pushReplacement(
          MaterialPageRoute(
            builder: (context) => const RiwayatPage(shouldRefresh: true),
          ),
        )
        .then((_) {})
        .catchError((e) {});
  }

  // Navigate to Xendit Payment Page
  void _navigateToXenditPayment(String paymentMethod, double amount) async {
    // Calculate final price
    double totalHarga = _getTotalHarga();
    double voucherDiscount = _getVoucherDiscount();
    double finalShippingCost = _getFinalShippingCost();
    double finalPrice = totalHarga - voucherDiscount + finalShippingCost;

    // Generate order code
    final orderCode = 'ORD_${DateTime.now().millisecondsSinceEpoch}';

    // Get customer ID
    String customerId = await SessionManager.getCustomerId() ?? '';
    if (customerId.isEmpty) {
      customerId = 'CUST_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Prepare items
    List<Map<String, dynamic>> items = [
      {
        'kode_barang': widget.produk['kode_barang'] ??
            widget.produk['id_produk'] ??
            'PROD001',
        'nama_produk': namaProduk,
        'quantity': quantity,
        'price': (totalHarga / quantity).toInt(),
      },
    ];

    // Navigate to Xendit Payment Page
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => XenditPaymentPage(
          orderId: orderCode,
          amount: finalPrice.toInt(),
          customerId: customerId,
          customerName: selectedAddress?['nama'] ?? 'Customer',
          customerPhone: selectedAddress?['hp'] ?? '08123456789',
          customerEmail: 'customer@example.com',
          items: items,
          paymentType: 'product',
          onPaymentComplete: (String orderId, String status) {
            // Navigate to success page
            Navigator.of(ctx).pop(); // Close XenditPaymentPage
            _onPaymentSuccess(ctx, orderId);
          },
        ),
      ),
    );
  }

  void _showManualPaymentDialog(BuildContext context) {
    double totalHarga = _getTotalHarga();
    double voucherDiscount = _getVoucherDiscount();
    double finalShippingCost = _getFinalShippingCost();
    double finalPrice = totalHarga - voucherDiscount + finalShippingCost;

    CustomDialog.show(
      context: context,
      barrierDismissible: false,
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.qr_code, color: Colors.blue, size: 48),
      ),
      title: 'Pembayaran Manual',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Pilih metode pembayaran:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // QRIS Option
          _buildManualPaymentOption(
            'QRIS',
            'Scan QR code untuk bayar',
            Icons.qr_code_2,
            () => _showQrisPayment(context, finalPrice),
          ),

          const SizedBox(height: 12),

          // Bank Transfer Option
          _buildManualPaymentOption(
            'Transfer Bank',
            'Transfer ke rekening bank',
            Icons.account_balance,
            () => _showBankTransferPayment(context, finalPrice, null),
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: const Text(
              '⚠️ Pembayaran manual untuk testing saja. Dalam production akan menggunakan gateway pembayaran resmi.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildManualPaymentOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showQrisPayment(BuildContext context, double amount) {
    Navigator.pop(context); // Close method selection dialog

    File? paymentProof;
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF667eea).withOpacity(0.95),
                  const Color(0xFF764ba2).withOpacity(0.95),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 25,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              children: [
                // Enhanced handle bar
                Container(
                  margin: const EdgeInsets.only(top: 15),
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 25),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                        left: 24,
                        right: 24,
                        top: 30,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Premium Header with QRIS branding
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.green.shade50,
                                    Colors.teal.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF4CAF50),
                                          Color(0xFF2E7D32),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        18,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(
                                            0.4,
                                          ),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pembayaran QRIS',
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Instant Payment',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Enhanced QR Code Display with premium styling
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.grey.shade50,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.shade100
                                          .withOpacity(0.5),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 180,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          16,
                                        ),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          16,
                                        ),
                                        child: Image.asset(
                                          'assets/image/my_qris.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              color: Colors.grey.shade100,
                                              child: const Icon(
                                                Icons.qr_code_2,
                                                size: 80,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(
                                          20,
                                        ),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.payments,
                                            size: 16,
                                            color: Colors.green.shade600,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Enhanced Instructions with better design
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.shade50,
                                    Colors.indigo.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.smartphone,
                                      color: Colors.blue.shade600,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Cara Pembayaran',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Buka aplikasi e-wallet Anda dan scan QR code di atas',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Enhanced Upload Section
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.orange.shade50,
                                    Colors.amber.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.receipt_long,
                                          color: Colors.orange.shade600,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Upload Bukti Pembayaran',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (paymentProof != null)
                                    Container(
                                      width: double.infinity,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.orange.shade200,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.orange.shade100
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                        child: Image.file(
                                          paymentProof!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: double.infinity,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.orange.shade200,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                        color: Colors.orange.shade50,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: 36,
                                            color: Colors.orange.shade400,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Belum ada bukti pembayaran",
                                            style: GoogleFonts.poppins(
                                              color: Colors.orange.shade600,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange.shade400,
                                          Colors.orange.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.shade300
                                              .withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        try {
                                          final XFile? pickedFile =
                                              await picker.pickImage(
                                            source: ImageSource.gallery,
                                            maxWidth: 1920,
                                            maxHeight: 1080,
                                            imageQuality: 85,
                                          );

                                          if (pickedFile != null) {
                                            setModalState(() {
                                              paymentProof = File(
                                                pickedFile.path,
                                              );
                                            });
                                          }
                                        } catch (e) {
                                          CustomDialog.show(
                                            context: context,
                                            icon: Container(
                                              padding: const EdgeInsets.all(
                                                16,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.red.withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.error,
                                                color: Colors.red,
                                                size: 24,
                                              ),
                                            ),
                                            title: 'Error',
                                            content: Text(
                                              'Error picking image: $e',
                                            ),
                                            actions: [
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                ),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.photo_library,
                                        size: 20,
                                      ),
                                      label: Text(
                                        paymentProof != null
                                            ? "Ganti Foto"
                                            : "Pilih dari Galeri",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Enhanced Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'Batal',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF4CAF50),
                                          Color(0xFF2E7D32),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(
                                            0.4,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: paymentProof == null
                                          ? null
                                          : () {
                                              Navigator.pop(context);
                                              _confirmManualPayment(
                                                amount,
                                                'QRIS',
                                                paymentProof: paymentProof,
                                              );
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        disabledBackgroundColor:
                                            Colors.grey.shade300,
                                      ),
                                      child: Text(
                                        'Konfirmasi Pembayaran',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showBankTransferPayment(
    BuildContext context,
    double amount,
    String? selectedBank,
  ) {
    Navigator.pop(context); // Close method selection dialog

    File? paymentProof;
    final ImagePicker picker = ImagePicker();

    CustomDialog.show(
      context: context,
      barrierDismissible: false,
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.account_balance, color: Colors.blue, size: 48),
      ),
      title: 'Transfer Bank Manual',
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Rekening Tujuan:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedBank != null
                        ? _getBankDestinationInfo(selectedBank)
                        : 'Pilih bank terlebih dahulu',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Text(
                    'a.n.  Azzahra Computer',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nominal: Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Transfer tepat sesuai nominal di atas',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Upload Bukti Pembayaran',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (paymentProof != null)
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(paymentProof!, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Belum ada bukti",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final XFile? pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1920,
                    maxHeight: 1080,
                    imageQuality: 85,
                  );

                  if (pickedFile != null) {
                    setState(() {
                      paymentProof = File(pickedFile.path);
                    });
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error picking image: $e'),
                      backgroundColor: Colors.red.withOpacity(0.8),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.photo_library),
              label: Text(
                paymentProof != null ? "Ganti Foto" : "Pilih dari Galeri",
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: paymentProof == null
              ? null
              : () {
                  Navigator.pop(context);
                  _confirmManualPayment(amount, 'Transfer Bank');
                },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text(
            'Konfirmasi Pembayaran',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showOnlineBankTransferPayment(BuildContext context, double amount) {
    Navigator.pop(context); // Close method selection dialog

    File? paymentProof;
    String? selectedBank;
    final ImagePicker picker = ImagePicker();

    CustomDialog.show(
      context: context,
      barrierDismissible: false,
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.account_balance, color: Colors.blue, size: 48),
      ),
      title: 'Transfer Bank Online',
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Pilih Bank untuk Internet Banking:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBank,
                    hint: const Text("Pilih bank Anda"),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF0041c3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "BCA", child: Text("BCA Klik")),
                      DropdownMenuItem(
                          value: "BRI", child: Text("BRI Internet Banking")),
                      DropdownMenuItem(
                          value: "Mandiri", child: Text("Mandiri Online")),
                      DropdownMenuItem(
                          value: "BNI", child: Text("BNI Internet Banking")),
                      DropdownMenuItem(
                          value: "CIMB Niaga", child: Text("CIMB Clicks")),
                      DropdownMenuItem(
                          value: "Danamon",
                          child: Text("Danamon Online Banking")),
                      DropdownMenuItem(
                          value: "Permata", child: Text("PermataNet")),
                    ],
                    onChanged: (value) => setState(() => selectedBank = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Mohon pilih bank';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nominal: Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lakukan transfer melalui internet banking dan upload bukti pembayaran',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Upload Bukti Pembayaran',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (paymentProof != null)
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(paymentProof!, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Belum ada bukti",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final XFile? pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1920,
                    maxHeight: 1080,
                    imageQuality: 85,
                  );

                  if (pickedFile != null) {
                    setState(() {
                      paymentProof = File(pickedFile.path);
                    });
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error picking image: $e'),
                      backgroundColor: Colors.red.withOpacity(0.8),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.photo_library),
              label: Text(
                paymentProof != null ? "Ganti Foto" : "Pilih dari Galeri",
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: (paymentProof == null || selectedBank == null)
              ? null
              : () {
                  Navigator.pop(context);
                  _confirmManualPayment(
                    amount,
                    'Transfer Bank Online - $selectedBank',
                    paymentProof: paymentProof,
                  );
                },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text(
            'Konfirmasi Pembayaran',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showEwalletPayment(BuildContext context, double amount) {
    Navigator.pop(context); // Close method selection dialog

    File? paymentProof;
    String? selectedEwallet;
    final ImagePicker picker = ImagePicker();

    CustomDialog.show(
      context: context,
      barrierDismissible: false,
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.account_balance_wallet,
          color: Colors.blue,
          size: 48,
        ),
      ),
      title: 'Pembayaran E-wallet',
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nominal: Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pilih e-wallet Anda dan lakukan pembayaran',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEwalletOption(
                  'GoPay',
                  selectedEwallet == 'GoPay',
                  () {
                    // Show coming soon message
                    CustomDialog.show(
                      context: context,
                      icon: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.schedule,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      title: 'Coming Soon',
                      content: const Text('GoPay akan segera tersedia'),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                  enabled: false,
                ),
                _buildEwalletOption(
                  'OVO',
                  selectedEwallet == 'OVO',
                  () => setState(() => selectedEwallet = 'OVO'),
                  enabled: true,
                ),
                _buildEwalletOption(
                  'Dana',
                  selectedEwallet == 'Dana',
                  () {
                    // Show coming soon message
                    CustomDialog.show(
                      context: context,
                      icon: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.schedule,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      title: 'Coming Soon',
                      content: const Text('DANA akan segera tersedia'),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                  enabled: false,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedEwallet != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kirim ke $selectedEwallet',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedEwallet == 'GoPay') ...[
                      const Text(
                        'Nomor GoPay: 0812-3456-7890',
                        style: TextStyle(fontSize: 13),
                      ),
                      const Text(
                        'Atas nama:  Azzahra Computer',
                        style: TextStyle(fontSize: 13),
                      ),
                    ] else if (selectedEwallet == 'OVO') ...[
                      const Text(
                        'Nomor HP: 0812-3456-7890',
                        style: TextStyle(fontSize: 13),
                      ),
                      const Text(
                        'Atas nama:  Azzahra Computer',
                        style: TextStyle(fontSize: 13),
                      ),
                    ] else if (selectedEwallet == 'Dana') ...[
                      const Text(
                        'Nomor HP: 0812-3456-7890',
                        style: TextStyle(fontSize: 13),
                      ),
                      const Text(
                        'Atas nama:  Azzahra Computer',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Upload Bukti Pembayaran',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (paymentProof != null)
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(paymentProof!, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Belum ada bukti",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final XFile? pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1920,
                    maxHeight: 1080,
                    imageQuality: 85,
                  );

                  if (pickedFile != null) {
                    setState(() {
                      paymentProof = File(pickedFile.path);
                    });
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error picking image: $e'),
                      backgroundColor: Colors.red.withOpacity(0.8),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.photo_library),
              label: Text(
                paymentProof != null ? "Ganti Foto" : "Pilih dari Galeri",
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: (paymentProof == null || selectedEwallet == null)
              ? null
              : () {
                  Navigator.pop(context);
                  _confirmManualPayment(
                    amount,
                    'E-wallet - $selectedEwallet',
                  );
                },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text(
            'Konfirmasi Pembayaran',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildEwalletOption(String name, bool isSelected, VoidCallback onTap, {bool enabled = true}) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFF0041c3) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? const Color(0xFF0041c3).withOpacity(0.1)
                : Colors.white,
          ),
          child: Column(
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF0041c3)
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87),
                ),
              ),
              if (!enabled) ...[
                const SizedBox(height: 2),
                const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getBankDestinationInfo(String bank) {
    switch (bank) {
      case 'BCA':
        return 'BCA - 1234567890';
      case 'BRI':
        return 'BRI - 0987654321';
      case 'Mandiri':
        return 'Mandiri - 1122334455';
      case 'BNI':
        return 'BNI - 5566778899';
      case 'CIMB Niaga':
        return 'CIMB Niaga - 4433221100';
      default:
        return 'BCA - 1234567890';
    }
  }

  void _confirmManualPayment(
    double amount,
    String method, {
    File? paymentProof,
  }) async {
    // Use stored page context to avoid invalid context issues
    final safeContext = pageContext;

    // Show loading
    try {
      CustomLoadingDialog.show(context: safeContext);
    } catch (e) {}

    try {
      // Get customer ID first
      String? customerId = await SessionManager.getCustomerId();
      if (customerId == null) {
        throw Exception('Customer ID tidak ditemukan');
      }

      // Generate order code
      final orderCode = 'ORD_${DateTime.now().millisecondsSinceEpoch}';

      // Calculate prices
      double totalHarga = _getTotalHarga();
      double voucherDiscount = _getVoucherDiscount();
      double finalShippingCost = _getFinalShippingCost();
      double totalPrice =
          hargaAsli != null ? (hargaAsli! * quantity) : totalHarga;
      double totalPayment = totalPrice - voucherDiscount + finalShippingCost;

      // For manual payments, use the selected voucher directly
      // The backend will validate it during order creation
      String? validVoucherCode = selectedVoucher;
      double validVoucherDiscount = voucherDiscount;

      // Recalculate total payment with validated voucher
      totalPayment = totalPrice - validVoucherDiscount + finalShippingCost;

      // UPLOAD PAYMENT PROOF FIRST (atomic with data creation)
      String? buktiPembayaranPath;
      if (paymentProof != null) {
        try {
          final uploadResult = await ApiService.uploadPaymentProof(
            paymentProof,
          );
          buktiPembayaranPath = uploadResult['path'];
        } catch (uploadError) {
          throw Exception('Gagal upload bukti pembayaran. Proses dibatalkan.');
        }
      } else {
        throw Exception('Bukti pembayaran diperlukan.');
      }

      // Prepare items
      List<Map<String, dynamic>> items = [
        {
          'kode_barang': widget.produk['kode_barang'] ??
              widget.produk['id_produk'] ??
              'PROD001',
          'nama_produk': namaProduk,
          'quantity': quantity,
          'price': (totalHarga / quantity).toInt(),
          'subtotal': ((totalHarga / quantity) * quantity).toInt(),
        },
      ];

      // Create checkout order ONLY after successful image upload

      final orderResponse = await ApiService.createCheckoutOrder(
        customerId: customerId,
        items: items,
        totalPrice: totalPrice,
        paymentMethod: method,
        deliveryAddress: selectedAddress!['detailAlamat'],
        customerLat: customerLat ?? 0.0,
        customerLng: customerLng ?? 0.0,
        voucherCode: validVoucherCode,
        voucherDiscount: validVoucherDiscount,
      );

      if (orderResponse['success'] == true) {
        final orderData = orderResponse['data'];
        final actualOrderCode = orderData['order_code'];

        // Update order with additional fields including payment proof path
        await ApiService.updateCheckoutOrder(actualOrderCode, {
          'shipping_cost': finalShippingCost,
          'total_payment': totalPayment,
          'distance_km': distanceKm,
          'expedition_type': 'pribadi',
          'payment_status':
              'pending', // Changed to pending for admin confirmation
          'delivery_status': 'menunggu',
          'bukti_pembayaran': buktiPembayaranPath,
          'voucher_discount': validVoucherDiscount,
          if (validVoucherCode != null)
            'voucher_code': validVoucherCode, // Only update if not null
        });

        // Close loading
        if (mounted && Navigator.canPop(safeContext)) {
          Navigator.of(safeContext, rootNavigator: true).pop();
        }

        await Future.delayed(const Duration(milliseconds: 200));

        // Show success dialog before navigation
        _showPaymentSuccessDialog(method);
      } else {
        throw Exception(orderResponse['message'] ?? 'Gagal membuat order');
      }
    } catch (e) {
      // Close loading
      try {
        if (Navigator.canPop(safeContext)) {
          Navigator.of(safeContext, rootNavigator: true).pop();
        }

        CustomDialog.show(
          context: safeContext,
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error, color: Colors.red, size: 24),
          ),
          title: 'Error',
          content: Text('Error: $e'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(safeContext),
              child: const Text('OK'),
            ),
          ],
        );
      } catch (dialogError) {
        // Show snackbar as fallback
        try {
          final userMessage = error_handler.ErrorHandler.handleUiError(
            e,
            context: 'CheckoutPage',
            customUserMessage: 'Terjadi kesalahan saat memproses pembayaran',
          );
          ScaffoldMessenger.of(safeContext).showSnackBar(
            SnackBar(content: Text(userMessage)),
          );
        } catch (snackbarError) {}
      }
    }
  }

  void _showPaymentSuccessDialog(String method) {
    // Show success dialog before navigation
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and title
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    border: const Border(
                      bottom: BorderSide(color: Colors.white24, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Pembayaran Berhasil!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Pembayaran dengan metode $method telah dikonfirmasi.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Anda akan diarahkan ke halaman riwayat...",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : Colors.black45,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.8),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      _navigateToPaymentSuccess();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      "Oke",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOrderSuccessDialog(
    BuildContext context,
    String orderCode,
    String method,
  ) {
    // Store context reference safely
    final dialogContext = context;

    // Show custom success dialog with auto-navigation
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            width: MediaQuery.of(dialogContext).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and title
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    border: const Border(
                      bottom: BorderSide(color: Colors.white24, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Pembayaran Berhasil!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Pembayaran dengan metode $method telah dikonfirmasi.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Anda akan diarahkan ke halaman riwayat...",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : Colors.black45,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.8),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop(); // Close dialog
                        // Navigate immediately
                        _navigateToPaymentSuccess();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      "Oke",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Auto-navigate after dialog is dismissed (either by button or auto)
      _navigateToPaymentSuccess();
    });

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(dialogContext)) {
        Navigator.of(dialogContext).pop();
      }
    });
  }
}
