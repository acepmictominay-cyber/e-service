import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'detail_service_midtrans.dart';

class TeknisiStatusPage extends StatefulWidget {
  final String queueCode;
  final String serviceType;
  final String nama;
  final int jumlahBarang;
  final List<Map<String, String?>> items;
  final String alamat;

  const TeknisiStatusPage({
    super.key,
    required this.queueCode,
    required this.serviceType,
    required this.nama,
    required this.jumlahBarang,
    required this.items,
    required this.alamat,
  });

  @override
  State<TeknisiStatusPage> createState() => _TeknisiStatusPageState();
}

class _TeknisiStatusPageState extends State<TeknisiStatusPage> {
  int currentStatus = 0; // 0: Menunggu, 1: Melakukan Service, 2: Selesai

  final List<String> statusTitles = [
    "Menunggu Teknisi Sedang Melakukan Pengecekan",
    "Teknisi Melakukan Service/Cleaning",
    "Selesai"
  ];

  final List<String> statusDescriptions = [
    "Teknisi sedang melakukan pemeriksaan awal pada perangkat Anda. Mohon tunggu sebentar.",
    "Teknisi sedang melakukan perbaikan atau pembersihan sesuai dengan jenis layanan yang dipilih.",
    "Layanan telah selesai. Silakan lakukan pembayaran untuk menyelesaikan pesanan."
  ];

  final List<IconData> statusIcons = [
    Icons.hourglass_empty,
    Icons.build,
    Icons.check_circle
  ];

  final List<Color> statusColors = [
    Colors.orange,
    Colors.blue,
    Colors.green
  ];

  void _nextStatus() {
    if (currentStatus < 2) {
      setState(() {
        currentStatus++;
      });
    } else {
      _showPaymentDialog();
    }
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Pembayaran Biaya Teknisi",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Biaya teknisi telah ditentukan berdasarkan pemeriksaan yang dilakukan.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailServiceMidtransPage(
                          serviceType: widget.serviceType,
                          nama: widget.nama,
                          status: null,
                          jumlahBarang: widget.jumlahBarang,
                          items: widget.items,
                          alamat: widget.alamat,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  ),
                  child: const Text(
                    "Lanjutkan ke Pembayaran",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Status Teknisi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    statusIcons[currentStatus],
                    size: 80,
                    color: statusColors[currentStatus],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    statusTitles[currentStatus],
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    statusDescriptions[currentStatus],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  if (currentStatus < 2)
                    ElevatedButton(
                      onPressed: _nextStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColors[currentStatus],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      ),
                      child: Text(
                        currentStatus == 0 ? "Teknisi Mulai Pengecekan" : "Teknisi Selesai Service",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: _nextStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      ),
                      child: const Text(
                        "Selesai & Bayar",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
