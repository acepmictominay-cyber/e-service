  import 'package:e_service/Beli/shop.dart';
  import 'package:e_service/Home/Home.dart';
  import 'package:e_service/Others/notifikasi.dart';
  import 'package:e_service/Profile/profile.dart';
  import 'package:e_service/Promo/promo.dart';
  import 'package:e_service/Service/Service.dart';
  import 'package:flutter/material.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'detail_service_midtrans.dart';

  class PerbaikanServicePage extends StatefulWidget {
    const PerbaikanServicePage({super.key});

    @override
    State<PerbaikanServicePage> createState() => _PerbaikanServicePageState();
  }

  class _PerbaikanServicePageState extends State<PerbaikanServicePage> {
    int currentIndex = 0;

    final TextEditingController namaController = TextEditingController();

    int jumlahBarang = 1;
    List<TextEditingController> seriControllers = [];
    List<TextEditingController> partControllers = [];
    List<TextEditingController> emailControllers = []; // Tambahkan untuk email
    List<String?> selectedMereks = [];
    List<String?> selectedDevices = [];
    List<String?> selectedStatuses = [];

    final List<String> merekOptions = ['Asus', 'Dell', 'HP', 'Lenovo', 'Apple', 'Samsung', 'Sony', 'Toshiba'];
    final List<String> deviceOptions = ['Laptop', 'Desktop', 'Tablet', 'Smartphone', 'Printer', 'Monitor', 'Keyboard', 'Mouse'];
    final List<String> statusOptions = ['CID', 'IW (Masih Garansi)', 'OOW (Tidak Garansi)'];

    @override
    void initState() {
      super.initState();
      _initializeItemFields();
    }

    void _initializeItemFields() {
      seriControllers = List.generate(jumlahBarang, (_) => TextEditingController());
      partControllers = List.generate(jumlahBarang, (_) => TextEditingController());
      emailControllers = List.generate(jumlahBarang, (_) => TextEditingController()); // Tambahkan emailControllers
      selectedMereks = List.filled(jumlahBarang, null);
      selectedDevices = List.filled(jumlahBarang, null);
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
      if (selectedStatuses.length != jumlahBarang ||
          selectedMereks.length != jumlahBarang ||
          selectedDevices.length != jumlahBarang ||
          seriControllers.length != jumlahBarang ||
          partControllers.length != jumlahBarang ||
          emailControllers.length != jumlahBarang) { // Tambahkan emailControllers
        _initializeItemFields();
      }

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
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationPage()),
                      );
                    },
                  ),
                ],
              ),
            ),

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

                          // ==== DAFTAR BARANG ====
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
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _dropdownField("Merek", selectedMereks[index], merekOptions, (value) {
                                    setState(() {
                                      selectedMereks[index] = value;
                                    });
                                  }),
                                  const SizedBox(height: 10),
                                  _dropdownField("Device", selectedDevices[index], deviceOptions, (value) {
                                    setState(() {
                                      selectedDevices[index] = value;
                                    });
                                  }),
                                  const SizedBox(height: 10),
                                  _dropdownField("Status", selectedStatuses[index], statusOptions, (value) {
                                    setState(() {
                                      selectedStatuses[index] = value;
                                    });
                                  }),
                                  const SizedBox(height: 10),
                                  _inputField("Seri", seriControllers[index]),
                                  const SizedBox(height: 10),
                                  _inputField("Keterangan Keluhan", partControllers[index]),
                                  // Kondisi untuk menampilkan field email
                                  if (selectedStatuses[index] == "IW (Masih Garansi)" &&
                                      selectedMereks[index] == "Lenovo") ...[
                                    const SizedBox(height: 10),
                                    _emailField("Email *", emailControllers[index]), // Gunakan _emailField khusus
                                  ],
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                // Validation
                                if (namaController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Nama wajib diisi dan tidak boleh kosong')),
                                  );
                                  return;
                                }
                                for (int i = 0; i < jumlahBarang; i++) {
                                  if (selectedMereks[i] == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Merek wajib dipilih')),
                                    );
                                    return;
                                  }
                                  if (selectedDevices[i] == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Device wajib dipilih')),
                                    );
                                    return;
                                  }
                                  if (selectedStatuses[i] == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Status wajib dipilih')),
                                    );
                                    return;
                                  }
                                  if (seriControllers[i].text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Seri wajib diisi dan tidak boleh kosong')),
                                    );
                                    return;
                                  }
                                  if (partControllers[i].text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Keterangan Keluhan wajib diisi dan tidak boleh kosong')),
                                    );
                                    return;
                                  }
                                  // Validasi email jika kondisi terpenuhi
                                  if (selectedStatuses[i] == "IW (Masih Garansi)" &&
                                      selectedMereks[i] == "Lenovo") {
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
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(fullEmail)) {
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
                                    'merek': selectedMereks[i],
                                    'device': selectedDevices[i],
                                    'status': selectedStatuses[i],
                                    'seri': seriControllers[i].text,
                                    'part': partControllers[i].text,
                                    'email': (selectedStatuses[i] == "IW (Masih Garansi)" &&
                                            selectedMereks[i] == "Lenovo")
                                        ? _getFullEmail(i)
                                        : null,
                                  });
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailServiceMidtransPage(
                                      serviceType: 'repair',
                                      nama: namaController.text,
                                      status: null,
                                      jumlahBarang: jumlahBarang,
                                      items: items,
                                      alamat: "", // alamat dihapus tapi tetap dikirim kosong agar tidak error
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "Pesan",
                                style: TextStyle(fontSize: 16, color: Colors.white),
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
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ServicePage()));
            } else if (index == 1) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MarketplacePage()));
            } else if (index == 2) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
            } else if (index == 3) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TukarPoinPage()));
            } else if (index == 4) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
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
            const BottomNavigationBarItem(icon: Icon(Icons.build_circle_outlined), label: 'Service'),
            const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Beli'),
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: currentIndex == 3
                  ? Image.asset('assets/image/promo.png', width: 24, height: 24)
                  : Opacity(opacity: 0.6, child: Image.asset('assets/image/promo.png', width: 24, height: 24)),
              label: 'Promo',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      );
    }

    // ==== WIDGET INPUT ====
    Widget _inputField(String label, TextEditingController controller) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            keyboardType: TextInputType.emailAddress, // Keyboard email untuk bantuan format
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

    Widget _dropdownField(String label, String? selectedValue, List<String> options, ValueChanged<String?> onChanged) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
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
              hint: const Text('Pilih...', style: TextStyle(color: Colors.black54)),
              isExpanded: true,
              underline: const SizedBox(),
              items: options.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(color: Colors.black)),
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
          const Text("Jumlah Barang :", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
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
                  onPressed: jumlahBarang > 1 ? () => _updateJumlahBarang(jumlahBarang - 1) : null,
                ),
                Text(jumlahBarang.toString(), style: const TextStyle(fontSize: 16, color: Colors.black)),
                IconButton(
                  icon: const Icon(Icons.add, size: 18, color: Colors.black),
                  onPressed: jumlahBarang < 10 ? () => _updateJumlahBarang(jumlahBarang + 1) : null,
                ),
              ],
            ),
          ),
        ],
      );
    }
  }