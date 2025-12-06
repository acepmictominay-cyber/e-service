import 'package:azza_service/Beli/shop.dart';
import 'package:azza_service/Home/Home.dart';
import 'package:azza_service/Others/notifikasi.dart';
import 'package:azza_service/Others/session_manager.dart';
import 'package:azza_service/Profile/profile.dart';
import 'package:azza_service/Promo/promo.dart';
import 'package:azza_service/Service/Service.dart';
import 'package:azza_service/Service/detail_alamat.dart';
import 'package:azza_service/api_services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'waiting_approval.dart';

class PerbaikanServicePage extends StatefulWidget {
  const PerbaikanServicePage({super.key});

  @override
  State<PerbaikanServicePage> createState() => _PerbaikanServicePageState();
}

class _PerbaikanServicePageState extends State<PerbaikanServicePage> {
  int currentIndex = 0;

  final TextEditingController namaController = TextEditingController();
  final TextEditingController hpController = TextEditingController();
  Map<String, dynamic>? selectedAddress;
  Map<String, dynamic>? userData;

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
  List<TextEditingController> partControllers = [];
  List<TextEditingController> emailControllers =
      []; // email hanya untuk transaksi lenovo iw
  List<TextEditingController> merekControllers = [];
  List<TextEditingController> deviceControllers = [];
  List<String?> selectedStatuses = [];

  final List<String> statusOptions = [
    'CID',
    'IW (Masih Garansi)',
    'OOW (Tidak Garansi)',
  ];

  @override
  void initState() {
    super.initState();
    _initializeItemFields();
    _loadUserData();
  }

  void _loadUserData() async {
    final session = await SessionManager.getUserSession();
    final userId = session['id'] as String?;
    if (userId != null) {
      try {
        final data = await ApiService.getCostomerById(userId);
        setState(() {
          userData = data;
          // Auto-fill name and phone
          namaController.text = data['cos_nama'] ?? '';
          hpController.text = data['cos_hp'] ?? '';
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
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  void _initializeItemFields() {
    // Preserve existing data when increasing quantity
    List<TextEditingController> newSeriControllers = [];
    List<TextEditingController> newPartControllers = [];
    List<TextEditingController> newEmailControllers = [];
    List<TextEditingController> newMerekControllers = [];
    List<TextEditingController> newDeviceControllers = [];
    List<String?> newSelectedStatuses = [];

    for (int i = 0; i < jumlahBarang; i++) {
      // Preserve existing controllers if they exist, otherwise create new ones
      if (i < seriControllers.length) {
        newSeriControllers.add(seriControllers[i]);
      } else {
        newSeriControllers.add(TextEditingController());
      }

      if (i < partControllers.length) {
        newPartControllers.add(partControllers[i]);
      } else {
        newPartControllers.add(TextEditingController());
      }

      if (i < emailControllers.length) {
        newEmailControllers.add(emailControllers[i]);
      } else {
        newEmailControllers.add(TextEditingController());
      }

      if (i < merekControllers.length) {
        newMerekControllers.add(merekControllers[i]);
      } else {
        newMerekControllers.add(TextEditingController());
      }

      if (i < deviceControllers.length) {
        newDeviceControllers.add(deviceControllers[i]);
      } else {
        newDeviceControllers.add(TextEditingController());
      }

      // Preserve existing selections if they exist
      if (i < selectedStatuses.length) {
        newSelectedStatuses.add(selectedStatuses[i]);
      } else {
        newSelectedStatuses.add(null);
      }
    }

    seriControllers = newSeriControllers;
    partControllers = newPartControllers;
    emailControllers = newEmailControllers;
    merekControllers = newMerekControllers;
    deviceControllers = newDeviceControllers;
    selectedStatuses = newSelectedStatuses;
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
    if (selectedStatuses.length != jumlahBarang ||
        merekControllers.length != jumlahBarang ||
        deviceControllers.length != jumlahBarang ||
        seriControllers.length != jumlahBarang ||
        partControllers.length != jumlahBarang ||
        emailControllers.length != jumlahBarang) {
      // Tambahkan emailControllers
      _initializeItemFields();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Colors.grey.shade200,
        elevation: 0,
        title: Image.asset('assets/image/logo.png', width: 95, height: 30),
        actions: [
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline,
              color: Theme.of(context).colorScheme.onSurface,
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
      body: Column(
        children: [
          // ==== KONTEN ====
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 20, bottom: 100),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _inputField("Nama", namaController, readOnly: true),
                        const SizedBox(height: 12),
                        _jumlahBarangField(),
                        const SizedBox(height: 12),
                        _buildAlamat(),
                        const SizedBox(height: 12),

                        // ==== DAFTAR BARANG ====
                        ...List.generate(jumlahBarang, (index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Barang ${index + 1}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _inputField("Merek", merekControllers[index]),
                                const SizedBox(height: 10),
                                _inputField("Device", deviceControllers[index]),
                                const SizedBox(height: 10),
                                _dropdownField(
                                  "Status",
                                  selectedStatuses[index],
                                  statusOptions,
                                  (value) {
                                    setState(() {
                                      selectedStatuses[index] = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                _inputField("Seri", seriControllers[index]),
                                const SizedBox(height: 10),
                                _inputField(
                                  "Keterangan Keluhan",
                                  partControllers[index],
                                ),
                                // Kondisi untuk menampilkan field email
                                if (selectedStatuses[index] ==
                                        "IW (Masih Garansi)" &&
                                    merekControllers[index].text.trim() ==
                                        "Lenovo") ...[
                                  const SizedBox(height: 10),
                                  _emailField(
                                    "Email *",
                                    emailControllers[index],
                                  ), // Gunakan _emailField khusus
                                ],
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              // ===== VALIDASI =====
                              if (namaController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Nama wajib diisi dan tidak boleh kosong',
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (selectedAddress == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Alamat pengiriman wajib dipilih',
                                    ),
                                  ),
                                );
                                return;
                              }

                              for (int i = 0; i < jumlahBarang; i++) {
                                if (merekControllers[i].text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Merek barang ${i + 1} wajib diisi',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (deviceControllers[i].text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Device barang ${i + 1} wajib diisi',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (selectedStatuses[i] == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Status barang ${i + 1} wajib dipilih',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (seriControllers[i].text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Seri barang ${i + 1} wajib diisi',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (partControllers[i].text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Keterangan keluhan barang ${i + 1} wajib diisi',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                // Validasi email untuk Lenovo IW
                                if (selectedStatuses[i] ==
                                        "IW (Masih Garansi)" &&
                                    merekControllers[i].text.trim() ==
                                        "Lenovo") {
                                  String fullEmail = _getFullEmail(i);
                                  if (fullEmail.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Email barang ${i + 1} wajib diisi',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                }
                              }

                              // ===== SHOW LOADING =====
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              try {
                                String cosKode =
                                    await SessionManager.getCustomerId() ?? '';
                                String transTanggal =
                                    DateTime.now().toIso8601String().split(
                                          'T',
                                        )[0];

                                // ===== SEPARATOR UNTUK MULTIPLE ITEMS =====
                                const String separator = '|||';

                                // ===== GABUNGKAN DATA DENGAN SEPARATOR =====
                                List<String> merekList = [];
                                List<String> deviceList = [];
                                List<String> statusGaransiList = [];
                                List<String> seriList = [];
                                List<String> keluhanList = [];
                                List<String> emailList = [];

                                for (int i = 0; i < jumlahBarang; i++) {
                                  merekList
                                      .add(merekControllers[i].text.trim());
                                  deviceList
                                      .add(deviceControllers[i].text.trim());
                                  statusGaransiList
                                      .add(selectedStatuses[i] ?? '');
                                  seriList.add(seriControllers[i].text.trim());
                                  keluhanList
                                      .add(partControllers[i].text.trim());

                                  // Email hanya untuk Lenovo IW
                                  if (selectedStatuses[i] ==
                                          "IW (Masih Garansi)" &&
                                      merekControllers[i].text.trim() ==
                                          "Lenovo") {
                                    emailList.add(_getFullEmail(i));
                                  } else {
                                    emailList.add('');
                                  }
                                }

                                // Gabungkan dengan separator |||
                                String merekGabungan =
                                    merekList.join(separator);
                                String deviceGabungan =
                                    deviceList.join(separator);
                                String statusGaransiGabungan =
                                    statusGaransiList.join(separator);
                                String seriGabungan = seriList.join(separator);
                                String keluhanGabungan =
                                    keluhanList.join(separator);
                                String emailGabungan = emailList
                                    .where((e) => e.isNotEmpty)
                                    .join(separator);

                                // ===== KIRIM 1 REQUEST SAJA =====
                                Map<String, dynamic> orderData = {
                                  'cos_kode': cosKode,
                                  'trans_total': 0.0,
                                  'trans_discount': 0.0,
                                  'trans_tanggal': transTanggal,
                                  'trans_status': 'pending',
                                  'merek': merekGabungan,
                                  'device': deviceGabungan,
                                  'status_garansi': statusGaransiGabungan,
                                  'seri': seriGabungan,
                                  'ket_keluhan': keluhanGabungan,
                                  'email': emailGabungan.isNotEmpty
                                      ? emailGabungan
                                      : null,
                                  'alamat': selectedAddress!['alamat'],
                                  'latitude': selectedAddress!['latitude'],
                                  'longitude': selectedAddress!['longitude'],
                                  'jumlah_item':
                                      jumlahBarang, // Tambahan info jumlah item
                                };

                                print('Creating order: $orderData');

                                Map<String, dynamic> orderResponse =
                                    await ApiService.createOrderList(orderData);

                                print('Order response: $orderResponse');

                                // Close loading dialog
                                Navigator.of(context).pop();

                                if (_isSuccess(orderResponse)) {
                                  // Ambil trans_kode dari response API
                                  String transKode = orderResponse['data']
                                              ?['trans_kode']
                                          ?.toString() ??
                                      '';

                                  if (transKode.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            WaitingApprovalPage(
                                          transKode: transKode,
                                          jumlahItem: jumlahBarang,
                                        ),
                                      ),
                                    );
                                  } else {
                                    _showErrorDialog(
                                      'Trans kode tidak ditemukan dalam response',
                                    );
                                  }
                                } else {
                                  String errorMsg = orderResponse['message'] ??
                                      'Gagal membuat pesanan';
                                  _showErrorDialog(errorMsg);
                                }
                              } catch (e) {
                                // Close loading dialog
                                Navigator.of(context).pop();
                                _showErrorDialog('Gagal membuat pesanan: $e');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              "Pesan",
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
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
        selectedItemColor: Colors.white,
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

  // ==== WIDGET INPUT ====
  Widget _inputField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAlamat() {
    print('Brightness: ${Theme.of(context).brightness}');
    print('Primary: ${Theme.of(context).colorScheme.primary}');
    print('OnPrimary: ${Theme.of(context).colorScheme.onPrimary}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Kirim Ke Alamat",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedAddress != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedAddress!['alamat'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Detail: ${selectedAddress!['detailAlamat'] ?? ''}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Penerima: ${selectedAddress!['nama'] ?? ''} (${selectedAddress!['hp'] ?? ''})",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DetailAlamatPage(),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          selectedAddress = result;
                        });
                      }
                    },
                    child: Text(
                      "Ubah Alamat",
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  "Belum ada alamat yang dipilih",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DetailAlamatPage(),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        selectedAddress = result;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Pilih Alamat",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
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
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
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
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            hintText: 'Masukkan email Gmail',
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
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
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: DropdownButton<String>(
            value: selectedValue,
            hint: Text(
              'Pilih...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
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
        Text(
          "Jumlah Barang :",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.remove,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: jumlahBarang > 1
                    ? () => _updateJumlahBarang(jumlahBarang - 1)
                    : null,
              ),
              Text(
                jumlahBarang.toString(),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.add,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Gagal'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
