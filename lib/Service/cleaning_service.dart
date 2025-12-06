import 'package:azza_service/Beli/shop.dart';
import 'package:azza_service/Home/Home.dart';
import 'package:azza_service/Others/notifikasi.dart';
import 'package:azza_service/Others/session_manager.dart';
import 'package:azza_service/Profile/profile.dart';
import 'package:azza_service/Promo/promo.dart';
import 'package:azza_service/Service/Service.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:azza_service/utils/error_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CleaningServicePage extends StatefulWidget {
  const CleaningServicePage({super.key});

  @override
  State<CleaningServicePage> createState() => _CleaningServicePageState();
}

class _CleaningServicePageState extends State<CleaningServicePage> {
  int currentIndex = 0;

  final TextEditingController namaController = TextEditingController();

  bool _isSuccess(Map<String, dynamic>? r) {
    if (r == null) return false;
    if (r.containsKey('success')) {
      final v = r['success'];
      return (v is bool) ? v : (v.toString().toLowerCase() == 'true');
    }
    if (r.containsKey('status')) {
      final v = r['status'];
      return (v is bool) ? v : (v.toString().toLowerCase() == 'true');
    }
    return false;
  }

  int jumlahBarang = 1;
  List<TextEditingController> seriControllers = [];
  List<TextEditingController> emailControllers = []; // Tambahkan untuk email
  List<TextEditingController> merekControllers = [];
  List<TextEditingController> deviceControllers = [];
  List<String?> selectedStatuses = [];
  String? selectedStatus;

  final List<String> statusOptions = [
    'CID',
    'IW (Masih Garansi)',
    'OOW (Tidak Garansi)',
  ];

  @override
  void initState() {
    super.initState();
    _initializeItemFields();
  }

  void _initializeItemFields() {
    seriControllers = List.generate(
      jumlahBarang,
      (_) => TextEditingController(),
    );
    emailControllers = List.generate(
      jumlahBarang,
      (_) => TextEditingController(),
    );
    merekControllers = List.generate(
      jumlahBarang,
      (_) => TextEditingController(),
    );
    deviceControllers = List.generate(
      jumlahBarang,
      (_) => TextEditingController(),
    );
    selectedStatuses = List.filled(jumlahBarang, null);
  }

  void _updateJumlahBarang(int newJumlah) {
    setState(() {
      jumlahBarang = newJumlah;
      _initializeItemFields();
    });
  }

  // Fungsi untuk mendapatkan email lengkap
  String _getFullEmail(int index) {
    String username = emailControllers[index].text.trim();
    if (username.isEmpty) return '';
    return '$username@gmail.com';
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
              color: Color(0xFF1976D2),
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

          // ==== FORM ====
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 20, bottom: 100),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _inputField("Nama", namaController),
                        const SizedBox(height: 12),
                        _jumlahBarangField(),
                        const SizedBox(height: 12),
                        ...List.generate(jumlahBarang, (index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Barang ${index + 1}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _dropdownField(
                                  "Status",
                                  selectedStatuses[index],
                                  statusOptions,
                                  (value) {
                                    setState(
                                      () => selectedStatuses[index] = value,
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                _inputField("Merek", merekControllers[index]),
                                const SizedBox(height: 10),
                                _inputField("Device", deviceControllers[index]),
                                const SizedBox(height: 10),
                                _inputField("Seri", seriControllers[index]),
                                // Kondisi untuk menampilkan field email
                                if (selectedStatuses[index] ==
                                        "IW (Masih Garansi)" &&
                                    merekControllers[index].text.trim() ==
                                        "Lenovo") ...[
                                  const SizedBox(height: 10),
                                  _emailField(
                                      "Email *",
                                      emailControllers[
                                          index]), // Gunakan _emailField khusus
                                ],
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              // Validation
                              if (namaController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Nama wajib diisi dan tidak boleh kosong',
                                    ),
                                  ),
                                );
                                return;
                              }
                              for (int i = 0; i < jumlahBarang; i++) {
                                if (selectedStatuses[i] == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Status wajib dipilih',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (merekControllers[i].text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Merek wajib diisi',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (deviceControllers[i].text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Device wajib diisi',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (seriControllers[i].text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Seri wajib diisi dan tidak boleh kosong',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                // Validasi email jika kondisi terpenuhi
                                if (selectedStatuses[i] ==
                                        "IW (Masih Garansi)" &&
                                    merekControllers[i].text.trim() ==
                                        "Lenovo") {
                                  String fullEmail = _getFullEmail(i);
                                  if (fullEmail.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Email wajib diisi',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  // Validasi format email lengkap
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                      .hasMatch(fullEmail)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Format email tidak valid',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                }
                              }
                              // If all validations pass
                              List<Map<String, String?>> items = [];
                              for (int i = 0; i < jumlahBarang; i++) {
                                items.add({
                                  'status_garansi': selectedStatuses[i],
                                  'merek': merekControllers[i].text.trim(),
                                  'device': deviceControllers[i].text.trim(),
                                  'seri': seriControllers[i].text,
                                  'email': (selectedStatuses[i] ==
                                              "IW (Masih Garansi)" &&
                                          merekControllers[i].text.trim() ==
                                              "Lenovo")
                                      ? _getFullEmail(i)
                                      : null,
                                });
                              }

                              // Send data to API for each item to azza database, then overall to azza_multibrand2_web
                              try {
                                String cosKode =
                                    await SessionManager.getCustomerId() ?? '';
                                String transTanggal = DateTime.now()
                                    .toIso8601String()
                                    .split('T')[0];
                                double pricePerItem = 0.0;
                                double totalTrans = pricePerItem * jumlahBarang;

                                // Step 1: Send to azza database (createTransaksi) for each item
                                bool azzaSuccess = true;
                                String? azzaError;
                                for (var item in items) {
                                  Map<String, dynamic> data = {
                                    'cos_kode': cosKode,
                                    'kry_kode': 'KRY001',
                                    'trans_total': pricePerItem,
                                    'trans_discount': 0.0,
                                    'trans_tanggal': transTanggal,
                                    'trans_status': 'pending',
                                    'merek': item['merek'],
                                    'device': item['device'],
                                    'status_garansi': item['status_garansi'],
                                    'seri': item['seri'],
                                    'email': item['email'],
                                  };
                                  Map<String, dynamic> response =
                                      await ApiService.createTransaksi(data);
                                  if (!_isSuccess(response)) {
                                    azzaSuccess = false;
                                    azzaError =
                                        response['message'] ?? 'Unknown error';
                                    break;
                                  }
                                }

                                if (!azzaSuccess) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Gagal'),
                                        content: Text('Gagal membuat pesanan'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  return;
                                }
                              } catch (e) {
                                ErrorUtils.showErrorSnackBar(context, e,
                                    customMessage: 'Gagal membuat pesanan');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "Pesan",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ==== BOTTOM NAV ====
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
                  )
                : Opacity(
                    opacity: 0.6,
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

  // ==== FIELD STYLES ====

  Widget _inputField(String label, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1976D2)),
            ),
          ),
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
      ],
    );
  }

  // Widget khusus untuk email dengan keyboard email
  Widget _emailField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType:
              TextInputType.emailAddress, // Keyboard email untuk bantuan format
          autofillHints: [AutofillHints.email], // Bantuan autofill email
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1976D2)),
            ),
            hintText: 'Masukkan email Gmail',
          ),
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
      ],
    );
  }

  Widget _dropdownField(
    String label,
    String? selectedValue,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<String>(
            value: selectedValue,
            hint: const Text(
              'Pilih...',
              style: TextStyle(color: Colors.black54),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _jumlahBarangField() {
    return Row(
      children: [
        const Text(
          "Jumlah Barang :",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 18, color: Colors.black),
                onPressed: jumlahBarang > 1
                    ? () => _updateJumlahBarang(jumlahBarang - 1)
                    : null,
              ),
              Text(
                jumlahBarang.toString(),
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18, color: Colors.black),
                onPressed: jumlahBarang < 10
                    ? () => _updateJumlahBarang(jumlahBarang + 1)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Method to submit service order
  void _submitServiceOrder(BuildContext context, String serviceType,
      String nama, int jumlahBarang, List<Map<String, String?>> items) async {
    try {
      print('=== SUBMIT SERVICE ORDER START ===');
      print('Service Type: $serviceType');
      print('Nama: $nama');
      print('Jumlah Barang: $jumlahBarang');
      print('Items: $items');

      // Get customer ID from session
      String? cosKode = await SessionManager.getCustomerId();
      print('Customer ID from session: $cosKode');
      if (cosKode == null) {
        print('ERROR: Customer ID is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Customer ID tidak ditemukan. Silakan login kembali.')),
        );
        return;
      }

      // Calculate total based on actual pricing logic
      double transTotal =
          30000.0 * jumlahBarang; // 30k per item for cleaning service
      double transDiscount = 0.0; // No discount for now
      String transStatus = 'pending'; // Initial status

      // Prepare data for API
      Map<String, dynamic> transaksiData = {
        'cos_kode': cosKode,
        'kry_kode': 'KRY001', // Valid technician code
        'trans_total': transTotal,
        'trans_discount': transDiscount,
        'trans_tanggal': DateTime.now()
            .toIso8601String()
            .split('T')[0], // Current date in YYYY-MM-DD format
        'trans_status': transStatus,
      };

      // Prepare full data for azza database including items
      Map<String, dynamic> fullData = {
        ...transaksiData,
        'items': items,
      };

      print('Full Data for azza: $fullData');
      print('Transaction Data for azza_multibrand2_web: $transaksiData');

      // Step 1: Send to azza database with items
      print('Calling ApiService.createTransaksi...');
      Map<String, dynamic> response1 =
          await ApiService.createTransaksi(fullData);
      print('API Response from azza: $response1');

      if (response1['success'] != true) {
        print('ERROR: Failed to create transaction in azza database');
        final sanitizedMessage = ErrorUtils.sanitizeServerMessage(
            response1['message'] ?? 'Unknown error');
        ErrorUtils.showErrorSnackBar(context, null,
            customMessage:
                'Gagal membuat pesanan di database utama: $sanitizedMessage');
        return;
      }
    } catch (e) {
      print('EXCEPTION: $e');
      // Handle error
      ErrorUtils.showErrorSnackBar(context, e,
          customMessage: 'Terjadi kesalahan saat membuat pesanan');
    }
    print('=== SUBMIT SERVICE ORDER END ===');
  }
}
